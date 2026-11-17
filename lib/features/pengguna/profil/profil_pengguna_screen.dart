import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/initials_avatar.dart';

class ProfilPenggunaScreen extends StatelessWidget {
  const ProfilPenggunaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final jumlahKendaraan = context.watch<VehicleProvider>().items.length;
    final jumlahServis = context.watch<ServiceProvider>().items.length;
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppHeader(),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                InitialsAvatar(initials: user.inisial, size: 72),
                const SizedBox(height: 12),
                Text(user.nama,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(user.email,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 2),
                Text('+${user.noHp}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _Stat(value: '$jumlahKendaraan', label: 'KENDARAAN'),
                      _Stat(value: '$jumlahServis', label: 'CATATAN SERVIS'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final vp = context.read<VehicleProvider>();
                final sp = context.read<ServiceProvider>();
                await context.read<AuthProvider>().logout();
                vp.clear();
                sp.clear();
                if (context.mounted) context.go('/onboarding');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar dari Akun'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted)),
        ],
      ),
    );
  }
}
