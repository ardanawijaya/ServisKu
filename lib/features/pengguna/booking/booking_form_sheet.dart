import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/api_client.dart';
import '../../../data/models/booking_model.dart';
import '../../../data/models/workshop_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_button.dart';

const _hariSingkat = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanSingkat = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];

/// Bottom sheet "Konfirmasi Booking" untuk satu bengkel.
class BookingFormSheet extends StatefulWidget {
  const BookingFormSheet({super.key, required this.bengkel});
  final BengkelModel bengkel;

  static Future<void> show(BuildContext context, BengkelModel bengkel) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: const BoxConstraints(maxWidth: 480),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => BookingFormSheet(bengkel: bengkel),
    );
  }

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _keluhan = TextEditingController();
  late final List<DateTime> _hari;

  List<WorkshopServiceModel> _layanan = [];
  bool _loadingDetail = true;
  String? _detailError;

  int? _vehicleId;
  late DateTime _tanggal;
  AvailabilityModel? _avail;
  bool _loadingSlot = false;
  String? _slotError;
  String? _jam;
  final Set<int> _dipilih = {};

  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    final hariIni = DateTime(n.year, n.month, n.day);
    _hari = List.generate(7, (i) => hariIni.add(Duration(days: i)));
    _tanggal = hariIni;
    _vehicleId = context.read<VehicleProvider>().selected?.id;
    _muatDetail();
    _muatSlot();
  }

  @override
  void dispose() {
    _keluhan.dispose();
    super.dispose();
  }

  String _apiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _muatDetail() async {
    try {
      final d = await context.read<BookingProvider>().detail(widget.bengkel.id);
      if (!mounted) return;
      setState(() {
        _layanan = d.layanan;
        _loadingDetail = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _detailError = e.message;
          _loadingDetail = false;
        });
      }
    }
  }

  Future<void> _muatSlot() async {
    setState(() {
      _loadingSlot = true;
      _slotError = null;
      _jam = null;
    });
    try {
      final a = await context
          .read<BookingProvider>()
          .slots(widget.bengkel.id, _apiDate(_tanggal));
      if (!mounted) return;
      setState(() {
        _avail = a;
        _loadingSlot = false;
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _slotError = e.message;
          _loadingSlot = false;
        });
      }
    }
  }

  int get _totalMin =>
      _layanan.where((l) => _dipilih.contains(l.id)).fold(0, (s, l) => s + l.hargaMin);
  int get _totalMax =>
      _layanan.where((l) => _dipilih.contains(l.id)).fold(0, (s, l) => s + l.hargaMax);

  Future<void> _kirim() async {
    if (_vehicleId == null) {
      setState(() => _error = 'Pilih kendaraan terlebih dahulu');
      return;
    }
    if (_jam == null) {
      setState(() => _error = 'Pilih sesi jam terlebih dahulu');
      return;
    }
    if (_dipilih.isEmpty) {
      setState(() => _error = 'Pilih minimal satu layanan');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final bp = context.read<BookingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await bp.create(
        vehicleId: _vehicleId!,
        workshopId: widget.bengkel.id,
        tanggal: _apiDate(_tanggal),
        jam: _jam!,
        serviceIds: _dipilih.toList(),
        keluhan: _keluhan.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Booking terkirim. Menunggu konfirmasi bengkel.')));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.message);
        _muatSlot(); // ketersediaan bisa berubah
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _labelHari(DateTime d, int i) {
    if (i == 0) return 'Hari Ini';
    if (i == 1) return 'Besok';
    return _hariSingkat[d.weekday - 1];
  }

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
      );

  @override
  Widget build(BuildContext context) {
    final vehicles = context.watch<VehicleProvider>().items;
    final b = widget.bengkel;

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
            const Text('Konfirmasi Booking',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.blueSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.storefront_outlined, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.nama,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 14)),
                        Text([b.alamat, b.kota].whereType<String>().join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _judul('Pilih Kendaraan'),
            if (vehicles.isEmpty)
              const Text('Belum ada kendaraan. Tambahkan di tab Kendaraan terlebih dahulu.',
                  style: TextStyle(color: AppColors.danger, fontSize: 12))
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final v in vehicles) ...[
                      GestureDetector(
                        onTap: () => setState(() => _vehicleId = v.id),
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
                          child: Text('${v.merekTipe} \u2022 ${v.platNomor}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: v.id == _vehicleId
                                      ? Colors.white
                                      : AppColors.muted)),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),

            _judul('Jadwal & Waktu Kedatangan'),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < _hari.length; i++) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _tanggal = _hari[i]);
                        _muatSlot();
                      },
                      child: Container(
                        width: 64,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _hari[i] == _tanggal ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: _hari[i] == _tanggal
                                  ? AppColors.primary
                                  : AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Text(_labelHari(_hari[i], i),
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _hari[i] == _tanggal
                                        ? Colors.white70
                                        : AppColors.muted)),
                            const SizedBox(height: 2),
                            Text('${_hari[i].day} ${_bulanSingkat[_hari[i].month - 1]}',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: _hari[i] == _tanggal
                                        ? Colors.white
                                        : AppColors.text)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            if (_loadingSlot)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_slotError != null)
              Text(_slotError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12))
            else if (_avail != null) ...[
              if (_avail!.tutup)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_avail!.alasan ?? 'Bengkel tutup',
                      style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                )
              else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text('Pilih Sesi Jam',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    ),
                    Text(
                      _avail!.penuh ? 'Kuota penuh' : 'Sisa kuota ${_avail!.kuotaSisa}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _avail!.penuh ? AppColors.danger : const Color(0xFF15803D)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in _avail!.slots)
                      GestureDetector(
                        onTap: s.tersedia ? () => setState(() => _jam = s.jam) : null,
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: _jam == s.jam
                                ? AppColors.primary
                                : (s.tersedia ? Colors.white : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _jam == s.jam ? AppColors.primary : AppColors.border),
                          ),
                          child: Text('${s.jam} WIB',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  decoration:
                                      s.tersedia ? null : TextDecoration.lineThrough,
                                  color: _jam == s.jam
                                      ? Colors.white
                                      : (s.tersedia
                                          ? AppColors.text
                                          : const Color(0xFF94A3B8)))),
                        ),
                      ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 16),

            _judul('Layanan Servis'),
            if (_loadingDetail)
              const Center(child: CircularProgressIndicator(strokeWidth: 2))
            else if (_detailError != null)
              Text(_detailError!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12))
            else
              for (final l in _layanan)
                InkWell(
                  onTap: () => setState(() {
                    _dipilih.contains(l.id) ? _dipilih.remove(l.id) : _dipilih.add(l.id);
                  }),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _dipilih.contains(l.id) ? AppColors.blueSoft : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _dipilih.contains(l.id)
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _dipilih.contains(l.id)
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: _dipilih.contains(l.id)
                              ? AppColors.primary
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.nama,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w700)),
                              Text('~${l.durasiMenit} menit',
                                  style: const TextStyle(
                                      fontSize: 10, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(
                          l.hargaMin == l.hargaMax
                              ? formatRupiah(l.hargaMin)
                              : 'Mulai ${formatRupiah(l.hargaMin)}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),

            _judul('Catatan Tambahan (Opsional)'),
            TextField(
              controller: _keluhan,
              maxLines: 2,
              maxLength: 500,
              decoration: const InputDecoration(
                  hintText: 'Contoh: Ada bunyi mendecit di rem belakang'),
            ),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Total Estimasi Biaya',
                        style: TextStyle(fontSize: 12, color: AppColors.muted)),
                  ),
                  Text(
                    _dipilih.isEmpty
                        ? '-'
                        : (_totalMin == _totalMax
                            ? formatRupiah(_totalMin)
                            : '${formatRupiah(_totalMin)} - ${formatRupiah(_totalMax)}'),
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text('Biaya final dibayar langsung ke bengkel setelah servis selesai.',
                style: TextStyle(fontSize: 10, color: AppColors.muted)),

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
            const SizedBox(height: 14),
            AppButton(
              label: 'Kirim Booking Sekarang',
              icon: Icons.arrow_forward,
              loading: _submitting,
              onPressed: _kirim,
            ),
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _submitting ? null : () => Navigator.of(context).pop(),
                child: const Text('Batal', style: TextStyle(color: AppColors.muted)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
