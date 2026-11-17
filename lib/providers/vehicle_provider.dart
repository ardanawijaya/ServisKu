import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/models/vehicle_model.dart';
import '../data/vehicle_repository.dart';

class VehicleProvider extends ChangeNotifier {
  final _repo = VehicleRepository();

  List<VehicleModel> _items = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;
  int? _selectedId;

  List<VehicleModel> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  int countOf(String jenis) =>
      jenis == 'semua' ? _items.length : _items.where((v) => v.jenis == jenis).length;

  /// Kendaraan yang sedang ditampilkan di Home: pilihan terakhir, kalau tidak ada maka yang utama.
  VehicleModel? get selected {
    if (_items.isEmpty) return null;
    for (final v in _items) {
      if (v.id == _selectedId) return v;
    }
    for (final v in _items) {
      if (v.isUtama) return v;
    }
    return _items.first;
  }

  void select(int id) {
    _selectedId = id;
    notifyListeners();
  }

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _items = await _repo.list();
      _loaded = true;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> add({
    required String jenis,
    required String merekTipe,
    required String platNomor,
    required int tahun,
    required int odometer,
  }) async {
    await _repo.create(
      jenis: jenis,
      merekTipe: merekTipe,
      platNomor: platNomor,
      tahun: tahun,
      odometer: odometer,
    );
    await load(silent: true);
  }

  Future<void> edit(
    int id, {
    required String merekTipe,
    required String platNomor,
    required int tahun,
  }) async {
    await _repo.update(id, merekTipe: merekTipe, platNomor: platNomor, tahun: tahun);
    await load(silent: true);
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load(silent: true);
  }

  Future<int> updateOdometer(int id, int km) async {
    final selisih = await _repo.updateOdometer(id, km);
    await load(silent: true);
    return selisih;
  }

  Future<void> setUtama(int id) async {
    await _repo.setUtama(id);
    _selectedId = id;
    await load(silent: true);
  }

  /// Dipanggil saat logout agar data akun sebelumnya tidak terbawa.
  void clear() {
    _items = [];
    _loaded = false;
    _loading = false;
    _error = null;
    _selectedId = null;
    notifyListeners();
  }
}
