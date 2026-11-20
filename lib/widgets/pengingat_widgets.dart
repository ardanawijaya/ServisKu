import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/formatters.dart';
import '../data/models/pengingat_model.dart';

/// Warna dan label untuk status aman / mendekati / terlambat.
class StatusStyle {
  final Color fg;
  final Color bg;
  final Color border;
  final String label;
  final IconData icon;

  const StatusStyle(this.fg, this.bg, this.border, this.label, this.icon);

  static StatusStyle of(String status) {
    switch (status) {
      case 'terlambat':
        return const StatusStyle(AppColors.danger, Color(0xFFFEF2F2), Color(0xFFFECACA),
            'Terlambat', Icons.warning_amber_rounded);
      case 'mendekati':
        return const StatusStyle(Color(0xFFB45309), Color(0xFFFEF3C7), Color(0xFFFCD34D),
            'Mendekati Jadwal', Icons.schedule_rounded);
      default:
        return const StatusStyle(Color(0xFF15803D), Color(0xFFDCFCE7), Color(0xFF86EFAC),
            'Aman', Icons.check_circle_outline);
    }
  }
}

String _desimal(double d) {
  final s = d.toStringAsFixed(1);
  return s.endsWith('.0') ? s.substring(0, s.length - 2) : s.replaceAll('.', ',');
}

/// Chip kecil: "Prima 95%"
class KondisiBadge extends StatelessWidget {
  const KondisiBadge({super.key, required this.pengingat});
  final PengingatModel pengingat;

  @override
  Widget build(BuildContext context) {
    final s = StatusStyle.of(pengingat.status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: s.border),
      ),
      child: Text('${pengingat.kondisiLabel} ${pengingat.kondisiPersen}%',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: s.fg)),
    );
  }
}

/// Bilah "Siklus Servis Berkala" di kartu kendaraan.
class SiklusBar extends StatelessWidget {
  const SiklusBar({super.key, required this.pengingat});
  final PengingatModel pengingat;

  @override
  Widget build(BuildContext context) {
    final e = pengingat.estimasi;
    final s = StatusStyle.of(e.status);
    final kanan = e.status == 'terlambat' ? 'Jatuh Tempo' : 'Sisa ${formatKm(e.sisaKm)} km';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Siklus Servis: ${e.komponen}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ),
            Text(kanan,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: s.fg)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (e.persenTerpakai.clamp(0, 100)) / 100,
            minHeight: 8,
            color: s.fg,
            backgroundColor: s.bg,
          ),
        ),
      ],
    );
  }
}

/// Kartu "Estimasi Servis Berikutnya" di Home.
class EstimasiCard extends StatelessWidget {
  const EstimasiCard({super.key, required this.pengingat});
  final PengingatModel pengingat;

  @override
  Widget build(BuildContext context) {
    final e = pengingat.estimasi;
    final s = StatusStyle.of(e.status);

    String utama;
    if (e.status == 'terlambat') {
      utama = 'Segera servis ${e.komponen}';
    } else {
      final hari = e.sisaHari != null ? '${e.sisaHari} hari lagi atau ' : '';
      utama = '$hari${formatKm(e.sisaKm)} km';
    }

    final rata = pengingat.rataRataKmPerHari;
    final catatan = rata != null
        ? 'Berdasarkan rata-rata harian ${_desimal(rata)} km/hari'
        : 'Rata-rata harian belum tersedia (butuh pembaruan odometer di hari yang berbeda)';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: s.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule_rounded, size: 14, color: s.fg),
                    const SizedBox(width: 6),
                    Text('ESTIMASI SERVIS BERIKUTNYA',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w800, color: s.fg)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(e.komponen,
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                const SizedBox(height: 2),
                Text(utama,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(catatan,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 58,
                  height: 58,
                  child: CircularProgressIndicator(
                    value: (e.persenTerpakai.clamp(0, 100)) / 100,
                    strokeWidth: 6,
                    color: s.fg,
                    backgroundColor: Colors.white,
                  ),
                ),
                Text('${e.persenTerpakai}%',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w800, color: s.fg)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Status Komponen & Siklus Aus": komponen dikelompokkan per status.
class StatusKomponenSection extends StatelessWidget {
  const StatusKomponenSection({super.key, required this.pengingat});
  final PengingatModel pengingat;

  String _detail(String status, KomponenModel k) {
    if (status == 'terlambat') {
      if (k.pemicu == 'waktu' && k.sisaHari != null) {
        if (k.sisaHari == 0) return 'Jatuh tempo hari ini';
        return 'Terlewat ${-k.sisaHari!} hari';
      }
      return 'Terlewat ${formatKm(-k.sisaKm)} km';
    }
    if (status == 'mendekati') {
      final hari = k.sisaHari != null ? ' (~${k.sisaHari} hari)' : '';
      return 'Tersisa ${formatKm(k.sisaKm)} km$hari';
    }
    return 'Sisa masa pakai ~${formatKm(k.sisaKm)} km';
  }

  @override
  Widget build(BuildContext context) {
    const urutan = ['aman', 'mendekati', 'terlambat'];
    final cards = <Widget>[];

    for (final status in urutan) {
      final grup = pengingat.komponen.where((k) => k.status == status).toList()
        ..sort((a, b) => a.persenSisa.compareTo(b.persenSisa));
      if (grup.isEmpty) continue;

      final s = StatusStyle.of(status);
      final nama = grup.take(2).map((k) => k.nama).join(' & ');
      final sisa = grup.length > 2 ? ' +${grup.length - 2} lainnya' : '';

      cards.add(Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: s.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Icon(s.icon, size: 18, color: s.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$nama$sisa',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(_detail(status, grup.first),
                      style: TextStyle(fontSize: 11, color: s.fg)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(10)),
              child: Text(s.label,
                  style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w800, color: s.fg)),
            ),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Status Komponen & Siklus Aus',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
            Text('${pengingat.komponen.length} Komponen Terpantau',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
        ),
        const SizedBox(height: 10),
        ...cards,
      ],
    );
  }
}
