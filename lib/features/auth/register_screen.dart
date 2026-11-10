import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/router.dart';
import '../../core/validators.dart';
import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/centered_scroll.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.role});
  final String role;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _hp = TextEditingController();
  final _pw = TextEditingController();
  final _pw2 = TextEditingController();
  final _namaBengkel = TextEditingController();
  final _kota = TextEditingController();
  bool _agree = false;
  bool _loading = false;
  String? _error;

  bool get _isBengkel => widget.role == 'bengkel';

  @override
  void dispose() {
    for (final c in [_nama, _email, _hp, _pw, _pw2, _namaBengkel, _kota]) {
      c.dispose();
    }
    super.dispose();
  }

  // Input "812-3456-7890" -> "6281234567890"
  String _phoneForApi() {
    var digits = _hp.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('62')) digits = digits.substring(2);
    return '62$digits';
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = 'Setujui Syarat & Ketentuan terlebih dahulu');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register({
        'role': widget.role,
        'nama': _nama.text.trim(),
        'email': _email.text.trim(),
        'noHp': _phoneForApi(),
        'password': _pw.text,
        'konfirmasiPassword': _pw2.text,
        if (_isBengkel) 'namaBengkel': _namaBengkel.text.trim(),
        if (_isBengkel) 'kota': _kota.text.trim(),
      });
      if (!mounted) return;
      context.go(homePathFor(widget.role));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CenteredScroll(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/onboarding'),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.bg,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blueSoft,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isBengkel ? 'BUAT AKUN BENGKEL' : 'BUAT AKUN BARU',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // penyeimbang lebar tombol back
                  ],
                ),
                const SizedBox(height: 12),
                Image.asset(AppAssets.logoHeader, height: 60),
                const SizedBox(height: 8),
                Text(
                  _isBengkel
                      ? 'Daftarkan bengkelmu dan kelola booking dengan mudah.'
                      : 'Mulai pantau jadwal servis & riwayat kendaraan Anda dengan mudah.',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: _isBengkel ? 'Nama Pemilik' : 'Nama Lengkap',
                  hint: 'Contoh: Budi Santoso',
                  icon: Icons.badge_outlined,
                  controller: _nama,
                  trailingLabel: '*Wajib',
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().length < 2) {
                      return 'Nama minimal 2 karakter';
                    }
                    return null;
                  },
                ),
                if (_isBengkel) ...[
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Nama Bengkel',
                    hint: 'Contoh: Bengkel Makmur Jaya',
                    icon: Icons.storefront_outlined,
                    controller: _namaBengkel,
                    trailingLabel: '*Wajib',
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Nama bengkel'),
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: 'Kota',
                    hint: 'Contoh: Surabaya',
                    icon: Icons.location_city_outlined,
                    controller: _kota,
                    trailingLabel: '*Wajib',
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.required(v, 'Kota'),
                  ),
                ],
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Alamat Email',
                  hint: 'Contoh: budi@email.com',
                  icon: Icons.mail_outline,
                  controller: _email,
                  trailingLabel: '*Wajib',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Nomor WhatsApp / Ponsel',
                  hint: '812-3456-7890',
                  icon: Icons.phone_outlined,
                  prefixText: '+62 ',
                  controller: _hp,
                  trailingLabel: '*Wajib',
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: Validators.phone,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Kata Sandi',
                  hint: 'Minimal 8 karakter',
                  icon: Icons.lock_outline,
                  controller: _pw,
                  trailingLabel: 'Min. 8 Karakter',
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  validator: Validators.password,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  label: 'Konfirmasi Kata Sandi',
                  hint: 'Ulangi kata sandi',
                  icon: Icons.verified_user_outlined,
                  controller: _pw2,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v != _pw.text ? 'Konfirmasi kata sandi tidak sama' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: TextStyle(fontSize: 12, height: 1.4),
                          children: [
                            TextSpan(text: 'Saya menyetujui '),
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' serta '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' ServisKu.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: 'Daftar Sekarang',
                  icon: Icons.arrow_forward,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Sudah punya akun? ',
                      style: TextStyle(fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () =>
                          context.pushReplacement('/login?role=${widget.role}'),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
