import 'api_client.dart';
import 'models/notification_model.dart';

class NotificationListResult {
  final List<NotificationModel> items;
  final int unreadCount;
  const NotificationListResult(this.items, this.unreadCount);
}

class NotificationRepository {
  final _dio = ApiClient.dio;

  Future<NotificationListResult> list() async {
    try {
      final res = await _dio.get('/notifications');
      final data = res.data['data'] as Map<String, dynamic>;
      final items = (data['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return NotificationListResult(items, (data['unreadCount'] as num).toInt());
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> markRead(int id) async {
    try {
      await _dio.patch('/notifications/$id/read');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }

  Future<void> markAllRead() async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (e) {
      throw ApiClient.parseError(e);
    }
  }
}
