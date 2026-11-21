import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/api_client.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

BoxDecoration _handleDecoration() =>
    BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(4));

Future<void> _tampilkanSheet(BuildContext context, Widget child) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    constraints: const BoxConstraints(maxWidth: 480),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => child,
  );
}

/// Bottom sheet ubah data akun (nama, email, nomor ponsel).
class EditAkunSheet extends StatefulWidget {
  const EditAkunSheet({super.key});

  static Future<void> show(BuildContext context) =>
      _tampilkanSheet(context, const EditAkunSheet());

  @override
  State<EditAkunSheet> createState() => _EditAkunSheetState();
}

class _EditAkunSheetState extends State<EditAkunSheet> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _hp = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    if (u != null) {
      _nama.text = u.nama;
      _email.text = u.email;
      // "62812..." -> "812..." (prefix +62 sudah ada di kolom)
      _hp.text = u.noHp.startsWith('62') ? u.noHp.substring(2) : u.noHp;
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _hp.dispose();
    super.dispose();
  }

  String _hpForApi() {
    var digits = _hp.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('62')) digits = digits.substring(2);
    return '62$digits';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.updateProfile(
        nama: _nama.text.trim(),
        email: _email.text.trim(),
        noHp: _hpForApi(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Data akun diperbarui')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: _handleDecoration())),
              const SizedBox(height: 16),
              const Text('Edit Profil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Perbarui data akunmu.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama Lengkap',
                hint: 'Contoh: Budi Santoso',
                icon: Icons.badge_outlined,
                controller: _nama,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Nama minimal 2 karakter'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Alamat Email',
                hint: 'Contoh: budi@email.com',
                icon: Icons.mail_outline,
                controller: _email,
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
                keyboardType: TextInputType.phone,
                validator: Validators.phone,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBox(_error!),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: 'Simpan Perubahan',
                icon: Icons.check_circle_outline,
                loading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet ganti kata sandi.
class GantiSandiSheet extends StatefulWidget {
  const GantiSandiSheet({super.key});

  static Future<void> show(BuildContext context) =>
      _tampilkanSheet(context, const GantiSandiSheet());

  @override
  State<GantiSandiSheet> createState() => _GantiSandiSheetState();
}

class _GantiSandiSheetState extends State<GantiSandiSheet> {
  final _form = GlobalKey<FormState>();
  final _lama = TextEditingController();
  final _baru = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _lama.dispose();
    _baru.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await auth.changePassword(_lama.text, _baru.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Kata sandi berhasil diubah')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: _handleDecoration())),
              const SizedBox(height: 16),
              const Text('Ganti Kata Sandi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Gunakan kata sandi minimal 8 karakter.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Kata Sandi Lama',
                hint: 'Masukkan kata sandi saat ini',
                icon: Icons.lock_outline,
                controller: _lama,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Kata sandi lama wajib diisi' : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Kata Sandi Baru',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_reset_outlined,
                controller: _baru,
                isPassword: true,
                textInputAction: TextInputAction.next,
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Konfirmasi Kata Sandi Baru',
                hint: 'Ulangi kata sandi baru',
                icon: Icons.verified_user_outlined,
                controller: _konfirmasi,
                isPassword: true,
                validator: (v) =>
                    v != _baru.text ? 'Konfirmasi kata sandi tidak sama' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                _ErrorBox(_error!),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: 'Ubah Kata Sandi',
                icon: Icons.check_circle_outline,
                loading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox(this.pesan);
  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(pesan, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
    );
  }
}

/// Baris menu bergaya daftar pengaturan.
class MenuAkunTile extends StatelessWidget {
  const MenuAkunTile({
    super.key,
    required this.icon,
    required this.judul,
    required this.keterangan,
    required this.onTap,
    this.warna = AppColors.primary,
    this.warnaLatar = AppColors.blueSoft,
  });

  final IconData icon;
  final String judul;
  final String keterangan;
  final VoidCallback onTap;
  final Color warna;
  final Color warnaLatar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: warnaLatar, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, size: 20, color: warna),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(keterangan,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
