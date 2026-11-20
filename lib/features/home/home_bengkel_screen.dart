import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/bengkel_header.dart';

class HomeBengkelScreen extends StatelessWidget {
  const HomeBengkelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkshopProvider>();
    final p = wp.profile;

    Widget body;
    if (wp.loading && !wp.loaded) {
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
              FilledButton(onPressed: () => wp.load(), child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    } else {
      final s = p.stats;
      final langkah = <Widget>[];
      if (!p.profilLengkap) {
        langkah.add(_Langkah(
          icon: Icons.storefront_outlined,
          judul: 'Lengkapi profil bengkel',
          deskripsi: 'Isi alamat, jam kerja, dan kontak agar pelanggan mudah menemukan bengkelmu.',
          onTap: () => context.go('/home/bengkel/profil'),
        ));
      }
      if (s.layananAktif == 0) {
        langkah.add(_Langkah(
          icon: Icons.build_outlined,
          judul: 'Tambahkan layanan',
          deskripsi: 'Belum ada layanan aktif. Tambahkan layanan agar pelanggan bisa booking.',
          onTap: () => context.go('/home/bengkel/layanan'),
        ));
      }

      body = RefreshIndicator(
        onRefresh: () => wp.load(silent: true),
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
                      nilai: s.menunggu,
                      ket: 'Order',
                      warna: AppColors.orange),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                      label: 'Dikerjakan',
                      nilai: s.dikerjakan,
                      ket: 'Di Pit',
                      warna: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StatCard(
                      label: 'Selesai',
                      nilai: s.selesai,
                      ket: 'Tuntas',
                      warna: const Color(0xFF16A34A)),
                ),
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 36, color: AppColors.muted),
                  SizedBox(height: 10),
                  Text('Belum ada booking masuk.',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  SizedBox(height: 4),
                  Text(
                    'Booking dari pelanggan akan tampil di sini beserta tombol Terima dan Tolak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
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
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w800)),
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
