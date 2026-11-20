import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/workshop_provider.dart';

/// Kerangka halaman bengkel: konten tab + bottom navigation (Home, Layanan, Profil).
class BengkelShell extends StatefulWidget {
  const BengkelShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<BengkelShell> createState() => _BengkelShellState();
}

class _BengkelShellState extends State<BengkelShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WorkshopProvider>().load();
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
              indicatorColor: AppColors.orangeSoft,
              height: 68,
              destinations: const [
                NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded, color: AppColors.orange),
                    label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.build_outlined),
                    selectedIcon: Icon(Icons.build_rounded, color: AppColors.orange),
                    label: 'Layanan'),
                NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded, color: AppColors.orange),
                    label: 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
