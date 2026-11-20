import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/formatters.dart';
import '../../../data/api_client.dart';
import '../../../data/models/vehicle_model.dart';
import '../../../providers/vehicle_provider.dart';
import '../../../widgets/app_header.dart';
import '../../../widgets/pengingat_widgets.dart';
import 'odometer_sheet.dart';
import 'vehicle_form_sheet.dart';

class KendaraanScreen extends StatefulWidget {
  const KendaraanScreen({super.key});

  @override
  State<KendaraanScreen> createState() => _KendaraanScreenState();
}

class _KendaraanScreenState extends State<KendaraanScreen> {
  String _filter = 'semua';
  bool _searching = false;
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<VehicleModel> _filtered(List<VehicleModel> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((v) {
      if (_filter != 'semua' && v.jenis != _filter) return false;
      if (q.isEmpty) return true;
      return v.merekTipe.toLowerCase().contains(q) ||
          v.platNomor.toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(VehicleModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus kendaraan?'),
        content: Text(
            '${v.merekTipe} (${v.platNomor}) beserta seluruh catatan servis dan booking terkait akan dihapus.'),
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
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vp.remove(v.id);
      messenger.showSnackBar(const SnackBar(content: Text('Kendaraan dihapus')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _setUtama(VehicleModel v) async {
    final vp = context.read<VehicleProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await vp.setUtama(v.id);
      messenger.showSnackBar(
          SnackBar(content: Text('${v.merekTipe} dijadikan kendaraan utama')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vp = context.watch<VehicleProvider>();
    final list = _filtered(vp.items);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: const AppHeader(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => VehicleFormSheet.show(context),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kendaraan',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: () => vp.load(silent: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Kendaraan Saya',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text('${vp.items.length} Kendaraan Terdaftar',
                          style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {
                    _searching = !_searching;
                    if (!_searching) _search.clear();
                  }),
                  icon: Icon(_searching ? Icons.close : Icons.search),
                  style: IconButton.styleFrom(backgroundColor: Colors.white),
                ),
              ],
            ),
            if (_searching) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _search,
                autofocus: true,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari merek, tipe, atau plat nomor',
                  prefixIcon: Icon(Icons.search, size: 20),
                ),
              ),
            ],
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Semua (${vp.countOf('semua')})',
                    selected: _filter == 'semua',
                    onTap: () => setState(() => _filter = 'semua'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Motor (${vp.countOf('motor')})',
                    selected: _filter == 'motor',
                    onTap: () => setState(() => _filter = 'motor'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Mobil (${vp.countOf('mobil')})',
                    selected: _filter == 'mobil',
                    onTap: () => setState(() => _filter = 'mobil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (vp.loading && !vp.loaded)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (vp.error != null && vp.items.isEmpty)
              _MessageCard(
                icon: Icons.cloud_off_outlined,
                text: vp.error!,
                actionLabel: 'Coba Lagi',
                onAction: () => vp.load(),
              )
            else if (list.isEmpty)
              _MessageCard(
                icon: Icons.two_wheeler_outlined,
                text: vp.items.isEmpty
                    ? 'Belum ada kendaraan. Tambahkan kendaraan pertamamu.'
                    : 'Tidak ada kendaraan yang cocok.',
                actionLabel: vp.items.isEmpty ? 'Tambah Kendaraan' : null,
                onAction: vp.items.isEmpty ? () => VehicleFormSheet.show(context) : null,
              )
            else
              for (final v in list) ...[
                _VehicleCard(
                  vehicle: v,
                  onEdit: () => VehicleFormSheet.show(context, vehicle: v),
                  onDelete: () => _confirmDelete(v),
                  onUpdateKm: () => OdometerSheet.show(context, v),
                  onSetUtama: () => _setUtama(v),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
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

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

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
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
          if (actionLabel != null) ...[
            const SizedBox(height: 12),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateKm,
    required this.onSetUtama,
  });

  final VehicleModel vehicle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateKm;
  final VoidCallback onSetUtama;

  @override
  Widget build(BuildContext context) {
    final v = vehicle;
    final p = v.pengingat;
    final accent = v.isMotor ? AppColors.primary : AppColors.orange;
    final soft = v.isMotor ? AppColors.blueSoft : AppColors.orangeSoft;

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
                decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
                child: Icon(
                  v.isMotor ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded,
                  color: accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(v.merekTipe,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                        ),
                        if (v.isUtama) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Utama',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(v.platNomor,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                        if (p != null) KondisiBadge(pengingat: p),
                      ],
                    ),
                  ],
                ),
              ),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _Info(
                    label: 'Tahun & Odometer',
                    value: '${v.tahun} \u2022 ${formatKm(v.odometerTerakhir)} km',
                  ),
                ),
                Expanded(
                  child: _Info(
                    label: 'Servis Terakhir',
                    value: v.servisTerakhir == null
                        ? 'Belum ada'
                        : formatTanggal(v.servisTerakhir!),
                  ),
                ),
              ],
            ),
          ),
          if (p != null) ...[
            const SizedBox(height: 12),
            SiklusBar(pengingat: p),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onUpdateKm,
                icon: const Icon(Icons.speed_outlined, size: 16),
                label: const Text('Update KM'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
              const Spacer(),
              if (!v.isUtama)
                TextButton.icon(
                  onPressed: onSetUtama,
                  icon: const Icon(Icons.star_outline_rounded, size: 16),
                  label: const Text('Jadikan Utama'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.muted,
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
