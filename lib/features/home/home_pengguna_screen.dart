import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/api_client.dart';
import '../../data/models/vehicle_model.dart';
import '../../providers/vehicle_provider.dart';
import '../../widgets/app_header.dart';
import '../../widgets/pengingat_widgets.dart';
import '../pengguna/kendaraan/vehicle_form_sheet.dart';

class HomePenggunaScreen extends StatefulWidget {
  const HomePenggunaScreen({super.key});

  @override
  State<HomePenggunaScreen> createState() => _HomePenggunaScreenState();
}

class _HomePenggunaScreenState extends State<HomePenggunaScreen> {
  final _km = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _updateKm(VehicleModel v) async {
    final km = int.tryParse(_km.text.trim());
    if (km == null) {
      setState(() => _error = 'Masukkan angka kilometer yang valid');
      return;
    }
    if (km <= v.odometerTerakhir) {
      setState(
        () => _error =
            'Odometer baru harus lebih besar dari ${formatKm(v.odometerTerakhir)} km',
      );
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final selisih = await vp.updateOdometer(v.id, km);
      _km.clear();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Odometer diperbarui (+${formatKm(selisih)} km)'),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final v = vp.selected;

    Widget body;
    if (vp.loading && !vp.loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (v == null) {
      body = _EmptyState(
        message:
            vp.error ?? 'Belum ada kendaraan. Tambahkan kendaraan pertamamu.',
        isError: vp.error != null,
        onAction: () =>
            vp.error != null ? vp.load() : VehicleFormSheet.show(context),
      );
    } else {
      final p = v.pengingat;
      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Pilihan kendaraan
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in vp.items) ...[
                  GestureDetector(
                    onTap: () {
                      vp.select(item.id);
                      _km.clear();
                      setState(() => _error = null);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: item.id == v.id
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: item.id == v.id
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        item.merekTipe,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: item.id == v.id
                              ? Colors.white
                              : AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Kartu kendaraan + update odometer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: v.isMotor
                            ? AppColors.blueSoft
                            : AppColors.orangeSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        v.isMotor
                            ? Icons.two_wheeler_rounded
                            : Icons.directions_car_filled_rounded,
                        color: v.isMotor ? AppColors.primary : AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.merekTipe,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            v.servisTerakhir == null
                                ? '${v.platNomor} | Belum ada catatan servis'
                                : '${v.platNomor} | Terakhir Servis : ${formatTanggal(v.servisTerakhir!)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (p != null) ...[
                      const SizedBox(width: 8),
                      KondisiBadge(pengingat: p),
                    ],
                  ],
                ),
                const Divider(height: 28),
                const Text(
                  'Jarak Tempuh Terakhir',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatKm(v.odometerTerakhir),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'km',
                      style: TextStyle(fontSize: 14, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Input KM Baru',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _km,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    hintText: formatKm(v.odometerTerakhir + 100),
                    suffixText: 'KM',
                  ),
                  onSubmitted: (_) => _updateKm(v),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : () => _updateKm(v),
                    icon: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Update Odometer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orangeSoft,
                      foregroundColor: const Color(0xFFB45309),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (p != null) ...[
            EstimasiCard(pengingat: p),
            if (p.estimasi.status != 'aman') ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home/pengguna/booking'),
                  icon: const Icon(Icons.event_available_outlined, size: 18),
                  label: const Text('Booking Servis Sekarang'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            StatusKomponenSection(pengingat: p),
          ] else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Data pengingat belum tersedia untuk kendaraan ini. Pastikan data master komponen sudah di-seed di backend.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary,
                  height: 1.5,
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppHeader(),
      body: body,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.message,
    required this.isError,
    required this.onAction,
  });
  final String message;
  final bool isError;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isError ? Icons.cloud_off_outlined : Icons.two_wheeler_outlined,
              size: 48,
              color: AppColors.muted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              child: Text(isError ? 'Coba Lagi' : 'Tambah Kendaraan'),
            ),
          ],
        ),
      ),
    );
  }
}
