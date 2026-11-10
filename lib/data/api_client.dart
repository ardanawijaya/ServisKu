import 'package:dio/dio.dart';
import '../core/constants.dart';
import 'token_storage.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();

  static final Dio dio = _create();

  static Dio _create() {
    final d = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    // Otomatis menempelkan JWT ke setiap request
    d.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) async {
      final token = await TokenStorage.read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    }));
    return d;
  }

  static ApiException parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        var msg = data['message'].toString();
        final errors = data['errors'];
        if (errors is List && errors.isNotEmpty) {
          msg = errors.map((x) => x['message']).join('\n');
        }
        return ApiException(msg, e.response?.statusCode);
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return ApiException(
            'Tidak dapat terhubung ke server. Pastikan backend sedang berjalan.');
      }
    }
    return ApiException('Terjadi kesalahan. Coba lagi.');
  }
}
