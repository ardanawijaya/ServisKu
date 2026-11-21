import 'api_client.dart';
import 'models/booking_model.dart';
import 'models/workshop_model.dart';

class BookingRepository {
  final _dio = ApiClient.dio;

  // ---------- Sisi pengguna ----------
  Future<List<BengkelModel>> listBengkel() async {
    try {
      final res = await _dio.get('/workshops');
      return (res.data['data']['bengkel'] as List)
          .map((e) => BengkelModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<BengkelDetail> bengkelDetail(int id) async {
    try {
      final res = await _dio.get('/workshops/$id');
      final data = res.data['data'] as Map<String, dynamic>;
      return BengkelDetail(
        BengkelModel.fromJson(data['bengkel'] as Map<String, dynamic>),
        (data['layanan'] as List)
            .map((e) => WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<AvailabilityModel> slots(int id, String tanggal) async {
    try {
      final res = await _dio.get('/workshops/$id/slots', queryParameters: {'tanggal': tanggal});
      return AvailabilityModel.fromJson(res.data['data'] as Map<String, dynamic>);
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> create({
    required int vehicleId,
    required int workshopId,
    required String tanggal,
    required String jam,
    required List<int> serviceIds,
    String? keluhan,
  }) async {
    try {
      await _dio.post('/bookings', data: {
        'vehicleId': vehicleId,
        'workshopId': workshopId,
        'tanggal': tanggal,
        'jam': jam,
        'serviceIds': serviceIds,
        'keluhan': keluhan,
      });
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<List<BookingModel>> listBookings() async {
    try {
      final res = await _dio.get('/bookings');
      return (res.data['data']['bookings'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> cancel(int id) async {
    try {
      await _dio.patch('/bookings/$id/cancel');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  // ---------- Sisi bengkel ----------
  Future<List<BookingModel>> listWorkshopBookings() async {
    try {
      final res = await _dio.get('/workshop/bookings');
      return (res.data['data']['bookings'] as List)
          .map((e) => BookingModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> terima(int id) async {
    try {
      await _dio.patch('/workshop/bookings/$id/terima');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> tolak(int id, String alasan) async {
    try {
      await _dio.patch('/workshop/bookings/$id/tolak', data: {'alasan': alasan});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> mulai(int id, String? mekanik) async {
    try {
      await _dio.patch('/workshop/bookings/$id/mulai', data: {'mekanik': mekanik});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> selesai(int id, int biayaAkhir, String? catatan) async {
    try {
      await _dio.patch('/workshop/bookings/$id/selesai',
          data: {'biayaAkhir': biayaAkhir, 'catatan': catatan});
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
