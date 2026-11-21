import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/api_client.dart';
import '../../data/models/booking_model.dart';
import '../../providers/bengkel_booking_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

enum BookingAksi { tolak, mulai, selesai }

/// Bottom sheet aksi bengkel: tolak (alasan), mulai (mekanik), selesai (biaya akhir + catatan).
class BookingActionSheet extends StatefulWidget {
  const BookingActionSheet({super.key, required this.booking, required this.aksi});
  final BookingModel booking;
  final BookingAksi aksi;

  static Future<void> show(BuildContext context, BookingModel booking, BookingAksi aksi) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BookingActionSheet(booking: booking, aksi: aksi),
    );
  }

  @override
  State<BookingActionSheet> createState() => _BookingActionSheetState();
}

class _BookingActionSheetState extends State<BookingActionSheet> {
  final _form = GlobalKey<FormState>();
  final _teks = TextEditingController(); // alasan / mekanik
  final _catatan = TextEditingController();
  final _biaya = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.aksi == BookingAksi.selesai) {
      _biaya.text = widget.booking.estimasiBiaya.toString();
    }
  }

  @override
  void dispose() {
    _teks.dispose();
    _catatan.dispose();
    _biaya.dispose();
    super.dispose();
  }

  String get _judul {
    switch (widget.aksi) {
      case BookingAksi.tolak:
        return 'Tolak Booking';
      case BookingAksi.mulai:
        return 'Mulai Dikerjakan';
      case BookingAksi.selesai:
        return 'Tandai Selesai';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = context.read<BengkelBookingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final b = widget.booking;
    try {
      switch (widget.aksi) {
        case BookingAksi.tolak:
          await p.tolak(b.id, _teks.text.trim());
          break;
        case BookingAksi.mulai:
          await p.mulai(b.id, _teks.text.trim());
          break;
        case BookingAksi.selesai:
          await p.selesai(b.id, int.parse(_biaya.text.trim()), _catatan.text.trim());
          break;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
          content: Text(widget.aksi == BookingAksi.selesai
              ? 'Booking selesai. Catatan servis pelanggan tersimpan otomatis.'
              : widget.aksi == BookingAksi.tolak
                  ? 'Booking ditolak'
                  : 'Pengerjaan dimulai')));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.booking;
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
              Text(_judul,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text('${b.pelangganNama} \u2022 ${b.merekTipe} (${b.platNomor})',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              Text('${formatTanggal(b.tanggal)}, ${b.jam} WIB',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 16),
              if (widget.aksi == BookingAksi.tolak)
                AppTextField(
                  label: 'Alasan Penolakan',
                  hint: 'Contoh: Slot hari ini sudah penuh',
                  icon: Icons.info_outline,
                  controller: _teks,
                  validator: (v) => (v == null || v.trim().length < 3)
                      ? 'Alasan minimal 3 karakter'
                      : null,
                ),
              if (widget.aksi == BookingAksi.mulai)
                AppTextField(
                  label: 'Nama Mekanik (Opsional)',
                  hint: 'Contoh: Dani',
                  icon: Icons.engineering_outlined,
                  controller: _teks,
                ),
              if (widget.aksi == BookingAksi.selesai) ...[
                AppTextField(
                  label: 'Biaya Akhir',
                  hint: '165000',
                  icon: Icons.payments_outlined,
                  prefixText: 'Rp ',
                  controller: _biaya,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null) return 'Biaya akhir wajib diisi';
                    if (n < 0) return 'Biaya tidak boleh negatif';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                const Text('Catatan Mekanik (Opsional)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _catatan,
                  maxLines: 3,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                      hintText: 'Contoh: Oli SPX2 0.8L, kampas belakang tersisa 30%'),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Setelah ditandai selesai, servis otomatis masuk ke catatan servis pelanggan dan jadwal pengingatnya diperbarui.',
                    style: TextStyle(fontSize: 11, color: AppColors.primary, height: 1.5),
                  ),
                ),
              ],
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
                label: _judul,
                icon: Icons.check_circle_outline,
                loading: _loading,
                onPressed: _submit,
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
