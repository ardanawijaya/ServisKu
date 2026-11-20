const { z } = require('zod');
const prisma = require('../config/db');
const { normalizePhone } = require('../utils/helpers');
const { parseHari, toMenit, statusBuka } = require('../utils/workshopHours');

const jam = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Format jam harus HH:mm');

const profileSchema = z
  .object({
    nama: z.string().trim().min(2, 'Nama bengkel wajib diisi').max(150),
    spesialis: z.string().trim().max(150).optional().nullable(),
    kota: z.string().trim().min(2, 'Kota wajib diisi').max(100),
    alamat: z.string().trim().min(5, 'Alamat terlalu pendek').max(500),
    noWhatsapp: z.string().trim().min(9, 'Nomor WhatsApp tidak valid').max(20),
    jamBuka: jam,
    jamTutup: jam,
    hariOperasional: z
      .string()
      .trim()
      .refine((v) => parseHari(v) !== null, 'Hari operasional tidak valid'),
    kuotaHarian: z.coerce
      .number()
      .int('Kuota harus bilangan bulat')
      .min(1, 'Kuota minimal 1')
      .max(200, 'Kuota maksimal 200'),
  })
  .refine((d) => toMenit(d.jamTutup) > toMenit(d.jamBuka), {
    message: 'Jam tutup harus setelah jam buka',
    path: ['jamTutup'],
  });

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

async function getOwnWorkshop(userId) {
  const w = await prisma.workshop.findUnique({ where: { userId } });
  if (!w) throw httpError(404, 'Profil bengkel tidak ditemukan');
  return w;
}

async function buildStats(workshopId) {
  const [grp, layananTotal, layananAktif] = await Promise.all([
    prisma.booking.groupBy({ by: ['status'], where: { workshopId }, _count: { _all: true } }),
    prisma.workshopService.count({ where: { workshopId } }),
    prisma.workshopService.count({ where: { workshopId, isActive: true } }),
  ]);
  const c = (s) => grp.find((g) => g.status === s)?._count._all ?? 0;
  const menunggu = c('menunggu');
  const dikonfirmasi = c('dikonfirmasi');
  const dikerjakan = c('dikerjakan');
  return {
    menunggu,
    dikonfirmasi,
    dikerjakan,
    selesai: c('selesai'),
    antrean: menunggu + dikonfirmasi + dikerjakan,
    layananTotal,
    layananAktif,
  };
}

function format(w, stats) {
  return {
    id: w.id,
    nama: w.nama,
    spesialis: w.spesialis,
    kota: w.kota,
    alamat: w.alamat,
    noWhatsapp: w.noWhatsapp,
    jamBuka: w.jamBuka,
    jamTutup: w.jamTutup,
    hariOperasional: w.hariOperasional,
    kuotaHarian: w.kuotaHarian,
    buka: statusBuka(w),
    stats,
  };
}

exports.getProfile = async (req, res, next) => {
  try {
    const w = await getOwnWorkshop(req.user.id);
    res.json({ success: true, data: { workshop: format(w, await buildStats(w.id)) } });
  } catch (err) {
    next(err);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const d = profileSchema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);

    const updated = await prisma.workshop.update({
      where: { id: w.id },
      data: {
        nama: d.nama,
        spesialis: d.spesialis || null,
        kota: d.kota,
        alamat: d.alamat,
        noWhatsapp: normalizePhone(d.noWhatsapp),
        jamBuka: d.jamBuka,
        jamTutup: d.jamTutup,
        hariOperasional: d.hariOperasional,
        kuotaHarian: d.kuotaHarian,
      },
    });
    res.json({
      success: true,
      message: 'Profil bengkel diperbarui',
      data: { workshop: format(updated, await buildStats(updated.id)) },
    });
  } catch (err) {
    next(err);
  }
};

exports.getOwnWorkshop = getOwnWorkshop;
