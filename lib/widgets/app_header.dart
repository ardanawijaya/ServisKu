import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import 'initials_avatar.dart';

/// Header: logo di kiri, lonceng notifikasi + avatar inisial di kanan.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final unread = context.watch<NotificationProvider>().unreadCount;

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
        IconButton(
          tooltip: 'Notifikasi',
          onPressed: () => context.push('/notifikasi'),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none_rounded, color: AppColors.muted),
              if (unread > 0)
                Positioned(
                  right: -1,
                  top: -1,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (user != null) InitialsAvatar(initials: user.inisial, size: 36),
        const SizedBox(width: 16),
      ],
    );
  }
}
