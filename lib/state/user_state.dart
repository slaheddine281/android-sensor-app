import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../core/constants/supabase_constants.dart';

class UserState extends ChangeNotifier {
  final List<AppUser> _users;
  bool _isLoadingUsers = false;

  UserState({List<AppUser>? initialUsers})
      : _users = List<AppUser>.from(initialUsers ?? []);

  List<AppUser> get allUsers => List.unmodifiable(_users);
  bool get isLoadingUsers => _isLoadingUsers;

  int get totalUsersCount => _users.length;
  int get activeUsersCount =>
      _users.where((u) => u.status == UserStatus.active).length;
  int get suspendedUsersCount =>
      _users.where((u) => u.status == UserStatus.suspended).length;
  int get adminUsersCount =>
      _users.where((u) => u.role == UserRole.admin).length;

  SupabaseClient? get _supabase => SupabaseConstants.client;

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

  /// Load all users from Supabase (admin use)
  Future<void> loadUsersFromSupabase() async {
    final sb = _supabase;
    if (sb == null) return;

    _isLoadingUsers = true;
    notifyListeners();

    try {
      final data = await sb
          .from(SupabaseConstants.profilesTable)
          .select()
          .order('created_at', ascending: false);

      _users.clear();
      for (final row in data) {
        try {
          _users.add(AppUser.fromMap(row));
        } catch (e) {
          debugPrint('UserState.loadUsers parse error: $e for row $row');
        }
      }
    } catch (e) {
      debugPrint('UserState.loadUsersFromSupabase error: $e');
    }

    _isLoadingUsers = false;
    notifyListeners();
  }

  void addUser(AppUser user) {
    // Avoid duplicates
    if (_users.any((u) => u.id == user.id)) return;
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

  /// Update user in Supabase and local state (admin use)
  Future<void> updateUserInSupabase(AppUser updatedUser) async {
    final sb = _supabase;
    if (sb != null) {
      try {
        await sb
            .from(SupabaseConstants.profilesTable)
            .update({
              'full_name': updatedUser.fullName,
              'email': updatedUser.email,
              'role': updatedUser.role.name,
              'status': updatedUser.status.name,
              'height_cm': updatedUser.heightCm,
              'weight_kg': updatedUser.weightKg,
              'birth_date': updatedUser.birthDate?.toIso8601String(),
              'level': updatedUser.level,
              'device_info': updatedUser.deviceInfo,
              'avatar_url': updatedUser.avatarUrl,
            })
            .eq('id', updatedUser.id);
      } catch (e) {
        debugPrint('updateUserInSupabase error: $e');
      }
    }
    updateUser(updatedUser);
  }

  void updateUserStatus(String userId, UserStatus newStatus) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      _users[index] = _users[index].copyWith(status: newStatus);
      notifyListeners();
    }
    final sb = _supabase;
    if (sb != null) {
      sb
          .from(SupabaseConstants.profilesTable)
          .update({'status': newStatus.name})
          .eq('id', userId)
          .then((_) => null)
          .catchError((e) {
            debugPrint('updateUserStatus Supabase error: $e');
            return null;
          });
    }
  }

  void updateUserRole(String userId, UserRole newRole) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      // Prevent removing the last admin
      if (newRole != UserRole.admin && _users[index].role == UserRole.admin) {
        final remainingAdmins = _users
            .where((u) => u.role == UserRole.admin && u.id != userId)
            .length;
        if (remainingAdmins == 0) {
          throw Exception("Impossible de rétrograder le dernier administrateur.");
        }
      }
      _users[index] = _users[index].copyWith(role: newRole);
      notifyListeners();
    }
    final sb = _supabase;
    if (sb != null) {
      sb
          .from(SupabaseConstants.profilesTable)
          .update({'role': newRole.name})
          .eq('id', userId)
          .then((_) => null)
          .catchError((e) {
            debugPrint('updateUserRole Supabase error: $e');
            return null;
          });
    }
  }

  bool deleteUser(String userId) {
    final userToDelete = findById(userId);
    if (userToDelete == null) return false;

    // Safety check: Prevent deleting the last admin
    if (userToDelete.role == UserRole.admin) {
      final remainingAdmins =
          _users.where((u) => u.role == UserRole.admin && u.id != userId).length;
      if (remainingAdmins == 0) {
        throw Exception("Impossible de supprimer le seul administrateur actif.");
      }
    }

    _users.removeWhere((u) => u.id == userId);
    notifyListeners();

    final sb = _supabase;
    if (sb != null) {
      sb
          .from(SupabaseConstants.profilesTable)
          .update({'status': 'suspended'})
          .eq('id', userId)
          .then((_) => null)
          .catchError((e) {
            debugPrint('deleteUser Supabase error: $e');
            return null;
          });
    }

    return true;
  }
}
