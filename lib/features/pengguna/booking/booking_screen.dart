import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/api_client.dart';
import '../../../data/models/booking_model.dart';
import '../../../providers/booking_provider.dart';
import '../../../providers/notification_provider.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/booking_status.dart';
import 'booking_form_sheet.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _tab = 0; // 0 = cari bengkel, 1 = booking saya
  bool _bukaSaja = false;
  final _search = TextEditingController();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bp = context.read<BookingProvider>();
      bp.loadBengkel();
      bp.loadBookings();
    });
    // Segarkan status booking secara berkala (bengkel bisa mengubah status kapan saja)
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<BookingProvider>().loadBookings(silent: true);
      context.read<NotificationProvider>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _batalkan(BookingModel b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text(
            'Booking di ${b.bengkelNama} pada ${formatTanggal(b.tanggal)} pukul ${b.jam} akan dibatalkan.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final bp = context.read<BookingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await bp.cancel(b.id);
      messenger.showSnackBar(const SnackBar(content: Text('Booking dibatalkan')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = context.watch<BookingProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppHeader(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _TabButton(
                      label: 'Cari Bengkel',
                      selected: _tab == 0,
                      onTap: () => setState(() => _tab = 0)),
                  _TabButton(
                      label: bp.bookingAktif > 0
                          ? 'Booking Saya (${bp.bookingAktif})'
                          : 'Booking Saya',
                      selected: _tab == 1,
                      onTap: () => setState(() => _tab = 1)),
                ],
              ),
            ),
          ),
          Expanded(child: _tab == 0 ? _daftarBengkel(bp) : _bookingSaya(bp)),
        ],
      ),
    );
  }

  Widget _daftarBengkel(BookingProvider bp) {
    final q = _search.text.trim().toLowerCase();
    final list = bp.bengkel.where((b) {
      if (_bukaSaja && !b.buka) return false;
      if (q.isEmpty) return true;
      return b.nama.toLowerCase().contains(q) ||
          (b.kota ?? '').toLowerCase().contains(q) ||
          (b.alamat ?? '').toLowerCase().contains(q) ||
          b.kategori.any((k) => k.toLowerCase().contains(q));
    }).toList();

    return RefreshIndicator(
      onRefresh: () => bp.loadBengkel(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Cari nama bengkel, kota, atau layanan',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Chip(
                  label: 'Semua',
                  selected: !_bukaSaja,
                  onTap: () => setState(() => _bukaSaja = false)),
              const SizedBox(width: 8),
              _Chip(
                  label: 'Buka Sekarang',
                  selected: _bukaSaja,
                  onTap: () => setState(() => _bukaSaja = true)),
              const Spacer(),
              Text('${list.length} Bengkel',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 14),
          if (bp.bengkelLoading && !bp.bengkelLoaded)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (bp.bengkelError != null && bp.bengkel.isEmpty)
            _Pesan(
              icon: Icons.cloud_off_outlined,
              teks: bp.bengkelError!,
              aksi: 'Coba Lagi',
              onAksi: () => bp.loadBengkel(),
            )
          else if (list.isEmpty)
            const _Pesan(
              icon: Icons.storefront_outlined,
              teks: 'Belum ada bengkel yang cocok. Bengkel baru muncul setelah menambahkan layanan.',
            )
          else
            for (final b in list) ...[
              _BengkelCard(
                b: b,
                onBooking: () => BookingFormSheet.show(context, b),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }

  Widget _bookingSaya(BookingProvider bp) {
    final list = bp.bookings;
    return RefreshIndicator(
      onRefresh: () => bp.loadBookings(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (bp.bookingLoading && !bp.bookingLoaded)
            const Padding(
              padding: EdgeInsets.only(top: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (bp.bookingError != null && list.isEmpty)
            _Pesan(
              icon: Icons.cloud_off_outlined,
              teks: bp.bookingError!,
              aksi: 'Coba Lagi',
              onAksi: () => bp.loadBookings(),
            )
          else if (list.isEmpty)
            _Pesan(
              icon: Icons.event_note_outlined,
              teks: 'Belum ada booking. Cari bengkel dan buat booking pertamamu.',
              aksi: 'Cari Bengkel',
              onAksi: () => setState(() => _tab = 0),
            )
          else
            for (final b in list) ...[
              _BookingCard(b: b, onBatal: b.bolehBatal ? () => _batalkan(b) : null),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.muted)),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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

class _BengkelCard extends StatelessWidget {
  const _BengkelCard({required this.b, required this.onBooking});
  final BengkelModel b;
  final VoidCallback onBooking;

  @override
  Widget build(BuildContext context) {
    final alamat = [b.alamat, b.kota].whereType<String>().where((s) => s.isNotEmpty).join(', ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
                    color: AppColors.blueSoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.storefront_outlined,
                    size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.nama,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                    if ((b.spesialis ?? '').isNotEmpty)
                      Text(b.spesialis!,
                          style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: b.buka ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(b.buka ? 'Buka' : 'Tutup',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: b.buka ? const Color(0xFF15803D) : AppColors.muted)),
              ),
            ],
          ),
          if (alamat.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(alamat,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time, size: 13, color: AppColors.muted),
              const SizedBox(width: 4),
              Text('${b.jamBuka} - ${b.jamTutup} WIB \u2022 ${b.hariOperasional}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ),
          if (b.kategori.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final k in b.kategori.take(3))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(k,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.muted)),
                  ),
              ],
            ),
          ],
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        b.slotHariIni != null
                            ? 'Slot terdekat hari ini ${b.slotHariIni} WIB'
                            : 'Tidak ada slot tersisa hari ini',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: b.slotHariIni != null
                                ? const Color(0xFF15803D)
                                : AppColors.muted)),
                    const SizedBox(height: 2),
                    Text('Layanan mulai ${formatRupiah(b.hargaMulai)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.muted)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                child: const Text('Booking'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.b, this.onBatal});
  final BookingModel b;
  final VoidCallback? onBatal;

  @override
  Widget build(BuildContext context) {
    final selesai = b.status == 'selesai';
    final biaya = selesai && b.biayaAkhir != null ? b.biayaAkhir! : b.estimasiBiaya;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(b.bengkelNama,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
              ),
              StatusChip(status: b.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 14, color: AppColors.muted),
              const SizedBox(width: 4),
              Text('${formatTanggal(b.tanggal)}, ${b.jam} WIB',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                b.jenisKendaraan == 'motor'
                    ? Icons.two_wheeler_rounded
                    : Icons.directions_car_filled_rounded,
                size: 14,
                color: AppColors.muted,
              ),
              const SizedBox(width: 4),
              Text('${b.merekTipe} \u2022 ${b.platNomor}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(b.namaLayanan,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          if ((b.keluhan ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Catatan: ${b.keluhan}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
          if (b.status == 'ditolak' && (b.alasanPenolakan ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('Alasan: ${b.alasanPenolakan}',
                  style: const TextStyle(fontSize: 11, color: AppColors.danger)),
            ),
          ],
          if (b.status == 'dikerjakan' && (b.mekanik ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Mekanik: ${b.mekanik}',
                style: const TextStyle(fontSize: 11, color: AppColors.muted)),
          ],
          if (selesai) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Servis ini sudah tersimpan otomatis di tab Servis.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF15803D))),
            ),
          ],
          const Divider(height: 22),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(selesai ? 'Biaya Akhir' : 'Estimasi Biaya',
                        style: const TextStyle(fontSize: 10, color: AppColors.muted)),
                    Text(formatRupiah(biaya),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary)),
                  ],
                ),
              ),
              if (onBatal != null)
                OutlinedButton(
                  onPressed: onBatal,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: Color(0xFFFECACA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  child: const Text('Batalkan'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
