enum NotificationType {
  accountCreated,
  accountSuspended,
  accountReactivated,
  loginDetected,
  profileUpdated,
  roleChanged,
  accountDeleted,
  securityAlert,
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

  Map<String, dynamic> toMap({bool snakeCase = true}) {
    if (snakeCase) {
      return {
        'id': id,
        'title': title,
        'message': message,
        'created_at': timestamp.toIso8601String(),
        'type': type.name,
        'is_read': isRead,
        'related_user_id': relatedUserId,
      };
    }
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'isRead': isRead,
      'relatedUserId': relatedUserId,
    };
  }

  factory UserNotification.fromMap(Map<String, dynamic> map) {
    NotificationType parsedType = NotificationType.securityAlert;
    final typeStr = (map['type'] ?? '').toString();
    for (final t in NotificationType.values) {
      if (t.name == typeStr) {
        parsedType = t;
        break;
      }
    }

    return UserNotification(
      id: map['id']?.toString() ?? '',
      title: (map['title'] ?? '') as String,
      message: (map['message'] ?? '') as String,
      timestamp: DateTime.tryParse(
              (map['created_at'] ?? map['timestamp'] ?? '').toString()) ??
          DateTime.now(),
      type: parsedType,
      isRead: (map['is_read'] ?? map['isRead']) as bool? ?? false,
      relatedUserId: (map['related_user_id'] ?? map['relatedUserId']) as String?,
    );
  }
}

