const { z } = require('zod');
const prisma = require('../config/db');
const { JENIS_SERVIS, parseJenis } = require('../utils/serviceTypes');
const { syncOdometer, recomputeComponents } = require('../utils/componentSync');

// ---------- Validasi ----------
const toDate = (s) => new Date(`${s}T00:00:00.000Z`);

const tanggal = z
  .string()
  .regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD')
  .refine((s) => !Number.isNaN(toDate(s).getTime()), 'Tanggal tidak valid')
  .refine((s) => {
    const max = new Date();
    max.setUTCDate(max.getUTCDate() + 1); // toleransi zona waktu
    return toDate(s) <= max;
  }, 'Tanggal servis tidak boleh di masa depan');

const base = {
  tanggal,
  odometer: z.coerce
    .number()
    .int('Odometer harus bilangan bulat')
    .min(0, 'Odometer tidak boleh negatif')
    .max(9999999, 'Odometer terlalu besar'),
  jenisServis: z
    .array(z.enum(JENIS_SERVIS, { message: 'Jenis servis tidak dikenal' }))
    .min(1, 'Pilih minimal satu jenis servis'),
  namaBengkel: z.string().trim().min(2, 'Nama bengkel wajib diisi').max(150),
  biaya: z.coerce
    .number()
    .int('Biaya harus bilangan bulat')
    .min(0, 'Biaya tidak boleh negatif')
    .max(100000000, 'Biaya terlalu besar'),
  catatan: z.string().trim().max(1000, 'Catatan maksimal 1000 karakter').optional().nullable(),
};

const createSchema = z.object({ vehicleId: z.coerce.number().int().positive(), ...base });
const updateSchema = z.object(base);

// ---------- Helper ----------
const include = { vehicle: { select: { merekTipe: true, platNomor: true, jenis: true } } };

function format(r) {
  return {
    id: r.id,
    vehicleId: r.vehicleId,
    kendaraan: {
      merekTipe: r.vehicle.merekTipe,
      platNomor: r.vehicle.platNomor,
      jenis: r.vehicle.jenis,
    },
    tanggal: r.tanggal,
    odometer: r.odometer,
    jenisServis: parseJenis(r.jenisServis),
    namaBengkel: r.namaBengkel,
    biaya: r.biaya,
    catatan: r.catatan,
    dariBooking: r.bookingId != null,
  };
}

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function getId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID catatan servis tidak valid');
  return id;
}

// Catatan hanya boleh diakses pemilik kendaraannya (selain itu 404)
async function findOwnedRecord(id, userId, db = prisma) {
  const r = await db.serviceRecord.findFirst({
    where: { id, vehicle: { userId } },
    include: { vehicle: true },
  });
  if (!r) throw httpError(404, 'Catatan servis tidak ditemukan');
  return r;
}

const joinJenis = (arr) => [...new Set(arr)].join(', ');

// ---------- Handler ----------
exports.list = async (req, res, next) => {
  try {
    const where = { vehicle: { userId: req.user.id } };
    const vid = Number(req.query.vehicleId);
    if (Number.isInteger(vid) && vid > 0) where.vehicleId = vid;

    const rows = await prisma.serviceRecord.findMany({
      where,
      include,
      orderBy: [{ tanggal: 'desc' }, { id: 'desc' }],
    });
    res.json({ success: true, data: { records: rows.map(format) } });
  } catch (err) {
    next(err);
  }
};

exports.detail = async (req, res, next) => {
  try {
    const id = getId(req);
    await findOwnedRecord(id, req.user.id);
    const r = await prisma.serviceRecord.findUnique({ where: { id }, include });
    res.json({ success: true, data: { record: format(r) } });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const d = createSchema.parse(req.body);

    const vehicle = await prisma.vehicle.findFirst({ where: { id: d.vehicleId, userId } });
    if (!vehicle) throw httpError(404, 'Kendaraan tidak ditemukan');

    const created = await prisma.$transaction(async (tx) => {
      const r = await tx.serviceRecord.create({
        data: {
          vehicleId: vehicle.id,
          tanggal: toDate(d.tanggal),
          odometer: d.odometer,
          jenisServis: joinJenis(d.jenisServis),
          namaBengkel: d.namaBengkel,
          biaya: d.biaya,
          catatan: d.catatan || null,
        },
      });
      await syncOdometer(tx, vehicle, d.odometer);
      await recomputeComponents(tx, vehicle.id);
      return r;
    });

    const full = await prisma.serviceRecord.findUnique({ where: { id: created.id }, include });
    res.status(201).json({
      success: true,
      message: 'Catatan servis disimpan',
      data: { record: format(full) },
    });
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const id = getId(req);
    const d = updateSchema.parse(req.body);
    const existing = await findOwnedRecord(id, req.user.id);

    await prisma.$transaction(async (tx) => {
      await tx.serviceRecord.update({
        where: { id },
        data: {
          tanggal: toDate(d.tanggal),
          odometer: d.odometer,
          jenisServis: joinJenis(d.jenisServis),
          namaBengkel: d.namaBengkel,
          biaya: d.biaya,
          catatan: d.catatan || null,
        },
      });
      await syncOdometer(tx, existing.vehicle, d.odometer);
      await recomputeComponents(tx, existing.vehicleId);
    });

    const r = await prisma.serviceRecord.findUnique({ where: { id }, include });
    res.json({ success: true, message: 'Catatan servis diperbarui', data: { record: format(r) } });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const id = getId(req);
    const existing = await findOwnedRecord(id, req.user.id);

    await prisma.$transaction(async (tx) => {
      await tx.serviceRecord.delete({ where: { id } });
      await recomputeComponents(tx, existing.vehicleId);
    });

    res.json({ success: true, message: 'Catatan servis dihapus' });
  } catch (err) {
    next(err);
  }
};
