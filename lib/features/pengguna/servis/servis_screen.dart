import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/models/service_record_model.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_header.dart';
import 'service_form_sheet.dart';

class ServisScreen extends StatefulWidget {
  const ServisScreen({super.key});

  @override
  State<ServisScreen> createState() => _ServisScreenState();
}

class _ServisScreenState extends State<ServisScreen> {
  int? _vehicleFilter; // null = semua kendaraan
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ServiceProvider>();
    final vp = context.watch<VehicleProvider>();

    final byVehicle = sp.items
        .where((r) => _vehicleFilter == null || r.vehicleId == _vehicleFilter)
        .toList();

    final q = _search.text.trim().toLowerCase();
    final list = byVehicle.where((r) {
      if (q.isEmpty) return true;
      return r.judul.toLowerCase().contains(q) ||
          r.namaBengkel.toLowerCase().contains(q) ||
          r.merekTipe.toLowerCase().contains(q);
    }).toList();

    final year = DateTime.now().year;
    final thisYear = byVehicle.where((r) => r.tanggal.year == year).toList();
    final totalBiaya = thisYear.fold<int>(0, (s, r) => s + r.biaya);
    final unitAktif = thisYear.map((r) => r.vehicleId).toSet().length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppHeader(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (vp.items.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Tambahkan kendaraan terlebih dahulu di tab Kendaraan')));
            return;
          }
          ServiceFormSheet.show(context);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Servis', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => sp.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat Servis',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      SizedBox(height: 2),
                      Text('Catatan perawatan kendaraanmu',
                          style: TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _search.clear();
                  }),
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari jenis servis atau nama bengkel',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua (${sp.items.length})',
                    selected: _vehicleFilter == null,
                    onTap: () => setState(() => _vehicleFilter = null),
                  ),
                  for (final v in vp.items) ...[
                    const SizedBox(width: 8),
                    _FilterChip(
                      label: v.merekTipe,
                      selected: _vehicleFilter == v.id,
                      onTap: () => setState(() => _vehicleFilter = v.id),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Ringkasan tahun ini
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.navy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TAHUN INI \u2022 $year',
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        const Text('Total Pengeluaran',
                            style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 2),
                        Text(formatRupiah(totalBiaya),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        const Text('Frekuensi',
                            style: TextStyle(color: Colors.white70, fontSize: 10)),
                        Text('${thisYear.length}\u00D7 Servis',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                        Text('$unitAktif Unit Aktif',
                            style: const TextStyle(color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text('Daftar Riwayat Perawatan',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),

            if (sp.loading && !sp.loaded)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (sp.error != null && sp.items.isEmpty)
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                text: sp.error!,
                actionLabel: 'Coba Lagi',
                onAction: () => sp.load(),
              )
            else if (list.isEmpty)
              _MessageCard(
                icon: Icons.receipt_long_outlined,
                text: sp.items.isEmpty
                    ? 'Belum ada catatan servis. Catat servis pertamamu.'
                    : 'Tidak ada catatan yang cocok.',
              )
            else
              for (final r in list) ...[
                _RecordCard(
                  record: r,
                  onTap: () => ServiceFormSheet.show(context, record: r),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onTap});
  final ServiceRecordModel record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = record;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: r.isMotor ? AppColors.blueSoft : AppColors.orangeSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    r.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded,
                    size: 16,
                    color: r.isMotor ? AppColors.primary : AppColors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(r.merekTipe,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
                Text(formatTanggal(r.tanggal),
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            Text(r.judul,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(r.namaBengkel,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
                if (r.dariBooking)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Via Booking',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF15803D))),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Biaya Servis',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    Text(formatRupiah(r.biaya),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Odometer',
                        style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    Text('${formatKm(r.odometer)} km',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
