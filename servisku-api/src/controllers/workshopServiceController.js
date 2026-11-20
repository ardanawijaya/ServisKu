const { z } = require('zod');
const prisma = require('../config/db');
const { getOwnWorkshop } = require('./workshopController');

const harga = z.coerce
  .number()
  .int('Harga harus bilangan bulat')
  .min(0, 'Harga tidak boleh negatif')
  .max(100000000, 'Harga terlalu besar');

const schema = z
  .object({
    kategori: z.string().trim().min(2, 'Kategori wajib diisi').max(60),
    nama: z.string().trim().min(2, 'Nama layanan wajib diisi').max(150),
    deskripsi: z.string().trim().max(255, 'Deskripsi maksimal 255 karakter').optional().nullable(),
    durasiMenit: z.coerce
      .number()
      .int('Durasi harus bilangan bulat')
      .min(5, 'Durasi minimal 5 menit')
      .max(600, 'Durasi maksimal 600 menit'),
    hargaMin: harga,
    hargaMax: harga,
    isActive: z.boolean().optional(),
  })
  .refine((d) => d.hargaMax >= d.hargaMin, {
    message: 'Harga maksimum tidak boleh lebih kecil dari harga minimum',
    path: ['hargaMax'],
  });

const aktifSchema = z.object({ isActive: z.boolean({ message: 'isActive harus true atau false' }) });

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function getId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID layanan tidak valid');
  return id;
}

async function findOwned(id, workshopId) {
  const s = await prisma.workshopService.findFirst({ where: { id, workshopId } });
  if (!s) throw httpError(404, 'Layanan tidak ditemukan');
  return s;
}

function format(s) {
  return {
    id: s.id,
    kategori: s.kategori,
    nama: s.nama,
    deskripsi: s.deskripsi,
    durasiMenit: s.durasiMenit,
    hargaMin: s.hargaMin,
    hargaMax: s.hargaMax,
    isActive: s.isActive,
  };
}

exports.list = async (req, res, next) => {
  try {
    const w = await getOwnWorkshop(req.user.id);
    const rows = await prisma.workshopService.findMany({
      where: { workshopId: w.id },
      orderBy: [{ kategori: 'asc' }, { id: 'asc' }],
    });
    res.json({ success: true, data: { services: rows.map(format) } });
  } catch (err) {
    next(err);
  }
};

exports.create = async (req, res, next) => {
  try {
    const d = schema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);
    const s = await prisma.workshopService.create({
      data: {
        workshopId: w.id,
        kategori: d.kategori,
        nama: d.nama,
        deskripsi: d.deskripsi || null,
        durasiMenit: d.durasiMenit,
        hargaMin: d.hargaMin,
        hargaMax: d.hargaMax,
        isActive: d.isActive ?? true,
      },
    });
    res.status(201).json({ success: true, message: 'Layanan ditambahkan', data: { service: format(s) } });
  } catch (err) {
    next(err);
  }
};

exports.update = async (req, res, next) => {
  try {
    const id = getId(req);
    const d = schema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);
    const existing = await findOwned(id, w.id);

    const s = await prisma.workshopService.update({
      where: { id },
      data: {
        kategori: d.kategori,
        nama: d.nama,
        deskripsi: d.deskripsi || null,
        durasiMenit: d.durasiMenit,
        hargaMin: d.hargaMin,
        hargaMax: d.hargaMax,
        isActive: d.isActive ?? existing.isActive,
      },
    });
    res.json({ success: true, message: 'Layanan diperbarui', data: { service: format(s) } });
  } catch (err) {
    next(err);
  }
};

exports.setAktif = async (req, res, next) => {
  try {
    const id = getId(req);
    const { isActive } = aktifSchema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);
    await findOwned(id, w.id);
    const s = await prisma.workshopService.update({ where: { id }, data: { isActive } });
    res.json({
      success: true,
      message: isActive ? 'Layanan diaktifkan' : 'Layanan dinonaktifkan',
      data: { service: format(s) },
    });
  } catch (err) {
    next(err);
  }
};

exports.remove = async (req, res, next) => {
  try {
    const id = getId(req);
    const w = await getOwnWorkshop(req.user.id);
    await findOwned(id, w.id);
    await prisma.workshopService.delete({ where: { id } });
    res.json({ success: true, message: 'Layanan dihapus' });
  } catch (err) {
    // Layanan yang sudah pernah dipesan tidak boleh dihapus (menjaga riwayat booking)
    if (err && (err.code === 'P2003' || err.code === 'P2014')) {
      return res.status(409).json({
        success: false,
        message: 'Layanan ini sudah pernah dipesan dan tidak bisa dihapus. Nonaktifkan saja.',
      });
    }
    next(err);
  }
};
