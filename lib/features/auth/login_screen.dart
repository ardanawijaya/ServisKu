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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role});
  final String role;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _remember = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(
            identifier: _id.text.trim(),
            password: _pw.text,
            role: widget.role,
            remember: _remember,
          );
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
    final isBengkel = widget.role == 'bengkel';
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CenteredScroll(
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        context.canPop() ? context.pop() : context.go('/onboarding'),
                    icon: const Icon(Icons.arrow_back),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.bg),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                    child: Image.asset(AppAssets.logoOnboarding, height: 80)),
                const SizedBox(height: 12),
                const Center(
                  child: Text('Selamat Datang!',
                      style:
                          TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    isBengkel
                        ? 'Masuk sebagai Bengkel untuk mengelola booking.'
                        : 'Masuk untuk mengelola kendaraanmu.',
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                AppTextField(
                  label: 'Email atau Nomor Ponsel',
                  hint: 'Contoh: budi@email.com',
                  icon: Icons.mail_outline,
                  controller: _id,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      Validators.required(v, 'Email atau nomor ponsel'),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Kata Sandi',
                  hint: '********',
                  icon: Icons.lock_outline,
                  controller: _pw,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Kata sandi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _remember,
                        onChanged: (v) => setState(() => _remember = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Ingat Saya', style: TextStyle(fontSize: 13)),
                    const Spacer(),
                    TextButton(
                      onPressed: () => ScaffoldMessenger.of(context)
                          .showSnackBar(const SnackBar(
                              content: Text('Fitur ini belum tersedia'))),
                      child: const Text('Lupa Kata Sandi?',
                          style: TextStyle(
                              color: Color(0xFFB45309),
                              fontWeight: FontWeight.w700,
                              fontSize: 13)),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(_error!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 13)),
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: 'Masuk',
                  icon: Icons.arrow_forward,
                  loading: _loading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun? ',
                        style: TextStyle(fontSize: 13)),
                    GestureDetector(
                      onTap: () =>
                          context.pushReplacement('/register?role=${widget.role}'),
                      child: const Text('Daftar',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 13)),
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
