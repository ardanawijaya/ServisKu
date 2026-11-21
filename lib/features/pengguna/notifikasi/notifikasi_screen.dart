import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/notification_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/pengingat_widgets.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _AksiNotif {
  const _AksiNotif(this.label, this.onTap);
  final String label;
  final VoidCallback onTap;
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  String _filter = 'semua'; // semua | perawatan | pengingat

  @override
  void initState() {
    super.initState();
    // Segarkan setiap kali layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<NotificationProvider>().load(silent: true);
    });
  }

  StatusStyle _gaya(String tipe) {
    switch (tipe) {
      case 'terlambat':
        return StatusStyle.of('terlambat');
      case 'mendekati':
        return StatusStyle.of('mendekati');
      case 'servis':
        return const StatusStyle(Color(0xFF15803D), Color(0xFFDCFCE7), Color(0xFF86EFAC),
            'Selesai', Icons.receipt_long_outlined);
      case 'booking':
        return const StatusStyle(Color(0xFF7C3AED), Color(0xFFEDE9FE), Color(0xFFC4B5FD),
            'Booking', Icons.event_available_outlined);
      default:
        return const StatusStyle(AppColors.primary, AppColors.blueSoft, Color(0xFFBFDBFE),
            'Pengingat KM', Icons.speed_rounded);
    }
  }

  void _ke(NotificationModel n, String path, {bool pilihKendaraan = false}) {
    context.read<NotificationProvider>().markRead(n.id);
    if (pilihKendaraan && n.vehicleId != null) {
      context.read<VehicleProvider>().select(n.vehicleId!);
    }
    context.go(path);
  }

  _AksiNotif? _aksi(NotificationModel n) {
    switch (n.tipe) {
      case 'pengingat_km':
        return _AksiNotif('Update Odometer \u2192',
            () => _ke(n, '/home/pengguna', pilihKendaraan: true));
      case 'mendekati':
      case 'terlambat':
        // Integrasi pengingat -> booking
        return _AksiNotif('Booking Sekarang \u2192',
            () => _ke(n, '/home/pengguna/booking', pilihKendaraan: true));
      case 'booking':
        return _AksiNotif('Lihat Booking \u2192', () => _ke(n, '/home/pengguna/booking'));
      case 'servis':
        return _AksiNotif('Lihat Riwayat \u2192', () => _ke(n, '/home/pengguna/servis'));
    }
    return null;
  }

  List<Widget> _section(String judul, List<NotificationModel> data) {
    if (data.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 10),
        child: Text(judul,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
      ),
      for (final n in data) ...[
        _NotifCard(
          n: n,
          gaya: _gaya(n.tipe),
          onTap: () => context.read<NotificationProvider>().markRead(n.id),
          aksi: _aksi(n),
        ),
        const SizedBox(height: 10),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final np = context.watch<NotificationProvider>();
    final semua = np.items;
    final list =
        semua.where((n) => _filter == 'semua' || n.kategori == _filter).toList();
    final hariIni = list.where((n) => hariIniLokal(n.createdAt)).toList();
    final sebelumnya = list.where((n) => !hariIniLokal(n.createdAt)).toList();
    final jmlPerawatan = semua.where((n) => n.kategori == 'perawatan').length;
    final jmlPengingat = semua.where((n) => n.kategori == 'pengingat').length;

    return Container(
      color: Colors.white,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Scaffold(
            backgroundColor: AppColors.bg,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go('/home/pengguna'),
                icon: const Icon(Icons.arrow_back),
              ),
              titleSpacing: 0,
              title: Row(
                children: [
                  const Text('Notifikasi',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  if (np.unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('${np.unreadCount} Belum Dibaca',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.danger)),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton.icon(
                  onPressed: np.unreadCount == 0 ? null : () => np.markAllRead(),
                  icon: const Icon(Icons.done_all, size: 16),
                  label: const Text('Tandai dibaca'),
                  style: TextButton.styleFrom(
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
            body: RefreshIndicator(
              onRefresh: () => np.load(silent: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _Chip(
                          label: 'Semua (${semua.length})',
                          selected: _filter == 'semua',
                          onTap: () => setState(() => _filter = 'semua'),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Perawatan ($jmlPerawatan)',
                          selected: _filter == 'perawatan',
                          onTap: () => setState(() => _filter = 'perawatan'),
                        ),
                        const SizedBox(width: 8),
                        _Chip(
                          label: 'Pengingat KM ($jmlPengingat)',
                          selected: _filter == 'pengingat',
                          onTap: () => setState(() => _filter = 'pengingat'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (np.loading && !np.loaded)
                    const Padding(
                      padding: EdgeInsets.only(top: 48),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (np.error != null && semua.isEmpty)
                    _Pesan(
                      icon: Icons.cloud_off_outlined,
                      teks: np.error!,
                      aksi: 'Coba Lagi',
                      onAksi: () => np.load(),
                    )
                  else if (list.isEmpty)
                    const _Pesan(
                      icon: Icons.notifications_none_rounded,
                      teks: 'Belum ada notifikasi.',
                    )
                  else ...[
                    ..._section('HARI INI', hariIni),
                    ..._section('KEMARIN & SEBELUMNYA', sebelumnya),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.muted)),
      ),
    );
  }
}

class _Pesan extends StatelessWidget {
  const _Pesan({required this.icon, required this.teks, this.aksi, this.onAksi});
  final IconData icon;
  final String teks;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.muted),
          const SizedBox(height: 10),
          Text(teks,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          if (aksi != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAksi, child: Text(aksi!)),
          ],
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  const _NotifCard({
    required this.n,
    required this.gaya,
    required this.onTap,
    this.aksi,
  });

  final NotificationModel n;
  final StatusStyle gaya;
  final VoidCallback onTap;
  final _AksiNotif? aksi;

  @override
  Widget build(BuildContext context) {
    final kendaraan = n.merekTipe == null ? null : '${n.merekTipe} \u2022 ${n.platNomor}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: n.isRead ? AppColors.border : gaya.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(color: gaya.bg, shape: BoxShape.circle),
              child: Icon(gaya.icon, size: 18, color: gaya.fg),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: gaya.bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(gaya.label,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: gaya.fg)),
                      ),
                      const SizedBox(width: 8),
                      if (kendaraan != null)
                        Expanded(
                          child: Text(kendaraan,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.muted)),
                        )
                      else
                        const Spacer(),
                      if (!n.isRead)
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                              color: AppColors.primary, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(n.judul,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: n.isRead ? FontWeight.w700 : FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(n.isi,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.muted, height: 1.45)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (aksi != null)
                        InkWell(
                          onTap: aksi!.onTap,
                          child: Text(aksi!.label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                        ),
                      const Spacer(),
                      const Icon(Icons.schedule, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Text(formatWaktuRelatif(n.createdAt),
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
