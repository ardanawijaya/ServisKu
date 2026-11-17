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

// Pemetaan jenis servis -> komponen yang "di-reset" di pengingat servis.
// Komponen yang tidak dimiliki kendaraan (mis. Oli Gardan untuk mobil) otomatis dilewati.
const PEMETAAN = {
  'Ganti Oli': ['Oli Mesin'],
  'Servis Berkala': ['Oli Mesin', 'Oli Gardan', 'Filter Udara', 'Busi'],
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

function komponenDariJenis(str) {
  const set = new Set();
  for (const j of parseJenis(str)) {
    for (const k of PEMETAAN[j] || []) set.add(k);
  }
  return [...set];
}

module.exports = { JENIS_SERVIS, parseJenis, komponenDariJenis };
