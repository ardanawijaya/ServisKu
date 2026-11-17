import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../core/service_types.dart';
import '../../../data/api_client.dart';
import '../../../data/models/service_record_model.dart';
import '../../../providers/service_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

/// Bottom sheet "Catat Servis Baru". Jika [record] diisi, mode ubah (ada tombol hapus).
class ServiceFormSheet extends StatefulWidget {
  const ServiceFormSheet({super.key, this.record});
  final ServiceRecordModel? record;

  static Future<void> show(BuildContext context, {ServiceRecordModel? record}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ServiceFormSheet(record: record),
    );
  }

  @override
  State<ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<ServiceFormSheet> {
  final _form = GlobalKey<FormState>();
  final _odo = TextEditingController();
  final _bengkel = TextEditingController();
  final _biaya = TextEditingController();
  final _catatan = TextEditingController();
  int? _vehicleId;
  DateTime _tanggal = DateTime.now();
  final Set<String> _jenis = {};
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    if (r != null) {
      _vehicleId = r.vehicleId;
      _tanggal = DateTime(r.tanggal.year, r.tanggal.month, r.tanggal.day);
      _odo.text = r.odometer.toString();
      _bengkel.text = r.namaBengkel;
      _biaya.text = r.biaya.toString();
      _catatan.text = r.catatan ?? '';
      _jenis.addAll(r.jenisServis.where(kJenisServis.contains));
    } else {
      final v = context.read<VehicleProvider>().selected;
      _vehicleId = v?.id;
      _odo.text = v?.odometerTerakhir.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _odo.dispose();
    _bengkel.dispose();
    _biaya.dispose();
    _catatan.dispose();
    super.dispose();
  }

  String get _apiDate {
    final m = _tanggal.month.toString().padLeft(2, '0');
    final d = _tanggal.day.toString().padLeft(2, '0');
    return '${_tanggal.year}-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _tanggal = picked);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_vehicleId == null) {
      setState(() => _error = 'Pilih kendaraan terlebih dahulu');
      return;
    }
    if (_jenis.isEmpty) {
      setState(() => _error = 'Pilih minimal satu jenis servis');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final sp = context.read<ServiceProvider>();
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final jenis = kJenisServis.where(_jenis.contains).toList();
    final catatan = _catatan.text.trim();

    try {
      if (_isEdit) {
        await sp.edit(
          widget.record!.id,
          tanggal: _apiDate,
          odometer: int.parse(_odo.text.trim()),
          jenisServis: jenis,
          namaBengkel: _bengkel.text.trim(),
          biaya: int.parse(_biaya.text.trim()),
          catatan: catatan,
        );
      } else {
        await sp.add(
          vehicleId: _vehicleId!,
          tanggal: _apiDate,
          odometer: int.parse(_odo.text.trim()),
          jenisServis: jenis,
          namaBengkel: _bengkel.text.trim(),
          biaya: int.parse(_biaya.text.trim()),
          catatan: catatan,
        );
      }
      // Odometer & "servis terakhir" kendaraan bisa ikut berubah
      await vp.load(silent: true);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(_isEdit ? 'Catatan servis diperbarui' : 'Catatan servis disimpan')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus catatan servis?'),
        content: const Text('Catatan ini akan dihapus dan jadwal pengingat dihitung ulang.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final sp = context.read<ServiceProvider>();
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);
    try {
      await sp.remove(widget.record!.id);
      await vp.load(silent: true);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Catatan servis dihapus')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _validateOdo(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Odometer wajib diisi';
    if (n < 0) return 'Odometer tidak boleh negatif';
    return null;
  }

  String? _validateBiaya(String? v) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return 'Total biaya wajib diisi';
    if (n < 0) return 'Biaya tidak boleh negatif';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().items;

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
                      color: AppColors.border, borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(height: 16),
              Text(_isEdit ? 'Ubah Catatan Servis' : 'Catat Servis Baru',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Simpan riwayat perawatan kendaraanmu.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),

              const _Label('Kendaraan'),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final v in vehicles) ...[
                      GestureDetector(
                        onTap: _isEdit
                            ? null
                            : () => setState(() {
                                  _vehicleId = v.id;
                                  _odo.text = v.odometerTerakhir.toString();
                                }),
                        child: Opacity(
                          opacity: _isEdit && v.id != _vehicleId ? 0.4 : 1,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: v.id == _vehicleId ? AppColors.primary : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: v.id == _vehicleId
                                      ? AppColors.primary
                                      : AppColors.border),
                            ),
                            child: Text(v.merekTipe,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: v.id == _vehicleId
                                        ? Colors.white
                                        : AppColors.muted)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              const _Label('Tanggal Servis'),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 20, color: AppColors.muted),
                      const SizedBox(width: 12),
                      Expanded(child: Text(formatTanggal(_tanggal))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Odometer Saat Servis (km)',
                hint: 'Contoh: 14250',
                icon: Icons.speed_outlined,
                controller: _odo,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateOdo,
              ),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                    'Jika lebih besar dari odometer kendaraan, odometer ikut diperbarui.',
                    style: TextStyle(color: AppColors.muted, fontSize: 11)),
              ),
              const SizedBox(height: 14),

              const _Label('Jenis Servis'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final j in kJenisServis)
                    GestureDetector(
                      onTap: () => setState(() {
                        _jenis.contains(j) ? _jenis.remove(j) : _jenis.add(j);
                      }),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _jenis.contains(j) ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _jenis.contains(j)
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_jenis.contains(j)) ...[
                              const Icon(Icons.check, size: 14, color: Colors.white),
                              const SizedBox(width: 4),
                            ],
                            Text(j,
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _jenis.contains(j)
                                        ? Colors.white
                                        : AppColors.muted)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              AppTextField(
                label: 'Nama Bengkel',
                hint: 'Contoh: AHASS Astra Motor BSD',
                icon: Icons.place_outlined,
                controller: _bengkel,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Nama bengkel wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Total Biaya',
                hint: '215000',
                icon: Icons.payments_outlined,
                prefixText: 'Rp ',
                controller: _biaya,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: _validateBiaya,
              ),
              const SizedBox(height: 14),

              const _Label('Catatan Perawatan (Opsional)'),
              TextFormField(
                controller: _catatan,
                maxLines: 3,
                maxLength: 1000,
                decoration: const InputDecoration(
                    hintText: 'Contoh: Oli SPX2 0.8L, stel rantai keteng'),
              ),

              if (_error != null) ...[
                const SizedBox(height: 8),
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
              const SizedBox(height: 12),
              AppButton(
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Catatan Servis',
                icon: Icons.check_circle_outline,
                loading: _loading,
                onPressed: _save,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.of(context).pop(),
                    child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
                  ),
                  if (_isEdit)
                    TextButton(
                      onPressed: _loading ? null : _delete,
                      child: const Text('Hapus Catatan',
                          style: TextStyle(color: AppColors.danger)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }
}
