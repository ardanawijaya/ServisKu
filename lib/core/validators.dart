class Validators {
  static String? required(String? v, [String label = 'Kolom ini']) =>
      (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Format email tidak valid';
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8) return 'Kata sandi minimal 8 karakter';
    return null;
  }

  static String? phone(String? v) {
    final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (digits.length < 8 || digits.length > 13) return 'Nomor tidak valid';
    return null;
  }
}
