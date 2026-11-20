/// 33909 -> "33.909"
String formatKm(int n) {
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}

/// 1485000 -> "Rp 1.485.000"
String formatRupiah(int n) => 'Rp ${formatKm(n)}';

const _bulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// DateTime -> "12 Januari 2026"
String formatTanggal(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

String _dua(int n) => n.toString().padLeft(2, '0');

bool _hariSama(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Apakah waktu tersebut terjadi hari ini (zona waktu perangkat).
bool hariIniLokal(DateTime waktu) => _hariSama(waktu.toLocal(), DateTime.now());

/// "Baru saja", "5 menit yang lalu", "2 jam yang lalu", "Kemarin, 14:20", "12 Jan 2026"
String formatWaktuRelatif(DateTime waktu) {
  final t = waktu.toLocal();
  final now = DateTime.now();
  final selisih = now.difference(t);
  if (selisih.inMinutes < 1) return 'Baru saja';
  if (_hariSama(t, now)) {
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit yang lalu';
    return '${selisih.inHours} jam yang lalu';
  }
  if (_hariSama(t, now.subtract(const Duration(days: 1)))) {
    return 'Kemarin, ${_dua(t.hour)}:${_dua(t.minute)}';
  }
  return '${t.day} ${_bulan[t.month - 1].substring(0, 3)} ${t.year}';
}
