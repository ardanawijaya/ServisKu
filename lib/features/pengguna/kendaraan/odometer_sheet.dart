import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/api_client.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_button.dart';

/// Bottom sheet untuk memperbarui odometer satu kendaraan.
class OdometerSheet extends StatefulWidget {
  const OdometerSheet({super.key, required this.vehicle});
  final VehicleModel vehicle;

  static Future<void> show(BuildContext context, VehicleModel vehicle) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => OdometerSheet(vehicle: vehicle),
    );
  }

  @override
  State<OdometerSheet> createState() => _OdometerSheetState();
}

class _OdometerSheetState extends State<OdometerSheet> {
  final _km = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _km.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final km = int.tryParse(_km.text.trim());
    final current = widget.vehicle.odometerTerakhir;
    if (km == null) {
      setState(() => _error = 'Masukkan angka kilometer yang valid');
      return;
    }
    if (km <= current) {
      setState(() =>
          _error = 'Odometer baru harus lebih besar dari ${formatKm(current)} km');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final selisih = await vp.updateOdometer(widget.vehicle.id, km);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text('Odometer diperbarui (+${formatKm(selisih)} km)')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border, borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Update Odometer',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('${v.merekTipe} (${v.platNomor})',
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            Text('Odometer saat ini: ${formatKm(v.odometerTerakhir)} km',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextField(
              controller: _km,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(hintText: 'Input KM baru', suffixText: 'KM'),
              onSubmitted: (_) => _save(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            AppButton(
              label: 'Simpan Odometer',
              icon: Icons.check_circle_outline,
              loading: _loading,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }
}
