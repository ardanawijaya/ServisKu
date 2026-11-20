import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/api_client.dart';
import '../../data/models/workshop_model.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

const kKategoriLayanan = [
  'Oli & Pelumas',
  'Transmisi',
  'Pengereman',
  'Perawatan Berkala',
  'Ban & Spooring',
  'Kelistrikan',
  'Mesin',
  'Lainnya',
];

/// Bottom sheet tambah / ubah layanan bengkel.
class LayananFormSheet extends StatefulWidget {
  const LayananFormSheet({super.key, this.service});
  final WorkshopServiceModel? service;

  static Future<void> show(BuildContext context, {WorkshopServiceModel? service}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => LayananFormSheet(service: service),
    );
  }

  @override
  State<LayananFormSheet> createState() => _LayananFormSheetState();
}

class _LayananFormSheetState extends State<LayananFormSheet> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _deskripsi = TextEditingController();
  final _durasi = TextEditingController(text: '30');
  final _hargaMin = TextEditingController();
  final _hargaMax = TextEditingController();
  String _kategori = kKategoriLayanan.first;
  bool _loading = false;
  String? _error;

  bool get _isEdit => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    if (s != null) {
      _kategori = s.kategori;
      _nama.text = s.nama;
      _deskripsi.text = s.deskripsi ?? '';
      _durasi.text = s.durasiMenit.toString();
      _hargaMin.text = s.hargaMin.toString();
      _hargaMax.text = s.hargaMax.toString();
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _deskripsi.dispose();
    _durasi.dispose();
    _hargaMin.dispose();
    _hargaMax.dispose();
    super.dispose();
  }

  String? _angka(String? v, {int min = 0, String label = 'Nilai'}) {
    final n = int.tryParse((v ?? '').trim());
    if (n == null) return '$label wajib diisi';
    if (n < min) return '$label minimal $min';
    return null;
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final min = int.parse(_hargaMin.text.trim());
    final max = int.parse(_hargaMax.text.trim());
    if (max < min) {
      setState(() => _error = 'Harga maksimum tidak boleh lebih kecil dari harga minimum');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final wp = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final body = {
      'kategori': _kategori,
      'nama': _nama.text.trim(),
      'deskripsi': _deskripsi.text.trim(),
      'durasiMenit': int.parse(_durasi.text.trim()),
      'hargaMin': min,
      'hargaMax': max,
    };
    try {
      if (_isEdit) {
        await wp.editService(widget.service!.id, body);
      } else {
        await wp.addService(body);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
          SnackBar(content: Text(_isEdit ? 'Layanan diperbarui' : 'Layanan ditambahkan')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Jika kategori lama bukan bagian dari daftar bawaan, tetap tampilkan sebagai pilihan
    final kategori = kKategoriLayanan.contains(_kategori)
        ? kKategoriLayanan
        : [_kategori, ...kKategoriLayanan];

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
              Text(_isEdit ? 'Ubah Layanan' : 'Tambah Layanan',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              const Text('Kategori',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final k in kategori)
                    GestureDetector(
                      onTap: () => setState(() => _kategori = k),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _kategori == k ? AppColors.orange : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color:
                                  _kategori == k ? AppColors.orange : AppColors.border),
                        ),
                        child: Text(k,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _kategori == k
                                    ? Colors.white
                                    : AppColors.muted)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Nama Layanan',
                hint: 'Contoh: Ganti Oli Mesin & Filter',
                icon: Icons.build_outlined,
                controller: _nama,
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().length < 2)
                    ? 'Nama layanan wajib diisi'
                    : null,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Deskripsi (Opsional)',
                hint: 'Contoh: Termasuk cek 10 titik standar',
                icon: Icons.notes_outlined,
                controller: _deskripsi,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 14),
              AppTextField(
                label: 'Estimasi Durasi (menit)',
                hint: '30',
                icon: Icons.timer_outlined,
                controller: _durasi,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                validator: (v) => _angka(v, min: 5, label: 'Durasi'),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Harga Min',
                      hint: '65000',
                      icon: Icons.payments_outlined,
                      prefixText: 'Rp ',
                      controller: _hargaMin,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                      validator: (v) => _angka(v, label: 'Harga min'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: 'Harga Maks',
                      hint: '150000',
                      icon: Icons.payments_outlined,
                      prefixText: 'Rp ',
                      controller: _hargaMax,
                      keyboardType: TextInputType.number,
                      validator: (v) => _angka(v, label: 'Harga maks'),
                    ),
                  ),
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
                label: _isEdit ? 'Simpan Perubahan' : 'Simpan Layanan',
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
