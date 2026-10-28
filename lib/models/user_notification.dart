enum NotificationType {
  accountCreated,
  accountSuspended,
  accountReactivated,
  loginDetected,
  profileUpdated,
  roleChanged,
  accountDeleted,
  securityAlert,
  marketplacePurchase,
  itemEquipped,
  itemUnequipped,
  marketplaceReward,
}

class UserNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final bool isRead;
  final String? relatedUserId;

  const UserNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.isRead = false,
    this.relatedUserId,
  });

  UserNotification copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    NotificationType? type,
    bool? isRead,
    String? relatedUserId,
  }) {
    return UserNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      relatedUserId: relatedUserId ?? this.relatedUserId,
    );
  }
}
