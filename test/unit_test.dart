import 'package:flutter_test/flutter_test.dart';
import 'package:stepquest/models/app_user.dart';
import 'package:stepquest/state/auth_state.dart';
import 'package:stepquest/state/notification_state.dart';
import 'package:stepquest/state/user_state.dart';

final List<AppUser> _testUsers = [
  AppUser(
    id: 'u1',
    fullName: 'Amine Ben Ali',
    email: 'amine@example.com',
    role: UserRole.user,
    status: UserStatus.active,
    createdAt: DateTime(2024, 10, 12),
  ),
  AppUser(
    id: 'u2',
    fullName: 'Sara Meftah',
    email: 'sara@example.com',
    role: UserRole.user,
    status: UserStatus.active,
    createdAt: DateTime(2024, 9, 28),
  ),
  AppUser(
    id: 'u3',
    fullName: 'Lina Khaled',
    email: 'lina@example.com',
    role: UserRole.user,
    status: UserStatus.suspended,
    createdAt: DateTime(2024, 7, 20),
  ),
  AppUser(
    id: 'u4',
    fullName: 'Omar Saidi',
    email: 'omar@example.com',
    role: UserRole.user,
    status: UserStatus.active,
    createdAt: DateTime(2024, 10, 5),
  ),
  AppUser(
    id: 'u5',
    fullName: 'Youssef Trabelsi',
    email: 'youssef@stepquest.com',
    role: UserRole.admin,
    status: UserStatus.active,
    createdAt: DateTime(2024, 8, 15),
  ),
  AppUser(
    id: 'u6',
    fullName: 'Admin Principal',
    email: 'admin@stepquest.com',
    role: UserRole.admin,
    status: UserStatus.active,
    createdAt: DateTime(2024, 1, 1),
  ),
];

void main() {
  group('StepQuest User Management & CRUD Tests', () {
    late UserState userState;

    setUp(() {
      userState = UserState(initialUsers: _testUsers);
    });

    test('Initial mock users are properly populated', () {
      expect(userState.allUsers.isNotEmpty, true);
      expect(userState.totalUsersCount, greaterThanOrEqualTo(5));
      expect(userState.activeUsersCount, greaterThan(0));
      expect(userState.suspendedUsersCount, greaterThan(0));
      expect(userState.adminUsersCount, greaterThan(0));
    });

    test('Filter users by status and query', () {
      final activeUsers =
          userState.filter(statusFilter: UserStatus.active);
      expect(
          activeUsers.every((u) => u.status == UserStatus.active), true);

      final suspendedUsers =
          userState.filter(statusFilter: UserStatus.suspended);
      expect(
          suspendedUsers.every((u) => u.status == UserStatus.suspended), true);

      final searchAmine = userState.filter(query: 'amine');
      expect(searchAmine.isNotEmpty, true);
      expect(searchAmine.first.fullName, contains('Amine'));
    });

    test('Add new user locally (Create)', () {
      final initialCount = userState.totalUsersCount;
      final newUser = AppUser(
        id: 'test-user-01',
        fullName: 'Test User',
        email: 'test@example.com',
        createdAt: DateTime.now(),
      );

      userState.addUser(newUser);
      expect(userState.totalUsersCount, initialCount + 1);
      expect(userState.findById('test-user-01')?.fullName, 'Test User');
    });

    test('Update user profile locally (Update)', () {
      final user = userState.allUsers.first;
      final updated = user.copyWith(fullName: 'Updated Name', heightCm: 185);

      userState.updateUser(updated);
      expect(userState.findById(user.id)?.fullName, 'Updated Name');
      expect(userState.findById(user.id)?.heightCm, 185);
    });

    test('Suspend and reactivate user locally', () {
      final activeUser =
          userState.allUsers.firstWhere((u) => u.isActive);
      userState.updateUserStatus(activeUser.id, UserStatus.suspended);
      expect(userState.findById(activeUser.id)?.isSuspended, true);

      userState.updateUserStatus(activeUser.id, UserStatus.active);
      expect(userState.findById(activeUser.id)?.isActive, true);
    });

    test('Prevent deleting the last administrator', () {
      // Find all admins except one and delete them
      final admins = userState.allUsers
          .where((u) => u.role == UserRole.admin)
          .toList();

      for (int i = 0; i < admins.length - 1; i++) {
        userState.deleteUser(admins[i].id);
      }

      final lastAdmin = admins.last;
      expect(() => userState.deleteUser(lastAdmin.id), throwsException);
    });
  });

  group('StepQuest Authentication & Security Tests', () {
    late UserState userState;
    late AuthState authState;
    late NotificationState notificationState;

    setUp(() {
      userState = UserState(initialUsers: _testUsers);
      authState = AuthState();
      notificationState = NotificationState();
    });

    test('Standard user login success', () async {
      final success = await authState.loginUser(
        emailOrUsername: 'amine@example.com',
        password: 'password123',
        userState: userState,
        notificationState: notificationState,
      );

      expect(success, true);
      expect(authState.isAuthenticated, true);
      expect(authState.currentUser?.fullName, 'Amine Ben Ali');
      expect(notificationState.notifications.isNotEmpty, true);
    });

    test('Suspended user login is blocked', () async {
      final success = await authState.loginUser(
        emailOrUsername: 'lina@example.com', // Suspended mock account
        password: 'password123',
        userState: userState,
        notificationState: notificationState,
      );

      expect(success, false);
      expect(authState.isAuthenticated, false);
      expect(authState.errorMessage, contains('suspendu'));
    });

    test('Admin login role verification', () async {
      // Standard user cannot log into admin area
      final normalUserFailed = await authState.loginAdmin(
        email: 'amine@example.com',
        password: 'password123',
        userState: userState,
        notificationState: notificationState,
      );
      expect(normalUserFailed, false);
      expect(authState.errorMessage, contains('privilèges'));

      // Real admin succeeds
      final adminSuccess = await authState.loginAdmin(
        email: 'admin@stepquest.com',
        password: 'admin123',
        userState: userState,
        notificationState: notificationState,
      );
      expect(adminSuccess, true);
      expect(authState.isAdmin, true);
    });

    test('Registration creates user and updates local state', () async {
      final registered = await authState.registerUser(
        fullName: 'Nouveau Membre',
        email: 'nouveau@example.com',
        password: 'securepassword123',
        userState: userState,
        notificationState: notificationState,
      );

      expect(registered, true);
      expect(authState.isAuthenticated, true);
      expect(authState.currentUser?.fullName, 'Nouveau Membre');
      expect(userState.findByEmail('nouveau@example.com'), isNotNull);
    });
  });
}
