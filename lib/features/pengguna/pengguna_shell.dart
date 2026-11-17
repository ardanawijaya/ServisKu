import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/service_provider.dart';
import '../../providers/vehicle_provider.dart';

/// Kerangka halaman pengguna: konten tab + bottom navigation.
class PenggunaShell extends StatefulWidget {
  const PenggunaShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<PenggunaShell> createState() => _PenggunaShellState();
}

class _PenggunaShellState extends State<PenggunaShell> {
  @override
  void initState() {
    super.initState();
    // Muat data kendaraan dan catatan servis sekali saat pengguna masuk
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<VehicleProvider>().load();
      context.read<ServiceProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final shell = widget.navigationShell;
    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Scaffold(
            backgroundColor: AppColors.bg,
            body: shell,
            bottomNavigationBar: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
              backgroundColor: Colors.white,
              indicatorColor: AppColors.blueSoft,
              height: 68,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.two_wheeler_outlined),
                    selectedIcon:
                        Icon(Icons.two_wheeler_rounded, color: AppColors.primary),
                    label: 'Kendaraan'),
                NavigationDestination(
                    icon: Icon(Icons.build_outlined),
                    selectedIcon: Icon(Icons.build_rounded, color: AppColors.primary),
                    label: 'Servis'),
                NavigationDestination(
                    icon: Icon(Icons.format_list_bulleted_rounded),
                    selectedIcon: Icon(Icons.format_list_bulleted_rounded,
                        color: AppColors.primary),
                    label: 'Booking'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary),
                    label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
