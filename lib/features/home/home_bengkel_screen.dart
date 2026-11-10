import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'home_placeholder.dart';

class HomeBengkelScreen extends StatelessWidget {
  const HomeBengkelScreen({super.key});

  @override
  Widget build(BuildContext context) => const HomePlaceholder(
        roleLabel: 'Bengkel',
        accent: AppColors.orange,
        accentSoft: AppColors.orangeSoft,
      );
}
