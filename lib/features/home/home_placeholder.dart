import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/centered_scroll.dart';
import '../../widgets/initials_avatar.dart';

/// Halaman sementara setelah login. Akan diganti dengan home asli di tahap berikutnya.
class HomePlaceholder extends StatelessWidget {
  const HomePlaceholder({
    super.key,
    required this.roleLabel,
    required this.accent,
    required this.accentSoft,
  });

  final String roleLabel;
  final Color accent;
  final Color accentSoft;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 16,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Image.asset(AppAssets.logoHeader, height: 36),
        ),
        actions: [
          const Icon(Icons.notifications_none_rounded, color: AppColors.muted),
          const SizedBox(width: 12),
          InitialsAvatar(initials: user.inisial, size: 36),
          const SizedBox(width: 16),
        ],
      ),
      body: CenteredScroll(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InitialsAvatar(initials: user.inisial, size: 56),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Halo, ${user.nama}',
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: accentSoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(roleLabel,
                                  style: TextStyle(
                                      color: accent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _info(Icons.mail_outline, user.email),
                  const SizedBox(height: 8),
                  _info(Icons.phone_outlined, '+${user.noHp}'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Autentikasi berhasil. Fitur utama $roleLabel akan ditambahkan pada tahap berikutnya.',
                style: TextStyle(color: accent, fontSize: 13, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/onboarding');
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Keluar dari Akun'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _info(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      );
}
