import 'package:flutter/foundation.dart';
import '../data/api_client.dart';
import '../data/models/notification_model.dart';
import '../data/notification_repository.dart';

class NotificationProvider extends ChangeNotifier {
  final _repo = NotificationRepository();

  List<NotificationModel> _items = [];
  int _unreadCount = 0;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  List<NotificationModel> get items => _items;
  int get unreadCount => _unreadCount;
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
      final r = await _repo.list();
      _items = r.items;
      _unreadCount = r.unreadCount;
      _loaded = true;
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    final i = _items.indexWhere((n) => n.id == id);
    if (i < 0 || _items[i].isRead) return;
    // Perbarui tampilan lebih dulu, lalu sinkron ke server
    _items[i] = _items[i].copyWith(isRead: true);
    _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
    notifyListeners();
    try {
      await _repo.markRead(id);
    } on ApiException {
      await load(silent: true);
    }
  }

  Future<void> markAllRead() async {
    if (_unreadCount == 0) return;
    _items = _items.map((n) => n.copyWith(isRead: true)).toList();
    _unreadCount = 0;
    notifyListeners();
    try {
      await _repo.markAllRead();
    } on ApiException {
      await load(silent: true);
    }
  }

  void clear() {
    _items = [];
    _unreadCount = 0;
    _loaded = false;
    _loading = false;
    _error = null;
    notifyListeners();
  }
}
