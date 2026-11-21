// Jenis servis yang dipilih pengguna (chip di form "Catat Servis Baru")
const JENIS_SERVIS = [
  'Ganti Oli',
  'Servis Berkala',
  'Kampas Rem',
  'Ban',
  'CVT / V-Belt',
  'Aki',
  'Lainnya',
];

const SERVIS_BERKALA = ['Oli Mesin', 'Oli Gardan', 'Filter Udara', 'Busi'];

// Pemetaan jenis servis -> komponen yang "di-reset" di pengingat servis.
// Komponen yang tidak dimiliki kendaraan (mis. Oli Gardan untuk mobil) otomatis dilewati.
const PEMETAAN = {
  'Ganti Oli': ['Oli Mesin'],
  'Servis Berkala': SERVIS_BERKALA,
  'Kampas Rem': ['Kampas Rem'],
  Ban: ['Ban'],
  'CVT / V-Belt': ['CVT / V-Belt'],
  Aki: ['Aki'],
  Lainnya: [],
};

// Disimpan di database sebagai teks dipisah koma, mis. "Ganti Oli, Servis Berkala"
function parseJenis(str) {
  return String(str)
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

// Untuk catatan servis dari booking: nama layanan bengkel bebas, jadi dikenali lewat kata kunci.
function komponenDariNama(nama) {
  const n = String(nama).toLowerCase();
  const out = new Set();
  const adaOli = /\boli\b|pelumas/.test(n);
  const gardan = /gardan/.test(n);
  if (gardan) out.add('Oli Gardan');
  if (adaOli && (!gardan || /mesin/.test(n))) out.add('Oli Mesin');
  if (/kampas rem|\brem\b|brake/.test(n)) out.add('Kampas Rem');
  if (/cvt|v-belt|vbelt|roller|\bbelt\b/.test(n)) out.add('CVT / V-Belt');
  if (/filter udara|air filter/.test(n)) out.add('Filter Udara');
  if (/\bbusi\b/.test(n)) out.add('Busi');
  if (/\baki\b|accu/.test(n)) out.add('Aki');
  if (/\bban\b|spooring|balancing/.test(n)) out.add('Ban');
  if (/tune up|servis berkala|service berkala|perawatan berkala/.test(n)) {
    SERVIS_BERKALA.forEach((k) => out.add(k));
  }
  return [...out];
}

function komponenDariJenis(str) {
  const set = new Set();
  for (const j of parseJenis(str)) {
    const list = PEMETAAN[j] !== undefined ? PEMETAAN[j] : komponenDariNama(j);
    for (const k of list) set.add(k);
  }
  return [...set];
}

module.exports = { JENIS_SERVIS, parseJenis, komponenDariJenis, komponenDariNama };
