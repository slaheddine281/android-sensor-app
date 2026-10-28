import '../models/user_notification.dart';

final List<UserNotification> initialMockNotifications = [
  UserNotification(
    id: 'notif-001',
    title: 'Compte créé',
    message: "Un nouvel utilisateur s'est inscrit.",
    timestamp: DateTime(2024, 10, 12, 10, 34),
    type: NotificationType.accountCreated,
    isRead: false,
    relatedUserId: 'u372-e56-9411-bc6e0892098e0300',
  ),
  UserNotification(
    id: 'notif-002',
    title: 'Compte suspendu',
    message: 'Le compte de Sara Meftah a été suspendu.',
    timestamp: DateTime(2024, 10, 11, 15, 20),
    type: NotificationType.accountSuspended,
    isRead: false,
    relatedUserId: 'u841-f22-1082-99ca0128472a1102',
  ),
  UserNotification(
    id: 'notif-003',
    title: 'Connexion suspecte',
    message: 'Une tentative de connexion inhabituelle a été détectée.',
    timestamp: DateTime(2024, 10, 10, 9, 12),
    type: NotificationType.securityAlert,
    isRead: true,
  ),
  UserNotification(
    id: 'notif-004',
    title: 'Rôle modifié',
    message: 'Le rôle de Youssef Trabelsi a été mis à jour en Administrateur.',
    timestamp: DateTime(2024, 10, 8, 14, 30),
    type: NotificationType.roleChanged,
    isRead: true,
    relatedUserId: 'a102-c91-4432-88ba339021876543',
  ),
  UserNotification(
    id: 'notif-005',
    title: 'Authentification biométrique activée',
    message: 'Reconnaissance par empreinte et visage configurées avec succès.',
    timestamp: DateTime(2024, 10, 7, 11, 45),
    type: NotificationType.profileUpdated,
    isRead: true,
    relatedUserId: 'u372-e56-9411-bc6e0892098e0300',
  ),
];

