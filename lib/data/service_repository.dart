import 'api_client.dart';
import 'models/service_record_model.dart';

class ServiceRepository {
  final _dio = ApiClient.dio;

  Future<List<ServiceRecordModel>> list() async {
    try {
      final res = await _dio.get('/services');
      final raw = res.data['data']['records'] as List;
      return raw
          .map((e) => ServiceRecordModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> create({
    required int vehicleId,
    required String tanggal, // YYYY-MM-DD
    required int odometer,
    required List<String> jenisServis,
    required String namaBengkel,
    required int biaya,
    String? catatan,
  }) async {
    try {
      await _dio.post('/services', data: {
        'vehicleId': vehicleId,
        'tanggal': tanggal,
        'odometer': odometer,
        'jenisServis': jenisServis,
        'namaBengkel': namaBengkel,
        'biaya': biaya,
        'catatan': catatan,
      });
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> update(
    int id, {
    required String tanggal,
    required int odometer,
    required List<String> jenisServis,
    required String namaBengkel,
    required int biaya,
    String? catatan,
  }) async {
    try {
      await _dio.put('/services/$id', data: {
        'tanggal': tanggal,
        'odometer': odometer,
        'jenisServis': jenisServis,
        'namaBengkel': namaBengkel,
        'biaya': biaya,
        'catatan': catatan,
      });
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/services/$id');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
