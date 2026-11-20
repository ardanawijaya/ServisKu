/// "Bengkel Makmur Jaya" -> "BMJ" (maksimal [maks] huruf)
String inisialNama(String nama, {int maks = 3}) {
  final parts = nama.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return parts.take(maks).map((p) => p[0].toUpperCase()).join();
}
