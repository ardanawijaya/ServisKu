import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/formatters.dart';
import '../../data/api_client.dart';
import '../../data/models/workshop_model.dart';
import '../../providers/workshop_provider.dart';
import '../../widgets/bengkel_header.dart';
import 'layanan_form_sheet.dart';

class LayananScreen extends StatelessWidget {
  const LayananScreen({super.key});

  Future<void> _toggle(BuildContext context, WorkshopServiceModel s, bool aktif) async {
    final wp = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await wp.setAktif(s.id, aktif);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _hapus(BuildContext context, WorkshopServiceModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text('"${s.nama}" akan dihapus dari daftar layanan.'),
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
    if (ok != true || !context.mounted) return;
    final wp = context.read<WorkshopProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await wp.removeService(s.id);
      messenger.showSnackBar(const SnackBar(content: Text('Layanan dihapus')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = context.watch<WorkshopProvider>();
    final list = wp.services;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const BengkelHeader(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => LayananFormSheet.show(context),
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Layanan', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => wp.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Layanan Bengkel',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${list.length} Layanan',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (wp.loading && !wp.loaded)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (wp.error != null && list.isEmpty)
              _Pesan(
                icon: Icons.cloud_off_outlined,
                teks: wp.error!,
                aksi: 'Coba Lagi',
                onAksi: () => wp.load(),
              )
            else if (list.isEmpty)
              _Pesan(
                icon: Icons.build_outlined,
                teks: 'Belum ada layanan. Tambahkan layanan pertamamu.',
                aksi: 'Tambah Layanan',
                onAksi: () => LayananFormSheet.show(context),
              )
            else
              for (final s in list) ...[
                _LayananCard(
                  s: s,
                  onEdit: () => LayananFormSheet.show(context, service: s),
                  onDelete: () => _hapus(context, s),
                  onToggle: (v) => _toggle(context, s, v),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
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

class _LayananCard extends StatelessWidget {
  const _LayananCard({
    required this.s,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final WorkshopServiceModel s;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final harga = s.hargaMin == s.hargaMax
        ? formatRupiah(s.hargaMin)
        : '${formatRupiah(s.hargaMin)} - ${formatRupiah(s.hargaMax)}';

    return Opacity(
      opacity: s.isActive ? 1 : 0.6,
      child: Container(
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(s.kategori,
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary)),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(backgroundColor: AppColors.blueSoft),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: AppColors.danger,
                  style: IconButton.styleFrom(backgroundColor: const Color(0xFFFEF2F2)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(s.nama,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text('~${s.durasiMenit} Menit',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              ],
            ),
            if ((s.deskripsi ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(s.deskripsi!,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Estimasi Biaya',
                          style: TextStyle(fontSize: 10, color: AppColors.muted)),
                      const SizedBox(height: 2),
                      Text(harga,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                Text(s.isActive ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: s.isActive ? AppColors.primary : AppColors.muted)),
                const SizedBox(width: 6),
                Switch(value: s.isActive, onChanged: onToggle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
