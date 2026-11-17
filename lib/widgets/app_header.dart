import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import 'initials_avatar.dart';

/// Header: logo di kiri, ikon notifikasi + avatar inisial di kanan.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 60,
      titleSpacing: 16,
      title: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(AppAssets.logoHeader, height: 36),
      ),
      actions: [
        const Icon(Icons.notifications_none_rounded, color: AppColors.muted),
        const SizedBox(width: 12),
        if (user != null) InitialsAvatar(initials: user.inisial, size: 36),
        const SizedBox(width: 16),
      ],
    );
  }
}
