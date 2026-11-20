import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/text_utils.dart';
import '../../providers/auth_provider.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/bengkel_header.dart';
import 'bengkel_edit_sheet.dart';

class ProfilBengkelScreen extends StatelessWidget {
  const ProfilBengkelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkshopProvider>();
    final user = context.watch<AuthProvider>().user;
    final p = wp.profile;

    Widget body;
    if (p == null) {
      body = Center(
        child: wp.loading
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(wp.error ?? 'Data bengkel belum tersedia.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () => wp.load(), child: const Text('Coba Lagi')),
                  ],
                ),
              ),
      );
    } else {
      final kategori = wp.services.map((s) => s.kategori).toSet().toList();
      final nomor = (p.noWhatsapp ?? '').isEmpty ? '-' : '+${p.noWhatsapp}';

      body = ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(inisialNama(p.nama),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nama,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w800)),
                          if ((p.spesialis ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(p.spesialis!,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.muted)),
                          ],
                          const SizedBox(height: 6),
                          if ((p.kota ?? '').isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.orangeSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.place,
                                      size: 12, color: AppColors.orange),
                                  const SizedBox(width: 4),
                                  Text(p.kota!,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9A3412))),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () => BengkelEditSheet.show(context, p),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Edit Profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      textStyle: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _Stat(label: 'Total Servis', nilai: '${p.stats.selesai}',
                      ket: 'Selesai')),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(label: 'Antrean', nilai: '${p.stats.antrean}',
                      ket: 'Aktif')),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      label: 'Operasional',
                      nilai: p.buka ? 'Buka' : 'Tutup',
                      ket: 's/d ${p.jamTutup} WIB',
                      warna: p.buka ? const Color(0xFF15803D) : AppColors.muted)),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Informasi Bengkel',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text('Detail yang tampil ke pelanggan',
              style: TextStyle(fontSize: 11, color: AppColors.muted)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _Info(
                  icon: Icons.place_outlined,
                  label: 'Alamat Lengkap',
                  nilai: p.profilLengkap ? p.alamat! : 'Belum diisi',
                  redup: !p.profilLengkap,
                ),
                const Divider(height: 22),
                _Info(icon: Icons.phone_outlined, label: 'Kontak WhatsApp', nilai: nomor),
                const Divider(height: 22),
                _Info(
                  icon: Icons.access_time,
                  label: 'Jam Kerja Bengkel',
                  nilai: '${p.jamBuka} - ${p.jamTutup} WIB\n${p.hariOperasional}',
                ),
                const Divider(height: 22),
                _Info(
                  icon: Icons.event_seat_outlined,
                  label: 'Kuota Booking Harian',
                  nilai: '${p.kuotaHarian} booking',
                ),
                const Divider(height: 22),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.work_outline, size: 20, color: AppColors.muted),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Lingkup Layanan',
                              style: TextStyle(fontSize: 11, color: AppColors.muted)),
                          const SizedBox(height: 6),
                          if (kategori.isEmpty)
                            const Text('Belum ada layanan',
                                style: TextStyle(fontSize: 13, color: AppColors.muted))
                          else
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: [
                                for (final k in kategori)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.blueSoft,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(k,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary)),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (user != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: _Info(
                icon: Icons.person_outline,
                label: 'Akun Pemilik',
                nilai: '${user.nama}\n${user.email}',
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                final wpc = context.read<WorkshopProvider>();
                await context.read<AuthProvider>().logout();
                wpc.clear();
                if (context.mounted) context.go('/onboarding');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: const BorderSide(color: Color(0xFFFECACA)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BengkelHeader(),
      body: body,
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.nilai, required this.ket, this.warna});
  final String label;
  final String nilai;
  final String ket;
  final Color? warna;

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
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(nilai,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: warna ?? AppColors.text)),
          Text(ket, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({
    required this.icon,
    required this.label,
    required this.nilai,
    this.redup = false,
  });
  final IconData icon;
  final String label;
  final String nilai;
  final bool redup;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.muted),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(nilai,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                      color: redup ? AppColors.muted : AppColors.text)),
            ],
          ),
        ),
      ],
    );
  }
}
