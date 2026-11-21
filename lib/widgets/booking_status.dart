import 'package:flutter/material.dart';
import '../core/constants.dart';
import 'pengingat_widgets.dart';

/// Warna & label status booking (dipakai di sisi pengguna dan bengkel).
StatusStyle gayaBooking(String status) {
  switch (status) {
    case 'menunggu':
      return const StatusStyle(Color(0xFFB45309), Color(0xFFFEF3C7), Color(0xFFFCD34D),
          'Menunggu Konfirmasi', Icons.hourglass_top_rounded);
    case 'dikonfirmasi':
      return const StatusStyle(AppColors.primary, AppColors.blueSoft, Color(0xFFBFDBFE),
          'Dikonfirmasi', Icons.event_available_outlined);
    case 'dikerjakan':
      return const StatusStyle(Color(0xFF7C3AED), Color(0xFFEDE9FE), Color(0xFFC4B5FD),
          'Sedang Dikerjakan', Icons.build_circle_outlined);
    case 'selesai':
      return const StatusStyle(Color(0xFF15803D), Color(0xFFDCFCE7), Color(0xFF86EFAC),
          'Selesai', Icons.check_circle_outline);
    case 'ditolak':
      return const StatusStyle(AppColors.danger, Color(0xFFFEF2F2), Color(0xFFFECACA),
          'Ditolak', Icons.cancel_outlined);
    default:
      return const StatusStyle(AppColors.muted, Color(0xFFF1F5F9), AppColors.border,
          'Dibatalkan', Icons.block_outlined);
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final s = gayaBooking(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: s.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 12, color: s.fg),
          const SizedBox(width: 4),
          Text(s.label,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.fg)),
        ],
      ),
    );
  }
}
