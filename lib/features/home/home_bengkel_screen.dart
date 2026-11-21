import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/api_client.dart';
import '../../data/models/booking_model.dart';
import '../../providers/bengkel_booking_provider.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/bengkel_header.dart';
import '../../widgets/booking_status.dart';
import '../bengkel/booking_action_sheet.dart';

class HomeBengkelScreen extends StatefulWidget {
  const HomeBengkelScreen({super.key});

  @override
  State<HomeBengkelScreen> createState() => _HomeBengkelScreenState();
}

class _HomeBengkelScreenState extends State<HomeBengkelScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BengkelBookingProvider>().load();
    });
    // Cek booking masuk baru secara berkala
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      context.read<BengkelBookingProvider>().load(silent: true);
      context.read<WorkshopProvider>().load(silent: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _terima(BookingModel b) async {
    final p = context.read<BengkelBookingProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await p.terima(b.id);
      messenger.showSnackBar(const SnackBar(content: Text('Booking diterima')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      context.read<BengkelBookingProvider>().load(silent: true),
      context.read<WorkshopProvider>().load(silent: true),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkshopProvider>();
    final bp = context.watch<BengkelBookingProvider>();
    final p = wp.profile;

    Widget body;
    if ((wp.loading && !wp.loaded) || (bp.loading && !bp.loaded)) {
      body = const Center(child: CircularProgressIndicator());
    } else if (p == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 48, color: AppColors.muted),
              const SizedBox(height: 12),
              Text(wp.error ?? 'Data bengkel belum tersedia.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 16),
              FilledButton(
                  onPressed: () {
                    wp.load();
                    bp.load();
                  },
                  child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    } else {
      final menunggu = bp.dengan('menunggu');
      final dikonfirmasi = bp.dengan('dikonfirmasi');
      final dikerjakan = bp.dengan('dikerjakan');
      final riwayat = bp.items
          .where((b) => b.status == 'selesai' || b.status == 'ditolak' || b.status == 'dibatalkan')
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final selesaiJml = bp.dengan('selesai').length;

      final langkah = <Widget>[];
      if (!p.profilLengkap) {
        langkah.add(_Langkah(
          icon: Icons.storefront_outlined,
          judul: 'Lengkapi profil bengkel',
          deskripsi: 'Isi alamat, jam kerja, dan kontak agar pelanggan mudah menemukan bengkelmu.',
          onTap: () => context.go('/home/bengkel/profil'),
        ));
      }
      if (p.stats.layananAktif == 0) {
        langkah.add(_Langkah(
          icon: Icons.build_outlined,
          judul: 'Tambahkan layanan',
          deskripsi: 'Belum ada layanan aktif. Pelanggan baru bisa booking setelah ada layanan.',
          onTap: () => context.go('/home/bengkel/layanan'),
        ));
      }

      body = RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(p.nama,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(p.buka ? 'Sedang buka' : 'Sedang tutup',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.buka ? const Color(0xFF15803D) : AppColors.muted)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Menunggu',
                        nilai: menunggu.length,
                        ket: 'Order',
                        warna: AppColors.orange)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        label: 'Dikerjakan',
                        nilai: dikerjakan.length,
                        ket: 'Di Pit',
                        warna: AppColors.primary)),
                const SizedBox(width: 10),
                Expanded(
                    child: _StatCard(
                        label: 'Selesai',
                        nilai: selesaiJml,
                        ket: 'Tuntas',
                        warna: const Color(0xFF16A34A))),
              ],
            ),
            const SizedBox(height: 16),
            if (langkah.isNotEmpty) ...[
              const Text('Langkah Awal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              ...langkah,
              const SizedBox(height: 6),
            ],
            if (bp.error != null && bp.items.isEmpty)
              _Kosong(icon: Icons.cloud_off_outlined, judul: 'Gagal memuat booking', teks: bp.error!)
            else if (menunggu.isEmpty && dikonfirmasi.isEmpty && dikerjakan.isEmpty)
              const _Kosong(
                icon: Icons.inbox_outlined,
                judul: 'Belum ada booking aktif.',
                teks: 'Booking dari pelanggan akan tampil di sini beserta tombol Terima dan Tolak.',
              ),
            ..._seksi('Menunggu Konfirmasi', menunggu, (b) => _BookingCard(
                  b: b,
                  aksiKiri: _Aksi('Tolak', danger: true,
                      onTap: () => BookingActionSheet.show(context, b, BookingAksi.tolak)),
                  aksiKanan: _Aksi('Terima Booking', onTap: () => _terima(b)),
                )),
            ..._seksi('Dikonfirmasi', dikonfirmasi, (b) => _BookingCard(
                  b: b,
                  aksiKanan: _Aksi('Mulai Dikerjakan',
                      onTap: () => BookingActionSheet.show(context, b, BookingAksi.mulai)),
                )),
            ..._seksi('Sedang Dikerjakan', dikerjakan, (b) => _BookingCard(
                  b: b,
                  aksiKanan: _Aksi('Tandai Selesai',
                      onTap: () => BookingActionSheet.show(context, b, BookingAksi.selesai)),
                )),
            if (riwayat.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Text('Riwayat Terbaru',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 10),
              for (final b in riwayat.take(5)) _RiwayatRow(b: b),
            ],
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BengkelHeader(),
      body: body,
    );
  }

  List<Widget> _seksi(String judul, List<BookingModel> data, Widget Function(BookingModel) bangun) {
    if (data.isEmpty) return const [];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Row(
          children: [
            Text(judul,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                  color: AppColors.blueSoft, borderRadius: BorderRadius.circular(10)),
              child: Text('${data.length}',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary)),
            ),
          ],
        ),
      ),
      for (final b in data) ...[bangun(b), const SizedBox(height: 12)],
    ];
  }
}

class _Aksi {
  const _Aksi(this.label, {required this.onTap, this.danger = false});
  final String label;
  final VoidCallback onTap;
  final bool danger;
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.b, this.aksiKiri, this.aksiKanan});
  final BookingModel b;
  final _Aksi? aksiKiri;
  final _Aksi? aksiKanan;

  @override
  Widget build(BuildContext context) {
    final s = gayaBooking(b.status);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: s.fg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StatusChip(status: b.status),
                        const Spacer(),
                        const Icon(Icons.event_outlined,
                            size: 13, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text('${formatTanggal(b.tanggal)}, ${b.jam}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: AppColors.blueSoft,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            b.pelangganNama.isEmpty
                                ? '?'
                                : b.pelangganNama[0].toUpperCase(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(b.pelangganNama,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800)),
                              Text('${b.merekTipe} \u2022 ${b.platNomor}',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('LAYANAN DIMINTA',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.muted)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final l in b.layanan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.blueSoft,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(l.nama,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                      ],
                    ),
                    if ((b.keluhan ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.bg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('"${b.keluhan}"',
                            style: const TextStyle(
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                                color: AppColors.muted)),
                      ),
                    ],
                    if ((b.mekanik ?? '').isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Mekanik: ${b.mekanik}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.muted)),
                    ],
                    const Divider(height: 22),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Estimasi Biaya',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                        ),
                        Text(formatRupiah(b.estimasiBiaya),
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w800)),
                      ],
                    ),
                    if (aksiKiri != null || aksiKanan != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (aksiKiri != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                onPressed: aksiKiri!.onTap,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.danger,
                                  side:
                                      const BorderSide(color: AppColors.danger),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                                child: Text(aksiKiri!.label),
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                          if (aksiKanan != null)
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                onPressed: aksiKanan!.onTap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w800),
                                ),
                                child: Text(aksiKanan!.label),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiwayatRow extends StatelessWidget {
  const _RiwayatRow({required this.b});
  final BookingModel b;

  @override
  Widget build(BuildContext context) {
    final biaya = b.status == 'selesai' && b.biayaAkhir != null
        ? formatRupiah(b.biayaAkhir!)
        : null;
    final tambahan = biaya != null ? ' \u2022 $biaya' : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${b.pelangganNama} \u2022 ${b.merekTipe}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                Text('${formatTanggal(b.tanggal)}, ${b.jam}$tambahan',
                    style: const TextStyle(fontSize: 10, color: AppColors.muted)),
              ],
            ),
          ),
          StatusChip(status: b.status),
        ],
      ),
    );
  }
}

class _Kosong extends StatelessWidget {
  const _Kosong({required this.icon, required this.judul, required this.teks});
  final IconData icon;
  final String judul;
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
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
          Text(judul, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(teks,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.nilai,
    required this.ket,
    required this.warna,
  });
  final String label;
  final int nilai;
  final String ket;
  final Color warna;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              ),
              Icon(Icons.circle, size: 8, color: warna),
            ],
          ),
          const SizedBox(height: 6),
          Text('$nilai',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Text(ket,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: warna)),
        ],
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  const _Langkah({
    required this.icon,
    required this.judul,
    required this.deskripsi,
    required this.onTap,
  });
  final IconData icon;
  final String judul;
  final String deskripsi;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.orangeSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration:
                    const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: AppColors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(judul,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(deskripsi,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF9A3412), height: 1.4)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.orange),
            ],
          ),
        ),
      ),
    );
  }
}
