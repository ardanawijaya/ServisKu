const { z } = require('zod');
const prisma = require('../config/db');
const { includeBooking, formatBooking } = require('../utils/bookingFormat');
const { bagianWIB, tambahHari, tanggalValid } = require('../utils/wib');
const { hitungKetersediaan, STATUS_AKTIF } = require('../utils/bookingSlots');

const toDate = (s) => new Date(`${s}T00:00:00.000Z`);

const createSchema = z.object({
  vehicleId: z.coerce.number().int().positive('Pilih kendaraan'),
  workshopId: z.coerce.number().int().positive('Pilih bengkel'),
  tanggal: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Format tanggal harus YYYY-MM-DD'),
  jam: z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Format jam harus HH:mm'),
  serviceIds: z
    .array(z.coerce.number().int().positive())
    .min(1, 'Pilih minimal satu layanan')
    .max(20),
  keluhan: z.string().trim().max(500, 'Catatan maksimal 500 karakter').optional().nullable(),
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

async function findOwned(id, userId) {
  const b = await prisma.booking.findFirst({ where: { id, userId }, include: includeBooking });
  if (!b) throw httpError(404, 'Booking tidak ditemukan');
  return b;
}

exports.create = async (req, res, next) => {
  try {
    const userId = req.user.id;
    const d = createSchema.parse(req.body);
    if (!tanggalValid(d.tanggal)) throw httpError(400, 'Tanggal tidak valid');

    const vehicle = await prisma.vehicle.findFirst({ where: { id: d.vehicleId, userId } });
    if (!vehicle) throw httpError(404, 'Kendaraan tidak ditemukan');

    const workshop = await prisma.workshop.findUnique({ where: { id: d.workshopId } });
    if (!workshop) throw httpError(404, 'Bengkel tidak ditemukan');

    const ids = [...new Set(d.serviceIds)];
    const layanan = await prisma.workshopService.findMany({
      where: { id: { in: ids }, workshopId: workshop.id, isActive: true },
    });
    if (layanan.length !== ids.length) {
      throw httpError(400, 'Ada layanan yang tidak tersedia di bengkel ini');
    }

    const { tanggal: hariIni } = bagianWIB();
    if (d.tanggal < hariIni) throw httpError(400, 'Tanggal booking tidak boleh di masa lalu');
    if (d.tanggal > tambahHari(hariIni, 30)) throw httpError(400, 'Booking maksimal 30 hari ke depan');

    const created = await prisma.$transaction(async (tx) => {
      // Kunci baris bengkel agar dua booking bersamaan tidak melampaui kuota
      await tx.$queryRaw`SELECT id FROM workshops WHERE id = ${workshop.id} FOR UPDATE`;

      const hariItu = await tx.booking.findMany({
        where: { workshopId: workshop.id, tanggal: toDate(d.tanggal), status: { in: STATUS_AKTIF } },
        select: { jam: true },
      });
      const k = hitungKetersediaan(workshop, d.tanggal, hariItu);
      if (k.tutup) throw httpError(409, k.alasan);

      const slot = k.slots.find((s) => s.jam === d.jam);
      if (!slot) throw httpError(400, 'Jam booking tidak valid');
      if (!slot.tersedia) {
        throw httpError(
          409,
          k.penuh ? 'Kuota booking pada tanggal ini sudah penuh' : 'Sesi jam ini sudah penuh atau sudah lewat',
        );
      }

      const ganda = await tx.booking.findFirst({
        where: {
          vehicleId: vehicle.id,
          tanggal: toDate(d.tanggal),
          status: { in: ['menunggu', 'dikonfirmasi', 'dikerjakan'] },
        },
      });
      if (ganda) throw httpError(409, 'Kendaraan ini sudah memiliki booking aktif pada tanggal tersebut');

      return tx.booking.create({
        data: {
          userId,
          vehicleId: vehicle.id,
          workshopId: workshop.id,
          tanggal: toDate(d.tanggal),
          jam: d.jam,
          keluhan: d.keluhan || null,
          // Harga yang disimpan = estimasi harga minimum layanan saat dipesan
          services: { create: layanan.map((l) => ({ workshopServiceId: l.id, harga: l.hargaMin })) },
        },
      });
    });

    const full = await prisma.booking.findUnique({ where: { id: created.id }, include: includeBooking });
    res.status(201).json({
      success: true,
      message: 'Booking berhasil dikirim ke bengkel',
      data: { booking: formatBooking(full) },
    });
  } catch (err) {
    next(err);
  }
};

exports.list = async (req, res, next) => {
  try {
    const rows = await prisma.booking.findMany({
      where: { userId: req.user.id },
      include: includeBooking,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: 100,
    });
    res.json({ success: true, data: { bookings: rows.map(formatBooking) } });
  } catch (err) {
    next(err);
  }
};

exports.detail = async (req, res, next) => {
  try {
    const b = await findOwned(getId(req), req.user.id);
    res.json({ success: true, data: { booking: formatBooking(b) } });
  } catch (err) {
    next(err);
  }
};

exports.cancel = async (req, res, next) => {
  try {
    const id = getId(req);
    const b = await findOwned(id, req.user.id);
    if (b.status !== 'menunggu' && b.status !== 'dikonfirmasi') {
      throw httpError(409, `Booking berstatus "${b.status}" tidak dapat dibatalkan`);
    }
    await prisma.booking.update({ where: { id }, data: { status: 'dibatalkan' } });
    const full = await prisma.booking.findUnique({ where: { id }, include: includeBooking });
    res.json({ success: true, message: 'Booking dibatalkan', data: { booking: formatBooking(full) } });
  } catch (err) {
    next(err);
  }
};
