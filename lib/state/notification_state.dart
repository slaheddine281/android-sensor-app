import 'package:flutter/foundation.dart';
import '../models/user_notification.dart';
import '../data/mock_notifications.dart';

class NotificationState extends ChangeNotifier {
  final List<UserNotification> _notifications =
      List<UserNotification>.from(initialMockNotifications);

  List<UserNotification> get notifications => List.unmodifiable(_notifications);

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    String? relatedUserId,
  }) {
    final notif = UserNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      isRead: false,
      relatedUserId: relatedUserId,
    );
    _notifications.insert(0, notif);
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  void markAllAsRead() {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearAll() {
    _notifications.clear();
    notifyListeners();
  }
}

