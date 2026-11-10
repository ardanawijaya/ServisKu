import 'api_client.dart';
import 'models/user_model.dart';

class AuthResult {
  final String token;
  final UserModel user;
  AuthResult(this.token, this.user);

  factory AuthResult.fromJson(Map<String, dynamic> j) => AuthResult(
        j['token'] as String,
        UserModel.fromJson(j['user'] as Map<String, dynamic>),
      );
}

class AuthRepository {
  final _dio = ApiClient.dio;

  Future<AuthResult> login(String identifier, String password) async {
    try {
      final res = await _dio.post('/auth/login',
          data: {'identifier': identifier, 'password': password});
      return AuthResult.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<AuthResult> register(Map<String, dynamic> body) async {
    try {
      final res = await _dio.post('/auth/register', data: body);
      return AuthResult.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<UserModel> me() async {
    try {
      final res = await _dio.get('/auth/me');
      return UserModel.fromJson(
          res.data['data']['user'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
