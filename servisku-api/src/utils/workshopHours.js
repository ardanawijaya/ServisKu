// Jam & hari operasional bengkel
const HARI = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

// "Senin - Sabtu" -> ['Senin', ..., 'Sabtu'];  "Setiap Hari" -> semua hari;  "Senin" -> ['Senin']
// Mengembalikan null jika formatnya tidak valid.
function parseHari(str) {
  const s = String(str).trim();
  if (/^setiap hari$/i.test(s)) return [...HARI];
  const parts = s.split(/\s*-\s*/);
  if (parts.length === 1) return HARI.includes(parts[0]) ? [parts[0]] : null;
  if (parts.length === 2 && HARI.includes(parts[0]) && HARI.includes(parts[1])) {
    const i = HARI.indexOf(parts[0]);
    const j = HARI.indexOf(parts[1]);
    const out = [];
    let k = i;
    for (;;) {
      out.push(HARI[k]);
      if (k === j) break;
      k = (k + 1) % 7;
    }
    return out;
  }
  return null;
}

const toMenit = (hhmm) => {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
};

// Hari dan menit sekarang di zona waktu WIB
function sekarangWIB(now = new Date()) {
  const f = new Intl.DateTimeFormat('id-ID', {
    timeZone: 'Asia/Jakarta',
    weekday: 'long',
    hour: '2-digit',
    minute: '2-digit',
    hourCycle: 'h23',
  });
  const p = Object.fromEntries(f.formatToParts(now).map((x) => [x.type, x.value]));
  const hari = p.weekday.charAt(0).toUpperCase() + p.weekday.slice(1).toLowerCase();
  return { hari, menit: Number(p.hour) * 60 + Number(p.minute) };
}

// Apakah bengkel sedang buka sekarang
function statusBuka(w, now = new Date()) {
  const { hari, menit } = sekarangWIB(now);
  const hariBuka = parseHari(w.hariOperasional) || HARI;
  return hariBuka.includes(hari) && menit >= toMenit(w.jamBuka) && menit < toMenit(w.jamTutup);
}

module.exports = { HARI, parseHari, toMenit, sekarangWIB, statusBuka };
