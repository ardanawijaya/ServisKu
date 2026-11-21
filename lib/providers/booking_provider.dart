import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/booking_repository.dart';
import '../data/models/booking_model.dart';

/// Booking dari sisi pengguna: daftar bengkel + riwayat booking.
class BookingProvider extends ChangeNotifier {
  final _repo = BookingRepository();

  List<BengkelModel> _bengkel = [];
  bool _bengkelLoading = false;
  bool _bengkelLoaded = false;
  String? _bengkelError;

  List<BookingModel> _bookings = [];
  bool _bookingLoading = false;
  bool _bookingLoaded = false;
  String? _bookingError;

  List<BengkelModel> get bengkel => _bengkel;
  bool get bengkelLoading => _bengkelLoading;
  bool get bengkelLoaded => _bengkelLoaded;
  String? get bengkelError => _bengkelError;

  List<BookingModel> get bookings => _bookings;
  bool get bookingLoading => _bookingLoading;
  bool get bookingLoaded => _bookingLoaded;
  String? get bookingError => _bookingError;

  int get bookingAktif => _bookings
      .where((b) => b.status == 'menunggu' || b.status == 'dikonfirmasi' || b.status == 'dikerjakan')
      .length;

  Future<void> loadBengkel({bool silent = false}) async {
    if (!silent) {
      _bengkelLoading = true;
      _bengkelError = null;
      notifyListeners();
    }
    try {
      _bengkel = await _repo.listBengkel();
      _bengkelLoaded = true;
      _bengkelError = null;
    } on ApiException catch (e) {
      _bengkelError = e.message;
    }
    _bengkelLoading = false;
    notifyListeners();
  }

  Future<void> loadBookings({bool silent = false}) async {
    if (!silent) {
      _bookingLoading = true;
      _bookingError = null;
      notifyListeners();
    }
    try {
      _bookings = await _repo.listBookings();
      _bookingLoaded = true;
      _bookingError = null;
    } on ApiException catch (e) {
      _bookingError = e.message;
    }
    _bookingLoading = false;
    notifyListeners();
  }

  Future<BengkelDetail> detail(int id) => _repo.bengkelDetail(id);

  Future<AvailabilityModel> slots(int id, String tanggal) => _repo.slots(id, tanggal);

  Future<void> create({
    required int vehicleId,
    required int workshopId,
    required String tanggal,
    required String jam,
    required List<int> serviceIds,
    String? keluhan,
  }) async {
    await _repo.create(
      vehicleId: vehicleId,
      workshopId: workshopId,
      tanggal: tanggal,
      jam: jam,
      serviceIds: serviceIds,
      keluhan: keluhan,
    );
    await loadBookings(silent: true);
    await loadBengkel(silent: true);
  }

  Future<void> cancel(int id) async {
    await _repo.cancel(id);
    await loadBookings(silent: true);
    await loadBengkel(silent: true);
  }

  void clear() {
    _bengkel = [];
    _bengkelLoaded = false;
    _bengkelLoading = false;
    _bengkelError = null;
    _bookings = [];
    _bookingLoaded = false;
    _bookingLoading = false;
    _bookingError = null;
    notifyListeners();
  }
}
