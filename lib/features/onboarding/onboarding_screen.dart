import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../widgets/app_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _role = 'pengguna';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Tinggi minimal 720 agar tidak sesak di layar pendek (akan bisa di-scroll)
                final height =
                    constraints.maxHeight < 720 ? 720.0 : constraints.maxHeight;
                return SingleChildScrollView(
                  child: SizedBox(
                    height: height,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          Image.asset(AppAssets.logoOnboarding, height: 90),
                          const SizedBox(height: 12),
                          const Text('Selamat Datang!',
                              style: TextStyle(
                                  fontSize: 28, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 6),
                          const Text('Masuk untuk mengelola kendaraanmu.',
                              style: TextStyle(
                                  color: AppColors.muted, fontSize: 13)),
                          const SizedBox(height: 20),
                          _buildRoleCard(),
                          const Spacer(flex: 1),
                          _buildBottomInfo(),
                          const SizedBox(height: 32),
                          AppButton(
                            label: 'Mulai',
                            icon: Icons.arrow_forward,
                            onPressed: () => context.push('/login?role=$_role'),
                          ),
                          const SizedBox(height: 64),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Login / Daftar Sebagai ?',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _RoleTile(
                  icon: Icons.directions_car_filled_rounded,
                  title: 'Pengguna',
                  subtitle: 'Saatnya Merawat\nKendaraan',
                  color: AppColors.primary,
                  soft: AppColors.blueSoft,
                  selected: _role == 'pengguna',
                  onTap: () => setState(() => _role = 'pengguna'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RoleTile(
                  icon: Icons.two_wheeler_rounded,
                  title: 'Bengkel',
                  subtitle: 'Kelola Booking\nOnline',
                  color: AppColors.orange,
                  soft: AppColors.orangeSoft,
                  selected: _role == 'bengkel',
                  onTap: () => setState(() => _role = 'bengkel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInfo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 14, color: AppColors.primary),
              SizedBox(width: 6),
              Text('Semua Kendaraan Dalam 1 Garasi',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Kelola Semua Kendaraan',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        const Text(
          'Simpan data mobil dan motor Anda dalam satu garasi digital yang praktis, rapi, dan mudah diakses.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.5),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.soft,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color soft;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: color, height: 1.3)),
          ],
        ),
      ),
    );
  }
}