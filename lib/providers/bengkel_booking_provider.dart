import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/booking_repository.dart';
import '../data/models/booking_model.dart';

/// Booking dari sisi bengkel: booking masuk dan aksi terima / tolak / mulai / selesai.
class BengkelBookingProvider extends ChangeNotifier {
  BengkelBookingProvider({this.onChanged});

  /// Dipanggil setelah sebuah aksi berhasil (untuk menyegarkan statistik bengkel).
  final VoidCallback? onChanged;

  final _repo = BookingRepository();

  List<BookingModel> _items = [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<BookingModel> get items => _items;
  bool get loading => _loading;
  bool get loaded => _loaded;
  String? get error => _error;

  List<BookingModel> dengan(String status) => _items.where((b) => b.status == status).toList();

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      _items = await _repo.listWorkshopBookings();
      _loaded = true;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _setelahAksi() async {
    await load(silent: true);
    onChanged?.call();
  }

  Future<void> terima(int id) async {
    await _repo.terima(id);
    await _setelahAksi();
  }

  Future<void> tolak(int id, String alasan) async {
    await _repo.tolak(id, alasan);
    await _setelahAksi();
  }

  Future<void> mulai(int id, String? mekanik) async {
    await _repo.mulai(id, mekanik);
    await _setelahAksi();
  }

  Future<void> selesai(int id, int biayaAkhir, String? catatan) async {
    await _repo.selesai(id, biayaAkhir, catatan);
    await _setelahAksi();
  }

  void clear() {
    _items = [];
    _loaded = false;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
