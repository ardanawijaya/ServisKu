// Utilitas tanggal & waktu zona WIB (Asia/Jakarta)
const BULAN = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

// { tanggal: 'YYYY-MM-DD', menit: menit sejak tengah malam } saat ini di WIB
function bagianWIB(now = new Date()) {
  const f = new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
  const p = Object.fromEntries(f.formatToParts(now).map((x) => [x.type, x.value]));
  return { tanggal: `${p.year}-${p.month}-${p.day}`, menit: Number(p.hour) * 60 + Number(p.minute) };
}

// 'YYYY-MM-DD' -> 'Senin', 'Selasa', ...
function namaHari(tanggal) {
  const f = new Intl.DateTimeFormat('id-ID', { timeZone: 'Asia/Jakarta', weekday: 'long' });
  const s = f.format(new Date(`${tanggal}T12:00:00Z`));
  return s.charAt(0).toUpperCase() + s.slice(1).toLowerCase();
}

function tambahHari(tanggal, n) {
  const d = new Date(`${tanggal}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
}

function tanggalValid(tanggal) {
  return /^\d{4}-\d{2}-\d{2}$/.test(tanggal) && !Number.isNaN(new Date(`${tanggal}T00:00:00Z`).getTime());
}

// '2026-11-24' atau Date -> '24 November 2026'
function tanggalIndonesia(t) {
  const s = t instanceof Date ? t.toISOString().slice(0, 10) : String(t).slice(0, 10);
  const [y, m, d] = s.split('-').map(Number);
  return `${d} ${BULAN[m - 1]} ${y}`;
}

const hhmm = (menit) =>
  `${String(Math.floor(menit / 60)).padStart(2, '0')}:${String(menit % 60).padStart(2, '0')}`;

module.exports = { bagianWIB, namaHari, tambahHari, tanggalValid, tanggalIndonesia, hhmm };
