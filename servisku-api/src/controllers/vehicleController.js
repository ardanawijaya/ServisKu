const { z } = require('zod');
const prisma = require('../config/db');
const { pengingatUntukKendaraan } = require('../utils/pengingatService');

// ---------- Validasi ----------
const plat = z
  .string()
  .trim()
  .min(3, 'Plat nomor terlalu pendek')
  .max(15, 'Plat nomor terlalu panjang')
  .transform((v) => v.toUpperCase().replace(/\s+/g, ' '))
  .refine((v) => /^[A-Z0-9 ]+$/.test(v), 'Plat nomor hanya boleh huruf dan angka');

const createSchema = z.object({
  jenis: z.enum(['motor', 'mobil'], { message: 'Jenis harus motor atau mobil' }),
  merekTipe: z.string().trim().min(2, 'Merek & tipe wajib diisi').max(100),
  platNomor: plat,
  tahun: z.coerce
    .number()
    .int('Tahun tidak valid')
    .min(1980, 'Tahun minimal 1980')
    .max(new Date().getFullYear() + 1, 'Tahun melebihi tahun berjalan'),
  odometer: z.coerce
    .number()
    .int('Odometer harus bilangan bulat')
    .min(0, 'Odometer tidak boleh negatif')
    .max(9999999, 'Odometer terlalu besar'),
});

const updateSchema = z
  .object({
    merekTipe: createSchema.shape.merekTipe,
    platNomor: createSchema.shape.platNomor,
    tahun: createSchema.shape.tahun,
  })
  .partial();

const odometerSchema = z.object({
  km: z.coerce
    .number()
    .int('Odometer harus bilangan bulat')
    .min(0)
    .max(9999999, 'Odometer terlalu besar'),
});

// ---------- Helper ----------
const include = {
  serviceRecords: { orderBy: { tanggal: 'desc' }, take: 1, select: { tanggal: true } },
};

function format(v, pengingat = null) {
  return {
    id: v.id,
    jenis: v.jenis,
    merekTipe: v.merekTipe,
    platNomor: v.platNomor,
    tahun: v.tahun,
    odometerTerakhir: v.odometerTerakhir,
    isUtama: v.isUtama,
    servisTerakhir: v.serviceRecords?.[0]?.tanggal ?? null,
    pengingat,
  };
}

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function getId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID kendaraan tidak valid');
  return id;
}

// Kendaraan hanya boleh diakses pemiliknya. Jika bukan milik user -> 404 (bukan 403)
// agar keberadaan data milik orang lain tidak bocor.
async function findOwned(id, userId, db = prisma) {
  const v = await db.vehicle.findFirst({ where: { id, userId } });
  if (!v) throw httpError(404, 'Kendaraan tidak ditemukan');
  return v;
}

function handleDuplicate(err, res) {
  if (err && err.code === 'P2002') {
    res.status(409).json({ success: false, message: 'Plat nomor sudah terdaftar di akunmu' });
    return true;
  }
  return false;
}

// ---------- Handler ----------
exports.list = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const { jenis, search } = req.query;

    const where = { userId };
    if (jenis === 'motor' || jenis === 'mobil') where.jenis = jenis;
    if (search) {
      const q = String(search);
      where.OR = [{ merekTipe: { contains: q } }, { platNomor: { contains: q } }];
    }

    const [rows, groups] = await Promise.all([
      prisma.vehicle.findMany({
        where,
        include,
        orderBy: [{ isUtama: 'desc' }, { createdAt: 'asc' }],
      }),
      prisma.vehicle.groupBy({ by: ['jenis'], where: { userId }, _count: { _all: true } }),
    ]);

    const ringkasan = { semua: 0, motor: 0, mobil: 0 };
    for (const g of groups) {
      ringkasan[g.jenis] = g._count._all;
      ringkasan.semua += g._count._all;
    }

    const peng = await pengingatUntukKendaraan(rows);
    res.json({
      success: true,
      data: { vehicles: rows.map((v) => format(v, peng[v.id])), ringkasan },
    });
  } catch (err) {
    next(err);
  }
};

exports.detail = async (req, res, next) => {
  try {
    const id = getId(req);
    await findOwned(id, req.user.id);
    const v = await prisma.vehicle.findUnique({ where: { id }, include });
    const peng = await pengingatUntukKendaraan([v]);
    res.json({ success: true, data: { vehicle: format(v, peng[v.id]) } });
  } catch (err) {
    next(err);
  }
};

// Detail pengingat servis satu kendaraan (status tiap komponen, estimasi, kondisi)
exports.pengingat = async (req, res, next) => {
  try {
    const id = getId(req);
    const v = await findOwned(id, req.user.id);
    const peng = await pengingatUntukKendaraan([v]);
    res.json({ success: true, data: { pengingat: peng[v.id] } });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const d = createSchema.parse(req.body);

    const created = await prisma.$transaction(async (tx) => {
      const count = await tx.vehicle.count({ where: { userId } });
      const v = await tx.vehicle.create({
        data: {
          userId,
          jenis: d.jenis,
          merekTipe: d.merekTipe,
          platNomor: d.platNomor,
          tahun: d.tahun,
          odometerTerakhir: d.odometer,
          isUtama: count === 0, // kendaraan pertama otomatis jadi "Utama"
        },
      });

      // Catatan awal odometer (dasar perhitungan rata-rata km/hari)
      await tx.odometerLog.create({ data: { vehicleId: v.id, km: d.odometer } });

      // Siapkan komponen yang dipantau pengingat. Titik awal = odometer dan tanggal
      // saat kendaraan didaftarkan; akan diperbarui saat ada catatan servis.
      const comps = await tx.serviceComponent.findMany({ where: { jenisKendaraan: d.jenis } });
      if (comps.length > 0) {
        await tx.vehicleComponent.createMany({
          data: comps.map((c) => ({
            vehicleId: v.id,
            componentId: c.id,
            lastServiceKm: d.odometer,
            lastServiceDate: new Date(),
          })),
        });
      }
      return v;
    });

    const full = await prisma.vehicle.findUnique({ where: { id: created.id }, include });
    res.status(201).json({
      success: true,
      message: 'Kendaraan berhasil ditambahkan',
      data: { vehicle: format(full) },
    });
  } catch (err) {
    if (handleDuplicate(err, res)) return;
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const id = getId(req);
    await findOwned(id, req.user.id);

    const data = updateSchema.parse(req.body);
    if (Object.keys(data).length === 0) {
      throw httpError(400, 'Tidak ada data yang diubah');
    }

    const v = await prisma.vehicle.update({ where: { id }, data, include });
    res.json({ success: true, message: 'Kendaraan diperbarui', data: { vehicle: format(v) } });
  } catch (err) {
    if (handleDuplicate(err, res)) return;
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const id = getId(req);
    const userId = req.user.id;

    await prisma.$transaction(async (tx) => {
      const v = await findOwned(id, userId, tx);
      await tx.vehicle.delete({ where: { id } });

      // Jika yang dihapus kendaraan utama, jadikan kendaraan tertua yang tersisa sebagai utama
      if (v.isUtama) {
        const next = await tx.vehicle.findFirst({
          where: { userId },
          orderBy: { createdAt: 'asc' },
        });
        if (next) await tx.vehicle.update({ where: { id: next.id }, data: { isUtama: true } });
      }
    });

    res.json({ success: true, message: 'Kendaraan dihapus' });
  } catch (err) {
    next(err);
  }
};

exports.updateOdometer = async (req, res, next) => {
  try {
    const id = getId(req);
    const { km } = odometerSchema.parse(req.body);
    const current = await findOwned(id, req.user.id);

    if (km <= current.odometerTerakhir) {
      return res.status(400).json({
        success: false,
        message: `Odometer baru harus lebih besar dari ${current.odometerTerakhir} km`,
      });
    }

    await prisma.$transaction([
      prisma.vehicle.update({ where: { id }, data: { odometerTerakhir: km } }),
      prisma.odometerLog.create({ data: { vehicleId: id, km } }),
    ]);

    const v = await prisma.vehicle.findUnique({ where: { id }, include });
    res.json({
      success: true,
      message: 'Odometer diperbarui',
      data: { vehicle: format(v), selisihKm: km - current.odometerTerakhir },
    });
  } catch (err) {
    next(err);
  }
};

exports.setUtama = async (req, res, next) => {
  try {
    const id = getId(req);
    const userId = req.user.id;
    await findOwned(id, userId);

    await prisma.$transaction([
      prisma.vehicle.updateMany({ where: { userId }, data: { isUtama: false } }),
      prisma.vehicle.update({ where: { id }, data: { isUtama: true } }),
    ]);

    const v = await prisma.vehicle.findUnique({ where: { id }, include });
    res.json({ success: true, message: 'Kendaraan utama diubah', data: { vehicle: format(v) } });
  } catch (err) {
    next(err);
  }
};
