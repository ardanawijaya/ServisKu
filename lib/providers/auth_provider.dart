import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/models/user_model.dart';
import '../data/token_storage.dart';

class AuthProvider extends ChangeNotifier {
  final _repo = AuthRepository();
  UserModel? _user;
  final List<VoidCallback> _logoutListeners = [];

  UserModel? get user => _user;
  bool get isLoggedIn => _user != null;

  /// Daftarkan fungsi yang dipanggil saat logout (mis. membersihkan data provider lain).
  void addLogoutListener(VoidCallback listener) => _logoutListeners.add(listener);

  /// Dipanggil saat splash: cek token tersimpan, validasi ke server.
  Future<void> init() async {
    final token = await TokenStorage.read();
    if (token != null) {
      try {
        _user = await _repo.me();
      } on ApiException catch (e) {
        if (e.statusCode == 401) await TokenStorage.clear();
      }
    }
    notifyListeners();
  }

  Future<void> login({
    required String identifier,
    required String password,
    required String role,
    required bool remember,
  }) async {
    final r = await _repo.login(identifier, password);
    if (r.user.role != role) {
      throw ApiException(
          'Akun ini terdaftar sebagai ${r.user.role}. Kembali dan pilih peran yang sesuai.');
    }
    await TokenStorage.save(r.token, remember: remember);
    _user = r.user;
    notifyListeners();
  }

  Future<void> register(Map<String, dynamic> body) async {
    final r = await _repo.register(body);
    await TokenStorage.save(r.token, remember: true);
    _user = r.user;
    notifyListeners();
  }

  Future<void> updateProfile({
    required String nama,
    required String email,
    required String noHp,
  }) async {
    _user = await _repo.updateProfile({'nama': nama, 'email': email, 'noHp': noHp});
    notifyListeners();
  }

  Future<void> changePassword(String lama, String baru) =>
      _repo.changePassword(lama, baru);

  Future<void> logout() async {
    await TokenStorage.clear();
    _user = null;
    for (final l in _logoutListeners) {
      l();
    }
    notifyListeners();
  }
}
