import 'api_client.dart';
import 'models/workshop_model.dart';

class WorkshopRepository {
  final _dio = ApiClient.dio;

  Future<WorkshopModel> getProfile() async {
    try {
      final res = await _dio.get('/workshop/profile');
      return WorkshopModel.fromJson(res.data['data']['workshop'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> updateProfile(Map<String, dynamic> body) async {
    try {
      await _dio.put('/workshop/profile', data: body);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<WorkshopServiceModel>> listServices() async {
    try {
      final res = await _dio.get('/workshop/services');
      return (res.data['data']['services'] as List)
          .map((e) => WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> createService(Map<String, dynamic> body) async {
    try {
      await _dio.post('/workshop/services', data: body);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> updateService(int id, Map<String, dynamic> body) async {
    try {
      await _dio.put('/workshop/services/$id', data: body);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> setAktif(int id, bool aktif) async {
    try {
      await _dio.patch('/workshop/services/$id/aktif', data: {'isActive': aktif});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> deleteService(int id) async {
    try {
      await _dio.delete('/workshop/services/$id');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
