/**
 * ALGORITMA PENGINGAT SERVIS BERKALA
 * ----------------------------------
 * Fungsi murni (tanpa akses database) agar mudah diuji dan dijelaskan di artikel.
 *
 * Untuk setiap komponen kendaraan (oli mesin, kampas rem, dst.):
 *   sisaKm    = (lastServiceKm + intervalKm) - odometerSekarang
 *   jatuhTempo = lastServiceDate + intervalBulan
 *   sisaHari  = jatuhTempo - hariIni
 *   fraksiKm  = sisaKm / intervalKm
 *   fraksiHari = sisaHari / jumlahHariInterval
 *   fraksi    = min(fraksiKm, fraksiHari)      -> "mana yang tercapai lebih dulu"
 *
 * Status:
 *   terlambat : sisaKm <= 0  ATAU  sisaHari <= 0
 *   mendekati : fraksi <= AMBANG_MENDEKATI (15% dari interval)
 *   aman      : selain itu
 */

const AMBANG_MENDEKATI = 0.15; // sisa <= 15% interval dianggap "mendekati jadwal"
const JENDELA_RATA_RATA_HARI = 90; // rata-rata km/hari dihitung dari data 90 hari terakhir
const MS_HARI = 24 * 60 * 60 * 1000;

// Tanggal hari ini (tengah malam UTC) agar sebanding dengan kolom @db.Date
function hariIni() {
  const n = new Date();
  return new Date(Date.UTC(n.getFullYear(), n.getMonth(), n.getDate()));
}

function tambahBulan(date, n) {
  const d = new Date(date.getTime());
  d.setUTCMonth(d.getUTCMonth() + n);
  return d;
}

function selisihHari(a, b) {
  return Math.round((b.getTime() - a.getTime()) / MS_HARI);
}

const clamp01 = (x) => Math.min(Math.max(x, 0), 1);

// Rata-rata km/hari dari catatan odometer (urut lama -> baru). null jika data belum cukup.
function hitungRataRata(logs, today) {
  if (!logs || logs.length < 2) return null;
  const recent = logs.filter((l) => today.getTime() - new Date(l.dicatatPada).getTime() <= JENDELA_RATA_RATA_HARI * MS_HARI);
  const dipakai = recent.length >= 2 ? recent : logs;
  const first = dipakai[0];
  const last = dipakai[dipakai.length - 1];
  const hari = (new Date(last.dicatatPada).getTime() - new Date(first.dicatatPada).getTime()) / MS_HARI;
  if (hari < 1) return null; // rentang kurang dari sehari -> tidak representatif
  const avg = (last.km - first.km) / hari;
  return avg > 0 ? Math.round(avg * 10) / 10 : null;
}

function hitungKomponen(komponen, vc, odometer, today) {
  const sisaKm = vc.lastServiceKm + komponen.intervalKm - odometer;
  const fraksiKm = sisaKm / komponen.intervalKm;

  let sisaHari = null;
  let jatuhTempo = null;
  let fraksiHari = Infinity;
  if (vc.lastServiceDate) {
    const mulai = new Date(vc.lastServiceDate);
    jatuhTempo = tambahBulan(mulai, komponen.intervalBulan);
    const intervalHari = Math.max(selisihHari(mulai, jatuhTempo), 1);
    sisaHari = selisihHari(today, jatuhTempo);
    fraksiHari = sisaHari / intervalHari;
  }

  const fraksi = Math.min(fraksiKm, fraksiHari);
  const pemicu = fraksiKm <= fraksiHari ? 'km' : 'waktu';

  let status = 'aman';
  if (sisaKm <= 0 || (sisaHari !== null && sisaHari <= 0)) status = 'terlambat';
  else if (fraksi <= AMBANG_MENDEKATI) status = 'mendekati';

  return {
    komponen: komponen.nama,
    status,
    pemicu,
    sisaKm,
    sisaHari,
    jatuhTempo,
    intervalKm: komponen.intervalKm,
    intervalBulan: komponen.intervalBulan,
    persenSisa: Math.round(clamp01(fraksi) * 100),
    fraksi, // dipakai untuk mengurutkan, dibuang saat dikirim ke klien
  };
}

/**
 * items: [{ komponen: {nama, intervalKm, intervalBulan}, vc: {lastServiceKm, lastServiceDate} }]
 * logs : catatan odometer kendaraan, urut lama -> baru
 */
function hitungKendaraan(odometer, items, logs, today = hariIni()) {
  if (!items || items.length === 0) return null;

  const hasil = items.map((it) => hitungKomponen(it.komponen, it.vc, odometer, today));
  hasil.sort((a, b) => a.fraksi - b.fraksi); // paling mendesak di depan

  const urgent = hasil[0];
  const rata = hitungRataRata(logs, today);

  const urutan = { aman: 0, mendekati: 1, terlambat: 2 };
  const status = hasil.reduce((w, k) => (urutan[k.status] > urutan[w] ? k.status : w), 'aman');
  const persen = Math.round(hasil.reduce((s, k) => s + k.persenSisa, 0) / hasil.length);

  let label;
  if (status === 'terlambat') label = 'Perlu Servis';
  else if (status === 'mendekati') label = 'Perlu Perhatian';
  else label = persen >= 80 ? 'Prima' : 'Baik';

  return {
    kondisiPersen: persen,
    kondisiLabel: label,
    status,
    rataRataKmPerHari: rata,
    estimasi: {
      komponen: urgent.komponen,
      status: urgent.status,
      sisaKm: urgent.sisaKm,
      sisaHari: urgent.sisaHari,
      persenTerpakai: 100 - urgent.persenSisa,
      perkiraanHariDariKm: rata && urgent.sisaKm > 0 ? Math.ceil(urgent.sisaKm / rata) : null,
    },
    komponen: hasil.map(({ fraksi, ...rest }) => rest),
  };
}

module.exports = {
  AMBANG_MENDEKATI,
  hariIni,
  hitungRataRata,
  hitungKomponen,
  hitungKendaraan,
};
