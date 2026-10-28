import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../data/mock_users.dart';

class UserState extends ChangeNotifier {
  final List<AppUser> _users = List<AppUser>.from(initialMockUsers);

  List<AppUser> get allUsers => List.unmodifiable(_users);

  int get totalUsersCount => _users.length;
  int get activeUsersCount =>
      _users.where((u) => u.status == UserStatus.active).length;
  int get suspendedUsersCount =>
      _users.where((u) => u.status == UserStatus.suspended).length;
  int get adminUsersCount =>
      _users.where((u) => u.role == UserRole.admin).length;

  AppUser? findById(String id) {
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  AppUser? findByEmail(String email) {
    try {
      return _users.firstWhere(
        (u) => u.email.trim().toLowerCase() == email.trim().toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  List<AppUser> filter({
    String query = '',
    UserStatus? statusFilter,
    UserRole? roleFilter,
  }) {
    return _users.where((user) {
      // Query filter
      if (query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchesName = user.fullName.toLowerCase().contains(q);
        final matchesEmail = user.email.toLowerCase().contains(q);
        if (!matchesName && !matchesEmail) return false;
      }

      // Status filter
      if (statusFilter != null && user.status != statusFilter) {
        return false;
      }

      // Role filter
      if (roleFilter != null && user.role != roleFilter) {
        return false;
      }

      return true;
    }).toList();
  }

  void addUser(AppUser user) {
    _users.insert(0, user);
    notifyListeners();
  }

  void updateUser(AppUser updatedUser) {
    final index = _users.indexWhere((u) => u.id == updatedUser.id);
    if (index != -1) {
      _users[index] = updatedUser;
      notifyListeners();
    }
  }

  void updateUserStatus(String userId, UserStatus newStatus) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void updateUserRole(String userId, UserRole newRole) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      // Prevent removing the last admin
      if (newRole != UserRole.admin && _users[index].role == UserRole.admin) {
        final remainingAdmins = _users.where((u) => u.role == UserRole.admin && u.id != userId).length;
        if (remainingAdmins == 0) {
          throw Exception("Impossible de rétrograder le dernier administrateur.");
        }
      }
      _users[index] = _users[index].copyWith(role: newRole);
      notifyListeners();
    }
  }

  bool deleteUser(String userId) {
    final userToDelete = findById(userId);
    if (userToDelete == null) return false;

    // Safety check: Prevent deleting the last admin
    if (userToDelete.role == UserRole.admin) {
      final remainingAdmins = _users.where((u) => u.role == UserRole.admin && u.id != userId).length;
      if (remainingAdmins == 0) {
        throw Exception("Impossible de supprimer le seul administrateur actif.");
      }
    }

    _users.removeWhere((u) => u.id == userId);
    notifyListeners();
    return true;
  }
}
