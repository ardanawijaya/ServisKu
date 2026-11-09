// Normalisasi nomor HP ke format 62xxxxxxxx
function normalizePhone(input) {
  let p = String(input).replace(/[^\d+]/g, '');
  if (p.startsWith('+')) p = p.slice(1);
  if (p.startsWith('0')) p = '62' + p.slice(1);
  return p;
}

// Inisial untuk avatar (pengganti foto profil), contoh "Ardana Wijaya" -> "AW"
function getInitials(nama) {
  const parts = String(nama).trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

function formatUser(user) {
  return {
    id: user.id,
    role: user.role,
    nama: user.nama,
    email: user.email,
    noHp: user.noHp,
    inisial: getInitials(user.nama),
    createdAt: user.createdAt,
  };
}

module.exports = { normalizePhone, getInitials, formatUser };
