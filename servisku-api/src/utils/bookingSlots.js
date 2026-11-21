/**
 * ALGORITMA KETERSEDIAAN SLOT BOOKING
 * -----------------------------------
 * - Slot dibuat per 60 menit dari jam buka sampai jam tutup (slot terakhir harus selesai <= jam tutup).
 * - Bengkel punya kuota booking per hari (kuotaHarian).
 * - Kapasitas tiap slot = ceil(kuotaHarian / jumlahSlot), minimal 1.
 * - Sebuah slot tersedia jika: bengkel buka pada hari itu, kuota harian belum habis,
 *   kapasitas slot belum penuh, dan jamnya belum lewat (untuk hari ini, waktu WIB).
 * - Booking berstatus menunggu, dikonfirmasi, dikerjakan, dan selesai memakan kuota.
 *   Booking ditolak / dibatalkan membebaskan kuota.
 */
const { parseHari, toMenit, HARI } = require('./workshopHours');
const { bagianWIB, namaHari, hhmm } = require('./wib');

const DURASI_SLOT_MENIT = 60;
const STATUS_AKTIF = ['menunggu', 'dikonfirmasi', 'dikerjakan', 'selesai'];

function buatSlot(w) {
  const mulai = toMenit(w.jamBuka);
  const selesai = toMenit(w.jamTutup);
  const out = [];
  for (let m = mulai; m + DURASI_SLOT_MENIT <= selesai; m += DURASI_SLOT_MENIT) out.push(hhmm(m));
  return out;
}

/**
 * w: workshop; tanggal: 'YYYY-MM-DD'; bookingsHariItu: [{ jam }] (hanya status yang memakan kuota)
 */
function hitungKetersediaan(w, tanggal, bookingsHariItu, now = new Date()) {
  const semua = buatSlot(w);
  const terpakai = bookingsHariItu.length;
  const sisaKuota = Math.max(w.kuotaHarian - terpakai, 0);
  const kuota = { total: w.kuotaHarian, terpakai, sisa: sisaKuota };

  const hari = namaHari(tanggal);
  const hariBuka = parseHari(w.hariOperasional) || HARI;
  if (!hariBuka.includes(hari)) {
    return {
      tutup: true,
      alasan: `Bengkel tutup pada hari ${hari}`,
      penuh: false,
      kuota,
      slots: semua.map((jam) => ({ jam, tersedia: false, sisa: 0 })),
    };
  }

  const kapasitasSlot = Math.max(1, Math.ceil(w.kuotaHarian / Math.max(semua.length, 1)));
  const { tanggal: hariIni, menit: sekarang } = bagianWIB(now);

  const slots = semua.map((jam) => {
    const dipakai = bookingsHariItu.filter((b) => b.jam === jam).length;
    const sisa = Math.max(kapasitasSlot - dipakai, 0);
    const lewat = tanggal < hariIni || (tanggal === hariIni && toMenit(jam) <= sekarang);
    return { jam, sisa, tersedia: !lewat && sisa > 0 && sisaKuota > 0 };
  });

  return { tutup: false, alasan: null, penuh: sisaKuota === 0, kuota, slots };
}

module.exports = { DURASI_SLOT_MENIT, STATUS_AKTIF, buatSlot, hitungKetersediaan };
