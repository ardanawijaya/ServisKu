import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/models/service_record_model.dart';
import '../data/service_repository.dart';

class ServiceProvider extends ChangeNotifier {
  final _repo = ServiceRepository();

  List<ServiceRecordModel> _items = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<ServiceRecordModel> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

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
    required int vehicleId,
    required String tanggal,
    required int odometer,
    required List<String> jenisServis,
    required String namaBengkel,
    required int biaya,
    String? catatan,
  }) async {
    await _repo.create(
      vehicleId: vehicleId,
      tanggal: tanggal,
      odometer: odometer,
      jenisServis: jenisServis,
      namaBengkel: namaBengkel,
      biaya: biaya,
      catatan: catatan,
    );
    await load(silent: true);
  }

  Future<void> edit(
    int id, {
    required String tanggal,
    required int odometer,
    required List<String> jenisServis,
    required String namaBengkel,
    required int biaya,
    String? catatan,
  }) async {
    await _repo.update(
      id,
      tanggal: tanggal,
      odometer: odometer,
      jenisServis: jenisServis,
      namaBengkel: namaBengkel,
      biaya: biaya,
      catatan: catatan,
    );
    await load(silent: true);
  }

  Future<void> remove(int id) async {
    await _repo.delete(id);
    await load(silent: true);
  }

  void clear() {
    _items = [];
    _loaded = false;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
