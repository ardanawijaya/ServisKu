import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/validators.dart';
import '../../../data/api_client.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// Bottom sheet tambah / ubah kendaraan. Jika [vehicle] diisi, mode ubah.
class VehicleFormSheet extends StatefulWidget {
  const VehicleFormSheet({super.key, this.vehicle});
  final VehicleModel? vehicle;

  static Future<void> show(BuildContext context, {VehicleModel? vehicle}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => VehicleFormSheet(vehicle: vehicle),
    );
  }

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _form = GlobalKey<FormState>();
  final _merek = TextEditingController();
  final _plat = TextEditingController();
  final _tahun = TextEditingController();
  final _odo = TextEditingController();
  String _jenis = 'motor';
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _jenis = v.jenis;
      _merek.text = v.merekTipe;
      _plat.text = v.platNomor;
      _tahun.text = v.tahun.toString();
    }
  }

  @override
  void dispose() {
    _merek.dispose();
    _plat.dispose();
    _tahun.dispose();
    _odo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (_isEdit) {
        await vp.edit(
          widget.vehicle!.id,
          merekTipe: _merek.text.trim(),
          platNomor: _plat.text.trim(),
          tahun: int.parse(_tahun.text.trim()),
        );
      } else {
        await vp.add(
          jenis: _jenis,
          merekTipe: _merek.text.trim(),
          platNomor: _plat.text.trim(),
          tahun: int.parse(_tahun.text.trim()),
          odometer: int.parse(_odo.text.trim()),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Kendaraan diperbarui' : 'Kendaraan ditambahkan')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateTahun(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Tahun wajib diisi';
    if (n < 1980 || n > DateTime.now().year + 1) return 'Tahun tidak valid';
    return null;
  }

  String? _validateOdo(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Odometer wajib diisi';
    if (n < 0) return 'Odometer tidak boleh negatif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(_isEdit ? 'Ubah Kendaraan' : 'Tambah Kendaraan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(
                _isEdit
                    ? 'Perbarui data kendaraanmu.'
                    : 'Daftarkan motor atau mobil baru ke garasi digital ServisKu.',
                style: const TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              const SizedBox(height: 16),
              const Text('Jenis Kendaraan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Opacity(
                opacity: _isEdit ? 0.5 : 1,
                child: Row(
                  children: [
                    Expanded(
                      child: _JenisTile(
                        icon: Icons.two_wheeler_rounded,
                        label: 'Sepeda Motor',
                        selected: _jenis == 'motor',
                        onTap: _isEdit ? null : () => setState(() => _jenis = 'motor'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _JenisTile(
                        icon: Icons.directions_car_filled_rounded,
                        label: 'Mobil',
                        selected: _jenis == 'mobil',
                        onTap: _isEdit ? null : () => setState(() => _jenis = 'mobil'),
                      ),
                    ),
                  ],
                ),
              ),
              if (_isEdit)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Jenis kendaraan tidak dapat diubah.',
                      style: TextStyle(color: AppColors.muted, fontSize: 11)),
                ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Merek & Tipe Kendaraan',
                hint: 'Contoh: Honda PCX 160 ABS',
                icon: Icons.two_wheeler_outlined,
                controller: _merek,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Merek & tipe'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Plat Nomor Polisi',
                hint: 'Contoh: B 3819 TXZ',
                icon: Icons.badge_outlined,
                controller: _plat,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Plat nomor'),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Tahun Pembuatan',
                      hint: '2023',
                      icon: Icons.calendar_today_outlined,
                      controller: _tahun,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: _validateTahun,
                    ),
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        label: 'Odometer Awal (km)',
                        hint: '12500',
                        icon: Icons.speed_outlined,
                        controller: _odo,
                        keyboardType: TextInputType.number,
                        validator: _validateOdo,
                      ),
                    ),
                  ],
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 13)),
                ),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Kendaraan',
                icon: Icons.check_circle_outline,
                loading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _loading ? null : () => Navigator.of(context).pop(),
                  child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JenisTile extends StatelessWidget {
  const _JenisTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.blueSoft : AppColors.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? AppColors.primary : AppColors.muted),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? AppColors.primary : AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
