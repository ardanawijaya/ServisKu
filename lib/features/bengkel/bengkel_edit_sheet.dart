import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/validators.dart';
import '../../data/api_client.dart';
import '../../data/models/workshop_model.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

const kHariPreset = ['Senin - Jumat', 'Senin - Sabtu', 'Setiap Hari', 'Selasa - Minggu'];

/// Bottom sheet ubah profil bengkel.
class BengkelEditSheet extends StatefulWidget {
  const BengkelEditSheet({super.key, required this.workshop});
  final WorkshopModel workshop;

  static Future<void> show(BuildContext context, WorkshopModel workshop) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BengkelEditSheet(workshop: workshop),
    );
  }

  @override
  State<BengkelEditSheet> createState() => _BengkelEditSheetState();
}

class _BengkelEditSheetState extends State<BengkelEditSheet> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _spesialis = TextEditingController();
  final _kota = TextEditingController();
  final _alamat = TextEditingController();
  final _wa = TextEditingController();
  final _kuota = TextEditingController();
  late TimeOfDay _buka;
  late TimeOfDay _tutup;
  late String _hari;
  bool _loading = false;
  String? _error;

  static TimeOfDay _parse(String s) =>
      TimeOfDay(hour: int.parse(s.substring(0, 2)), minute: int.parse(s.substring(3, 5)));

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final w = widget.workshop;
    _nama.text = w.nama;
    _spesialis.text = w.spesialis ?? '';
    _kota.text = w.kota ?? '';
    _alamat.text = w.alamat ?? '';
    // Nomor tersimpan "62812..." -> tampil "812..." (prefix +62 ada di kolom)
    final wa = w.noWhatsapp ?? '';
    _wa.text = wa.startsWith('62') ? wa.substring(2) : wa;
    _kuota.text = w.kuotaHarian.toString();
    _buka = _parse(w.jamBuka);
    _tutup = _parse(w.jamTutup);
    _hari = w.hariOperasional;
  }

  @override
  void dispose() {
    for (final c in [_nama, _spesialis, _kota, _alamat, _wa, _kuota]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pilihJam(bool buka) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: buka ? _buka : _tutup,
    );
    if (picked != null) setState(() => buka ? _buka = picked : _tutup = picked);
  }

  String _waForApi() {
    var digits = _wa.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.startsWith('62')) digits = digits.substring(2);
    return '62$digits';
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final bukaMenit = _buka.hour * 60 + _buka.minute;
    final tutupMenit = _tutup.hour * 60 + _tutup.minute;
    if (tutupMenit <= bukaMenit) {
      setState(() => _error = 'Jam tutup harus setelah jam buka');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final wp = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await wp.updateProfile({
        'nama': _nama.text.trim(),
        'spesialis': _spesialis.text.trim(),
        'kota': _kota.text.trim(),
        'alamat': _alamat.text.trim(),
        'noWhatsapp': _waForApi(),
        'jamBuka': _fmt(_buka),
        'jamTutup': _fmt(_tutup),
        'hariOperasional': _hari,
        'kuotaHarian': int.parse(_kuota.text.trim()),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Profil bengkel diperbarui')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _jamTile(String label, TimeOfDay t, bool buka) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pilihJam(buka),
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
                  const Icon(Icons.access_time, size: 20, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Text(_fmt(t)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika hari lama bukan bagian dari preset, tetap tampilkan sebagai pilihan
    final hari = kHariPreset.contains(_hari) ? kHariPreset : [_hari, ...kHariPreset];

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
              const Text('Ubah Profil Bengkel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text('Informasi ini ditampilkan kepada pelanggan.',
                  style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Nama Bengkel',
                hint: 'Contoh: Bengkel Makmur Jaya',
                icon: Icons.storefront_outlined,
                controller: _nama,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Nama bengkel'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Spesialis (Opsional)',
                hint: 'Contoh: Spesialis Mobil & Motor',
                icon: Icons.star_outline,
                controller: _spesialis,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Kota',
                hint: 'Contoh: Surabaya',
                icon: Icons.location_city_outlined,
                controller: _kota,
                textInputAction: TextInputAction.next,
                validator: (v) => Validators.required(v, 'Kota'),
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Alamat Lengkap',
                hint: 'Jl. Ketintang No. 123, Gayungan',
                icon: Icons.place_outlined,
                controller: _alamat,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 5)
                    ? 'Alamat minimal 5 karakter'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Nomor WhatsApp',
                hint: '812-3456-7890',
                icon: Icons.phone_outlined,
                prefixText: '+62 ',
                controller: _wa,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: Validators.phone,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _jamTile('Jam Buka', _buka, true),
                  const SizedBox(width: 12),
                  _jamTile('Jam Tutup', _tutup, false),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Hari Operasional',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final h in hari)
                    GestureDetector(
                      onTap: () => setState(() => _hari = h),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _hari == h ? AppColors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _hari == h ? AppColors.orange : AppColors.border),
                        ),
                        child: Text(h,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _hari == h ? Colors.white : AppColors.muted)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Kuota Booking per Hari',
                hint: '10',
                icon: Icons.event_seat_outlined,
                controller: _kuota,
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null) return 'Kuota wajib diisi';
                  if (n < 1 || n > 200) return 'Kuota 1 sampai 200';
                  return null;
                },
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
                label: 'Simpan Perubahan',
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
