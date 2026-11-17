import 'api_client.dart';
import 'models/vehicle_model.dart';

class VehicleRepository {
  final _dio = ApiClient.dio;

  Future<List<VehicleModel>> list() async {
    try {
      final res = await _dio.get('/vehicles');
      final raw = res.data['data']['vehicles'] as List;
      return raw
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> create({
    required String jenis,
    required String merekTipe,
    required String platNomor,
    required int tahun,
    required int odometer,
  }) async {
    try {
      await _dio.post('/vehicles', data: {
        'jenis': jenis,
        'merekTipe': merekTipe,
        'platNomor': platNomor,
        'tahun': tahun,
        'odometer': odometer,
      });
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> update(
    int id, {
    required String merekTipe,
    required String platNomor,
    required int tahun,
  }) async {
    try {
      await _dio.put('/vehicles/$id', data: {
        'merekTipe': merekTipe,
        'platNomor': platNomor,
        'tahun': tahun,
      });
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete('/vehicles/$id');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  /// Mengembalikan selisih km dari odometer sebelumnya.
  Future<int> updateOdometer(int id, int km) async {
    try {
      final res = await _dio.patch('/vehicles/$id/odometer', data: {'km': km});
      return res.data['data']['selisihKm'] as int;
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> setUtama(int id) async {
    try {
      await _dio.patch('/vehicles/$id/utama');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
