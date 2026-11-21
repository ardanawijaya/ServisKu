const { z } = require('zod');
const prisma = require('../config/db');
const { getOwnWorkshop } = require('./workshopController');
const { includeBooking, formatBooking } = require('../utils/bookingFormat');
const { recomputeComponents } = require('../utils/componentSync');
const { kirimNotifikasiBooking } = require('../utils/bookingNotifikasi');
const { tanggalIndonesia } = require('../utils/wib');

const STATUS_VALID = ['menunggu', 'dikonfirmasi', 'ditolak', 'dikerjakan', 'selesai', 'dibatalkan'];

const tolakSchema = z.object({
  alasan: z.string().trim().min(3, 'Alasan penolakan wajib diisi').max(255),
});
const mulaiSchema = z.object({
  mekanik: z.string().trim().max(100).optional().nullable(),
});
const selesaiSchema = z.object({
  biayaAkhir: z.coerce
    .number()
    .int('Biaya harus bilangan bulat')
    .min(0, 'Biaya tidak boleh negatif')
    .max(100000000, 'Biaya terlalu besar'),
  catatan: z.string().trim().max(1000, 'Catatan maksimal 1000 karakter').optional().nullable(),
});

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function getId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID booking tidak valid');
  return id;
}

async function findOwned(id, workshopId) {
  const b = await prisma.booking.findFirst({
    where: { id, workshopId },
    include: { ...includeBooking, vehicle: true },
  });
  if (!b) throw httpError(404, 'Booking tidak ditemukan');
  return b;
}

function pastikanStatus(b, ...diizinkan) {
  if (!diizinkan.includes(b.status)) {
    throw httpError(409, `Aksi tidak dapat dilakukan pada booking berstatus "${b.status}"`);
  }
}

const namaLayanan = (b) => b.services.map((s) => s.workshopService.nama).join(', ');

async function responBooking(res, id, message) {
  const full = await prisma.booking.findUnique({ where: { id }, include: includeBooking });
  res.json({ success: true, message, data: { booking: formatBooking(full) } });
}

exports.list = async (req, res, next) => {
  try {
    const w = await getOwnWorkshop(req.user.id);
    const where = { workshopId: w.id };
    const { status } = req.query;
    if (status && STATUS_VALID.includes(String(status))) where.status = String(status);

    const rows = await prisma.booking.findMany({
      where,
      include: includeBooking,
      orderBy: [{ tanggal: 'asc' }, { jam: 'asc' }, { id: 'asc' }],
      take: 200,
    });
    res.json({ success: true, data: { bookings: rows.map(formatBooking) } });
  } catch (err) {
    next(err);
  }
};

exports.terima = async (req, res, next) => {
  try {
    const id = getId(req);
    const w = await getOwnWorkshop(req.user.id);
    const b = await findOwned(id, w.id);
    pastikanStatus(b, 'menunggu');

    await prisma.booking.update({ where: { id }, data: { status: 'dikonfirmasi' } });
    await kirimNotifikasiBooking(
      b.userId,
      b.vehicleId,
      'Booking Dikonfirmasi',
      `${w.nama} menerima booking ${namaLayanan(b)} untuk ${b.vehicle.merekTipe} pada ${tanggalIndonesia(b.tanggal)} pukul ${b.jam} WIB.`,
    );
    await responBooking(res, id, 'Booking diterima');
  } catch (err) {
    next(err);
  }
};

exports.tolak = async (req, res, next) => {
  try {
    const id = getId(req);
    const { alasan } = tolakSchema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);
    const b = await findOwned(id, w.id);
    pastikanStatus(b, 'menunggu');

    await prisma.booking.update({ where: { id }, data: { status: 'ditolak', alasanPenolakan: alasan } });
    await kirimNotifikasiBooking(
      b.userId,
      b.vehicleId,
      'Booking Ditolak',
      `${w.nama} tidak dapat menerima booking ${tanggalIndonesia(b.tanggal)} pukul ${b.jam} WIB. Alasan: ${alasan}`,
    );
    await responBooking(res, id, 'Booking ditolak');
  } catch (err) {
    next(err);
  }
};

exports.mulai = async (req, res, next) => {
  try {
    const id = getId(req);
    const { mekanik } = mulaiSchema.parse(req.body || {});
    const w = await getOwnWorkshop(req.user.id);
    const b = await findOwned(id, w.id);
    pastikanStatus(b, 'dikonfirmasi');

    await prisma.booking.update({ where: { id }, data: { status: 'dikerjakan', mekanik: mekanik || null } });
    await kirimNotifikasiBooking(
      b.userId,
      b.vehicleId,
      'Kendaraan Sedang Dikerjakan',
      `${b.vehicle.merekTipe} (${b.vehicle.platNomor}) sedang dikerjakan di ${w.nama}.`,
    );
    await responBooking(res, id, 'Pengerjaan dimulai');
  } catch (err) {
    next(err);
  }
};

// Menyelesaikan booking sekaligus membuat catatan servis untuk pelanggan
// dan menghitung ulang jadwal pengingat servis kendaraannya.
exports.selesai = async (req, res, next) => {
  try {
    const id = getId(req);
    const { biayaAkhir, catatan } = selesaiSchema.parse(req.body);
    const w = await getOwnWorkshop(req.user.id);
    const b = await findOwned(id, w.id);
    pastikanStatus(b, 'dikerjakan');

    await prisma.$transaction(async (tx) => {
      await tx.booking.update({
        where: { id },
        data: { status: 'selesai', biayaAkhir, catatanBengkel: catatan || null },
      });
      await tx.serviceRecord.create({
        data: {
          vehicleId: b.vehicleId,
          bookingId: b.id,
          tanggal: b.tanggal,
          odometer: b.vehicle.odometerTerakhir,
          jenisServis: namaLayanan(b).slice(0, 200),
          namaBengkel: w.nama,
          biaya: biayaAkhir,
          catatan: catatan || b.keluhan || null,
        },
      });
      await recomputeComponents(tx, b.vehicleId);
    });

    await kirimNotifikasiBooking(
      b.userId,
      b.vehicleId,
      'Servis Selesai',
      `${b.vehicle.merekTipe} selesai diservis di ${w.nama} (biaya Rp ${biayaAkhir.toLocaleString('id-ID')}). Catatan servis sudah tersimpan otomatis.`,
    );
    await responBooking(res, id, 'Booking selesai dan masuk ke catatan servis pelanggan');
  } catch (err) {
    next(err);
  }
};
