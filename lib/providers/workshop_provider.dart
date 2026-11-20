import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/models/workshop_model.dart';
import '../data/workshop_repository.dart';

class WorkshopProvider extends ChangeNotifier {
  final _repo = WorkshopRepository();

  WorkshopModel? _profile;
  List<WorkshopServiceModel> _services = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  WorkshopModel? get profile => _profile;
  List<WorkshopServiceModel> get services => _services;
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
      final r = await Future.wait([_repo.getProfile(), _repo.listServices()]);
      _profile = r[0] as WorkshopModel;
      _services = r[1] as List<WorkshopServiceModel>;
      _loaded = true;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    await _repo.updateProfile(body);
    await load(silent: true);
  }

  Future<void> addService(Map<String, dynamic> body) async {
    await _repo.createService(body);
    await load(silent: true);
  }

  Future<void> editService(int id, Map<String, dynamic> body) async {
    await _repo.updateService(id, body);
    await load(silent: true);
  }

  Future<void> setAktif(int id, bool aktif) async {
    await _repo.setAktif(id, aktif);
    await load(silent: true);
  }

  Future<void> removeService(int id) async {
    await _repo.deleteService(id);
    await load(silent: true);
  }

  void clear() {
    _profile = null;
    _services = [];
    _loaded = false;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
