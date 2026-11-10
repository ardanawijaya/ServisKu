import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'home_placeholder.dart';

class HomePenggunaScreen extends StatelessWidget {
  const HomePenggunaScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomePlaceholder(
        roleLabel: 'Pengguna',
        accent: AppColors.primary,
        accentSoft: AppColors.blueSoft,
      );
}
