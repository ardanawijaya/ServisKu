const prisma = require('../config/db');
const { statusBuka } = require('../utils/workshopHours');
const { bagianWIB, tambahHari, tanggalValid } = require('../utils/wib');
const { hitungKetersediaan, STATUS_AKTIF } = require('../utils/bookingSlots');

const toDate = (s) => new Date(`${s}T00:00:00.000Z`);

function httpError(status, message) {
  const e = new Error(message);
  e.status = status;
  return e;
}

function formatBengkel(w, extra = {}) {
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
    buka: statusBuka(w),
    ...extra,
  };
}

// Daftar bengkel yang punya minimal satu layanan aktif
exports.list = async (req, res, next) => {
  try {
    const { search, kota } = req.query;
    const AND = [{ services: { some: { isActive: true } } }];
    if (search) {
      const q = String(search);
      AND.push({
        OR: [{ nama: { contains: q } }, { kota: { contains: q } }, { alamat: { contains: q } }],
      });
    }
    if (kota) AND.push({ kota: { contains: String(kota) } });

    const rows = await prisma.workshop.findMany({
      where: { AND },
      include: { services: { where: { isActive: true }, select: { kategori: true, hargaMin: true } } },
    });

    // Slot terdekat yang masih tersedia hari ini (WIB)
    const { tanggal: hariIni } = bagianWIB();
    const bookingsHariIni = rows.length
      ? await prisma.booking.findMany({
          where: {
            workshopId: { in: rows.map((w) => w.id) },
            tanggal: toDate(hariIni),
            status: { in: STATUS_AKTIF },
          },
          select: { workshopId: true, jam: true },
        })
      : [];

    const hasil = rows.map((w) => {
      const k = hitungKetersediaan(
        w,
        hariIni,
        bookingsHariIni.filter((b) => b.workshopId === w.id),
      );
      const slot = k.slots.find((s) => s.tersedia);
      return formatBengkel(w, {
        kategori: [...new Set(w.services.map((s) => s.kategori))],
        hargaMulai: Math.min(...w.services.map((s) => s.hargaMin)),
        layananAktif: w.services.length,
        slotHariIni: slot ? slot.jam : null,
      });
    });

    hasil.sort((a, b) => Number(b.buka) - Number(a.buka) || a.nama.localeCompare(b.nama));
    res.json({ success: true, data: { bengkel: hasil } });
  } catch (err) {
    next(err);
  }
};

function parseId(req) {
  const id = Number(req.params.id);
  if (!Number.isInteger(id) || id <= 0) throw httpError(400, 'ID bengkel tidak valid');
  return id;
}

exports.detail = async (req, res, next) => {
  try {
    const id = parseId(req);
    const w = await prisma.workshop.findUnique({
      where: { id },
      include: {
        services: { where: { isActive: true }, orderBy: [{ kategori: 'asc' }, { id: 'asc' }] },
      },
    });
    if (!w) throw httpError(404, 'Bengkel tidak ditemukan');

    res.json({
      success: true,
      data: {
        bengkel: formatBengkel(w, {
          kategori: [...new Set(w.services.map((s) => s.kategori))],
          hargaMulai: w.services.length ? Math.min(...w.services.map((s) => s.hargaMin)) : 0,
          layananAktif: w.services.length,
        }),
        layanan: w.services.map((s) => ({
          id: s.id,
          kategori: s.kategori,
          nama: s.nama,
          deskripsi: s.deskripsi,
          durasiMenit: s.durasiMenit,
          hargaMin: s.hargaMin,
          hargaMax: s.hargaMax,
          isActive: s.isActive,
        })),
      },
    });
  } catch (err) {
    next(err);
  }
};

// Ketersediaan slot satu bengkel pada satu tanggal: GET /workshops/:id/slots?tanggal=YYYY-MM-DD
exports.slots = async (req, res, next) => {
  try {
    const id = parseId(req);
    const tanggal = String(req.query.tanggal || '');
    if (!tanggalValid(tanggal)) throw httpError(400, 'Parameter tanggal wajib berformat YYYY-MM-DD');

    const { tanggal: hariIni } = bagianWIB();
    if (tanggal < hariIni) throw httpError(400, 'Tanggal tidak boleh di masa lalu');
    if (tanggal > tambahHari(hariIni, 30)) throw httpError(400, 'Booking maksimal 30 hari ke depan');

    const w = await prisma.workshop.findUnique({ where: { id } });
    if (!w) throw httpError(404, 'Bengkel tidak ditemukan');

    const bookings = await prisma.booking.findMany({
      where: { workshopId: id, tanggal: toDate(tanggal), status: { in: STATUS_AKTIF } },
      select: { jam: true },
    });
    res.json({ success: true, data: { tanggal, ...hitungKetersediaan(w, tanggal, bookings) } });
  } catch (err) {
    next(err);
  }
};
