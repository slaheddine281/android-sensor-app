import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/user_notification.dart';
import '../services/mock_biometric_service.dart';
import 'user_state.dart';
import 'notification_state.dart';

class AuthState extends ChangeNotifier {
  AppUser? _currentUser;
  bool _rememberMe = true;
  bool _isLoading = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setRememberMe(bool value) {
    _rememberMe = value;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Simulate checking session on splash screen
  Future<bool> checkExistingSession(UserState userState) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 1000));

    // For first launch demo, start unauthenticated or with Amine if remembered
    _isLoading = false;
    notifyListeners();
    return _currentUser != null;
  }

  /// Standard User Login
  Future<bool> loginUser({
    required String emailOrUsername,
    required String password,
    required UserState userState,
    required NotificationState notificationState,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final cleanEmail = emailOrUsername.trim().toLowerCase();
    AppUser? targetUser = userState.findByEmail(cleanEmail);

    // If not found by exact email, allow searching by name or demo shortcut
    if (targetUser == null) {
      final matches = userState.allUsers.where(
        (u) => u.fullName.toLowerCase().contains(cleanEmail),
      );
      if (matches.isNotEmpty) {
        targetUser = matches.first;
      }
    }

    if (targetUser == null) {
      _errorMessage = "Aucun compte trouvé avec cet identifiant.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (targetUser.isSuspended) {
      _errorMessage =
          "Ce compte a été suspendu par un administrateur. Connexion impossible.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Passwords in mock demo: at least 4 characters
    if (password.length < 4) {
      _errorMessage = "Mot de passe trop court (min. 4 caractères).";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Success
    final updated = targetUser.copyWith(lastLoginAt: DateTime.now());
    userState.updateUser(updated);
    _currentUser = updated;
    _isLoading = false;

    notificationState.addNotification(
      title: 'Connexion réussie',
      message: 'Connexion effectuée avec succès (${updated.fullName}).',
      type: NotificationType.loginDetected,
      relatedUserId: updated.id,
    );

    notifyListeners();
    return true;
  }

  /// Administrator Login with Role Verification
  Future<bool> loginAdmin({
    required String email,
    required String password,
    required UserState userState,
    required NotificationState notificationState,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final cleanEmail = email.trim().toLowerCase();
    final user = userState.findByEmail(cleanEmail);

    if (user == null) {
      _errorMessage = "Identifiants d'administrateur introuvables.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (!user.isAdmin) {
      _errorMessage =
          "Accès refusé : Ce compte n'a pas les privilèges administrateur.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (user.isSuspended) {
      _errorMessage = "Ce compte administrateur est suspendu.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (password.length < 4) {
      _errorMessage = "Mot de passe administrateur incorrect.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updated = user.copyWith(lastLoginAt: DateTime.now());
    userState.updateUser(updated);
    _currentUser = updated;
    _isLoading = false;

    notificationState.addNotification(
      title: 'Connexion Administrateur',
      message: 'Session admin ouverte par ${updated.fullName}.',
      type: NotificationType.loginDetected,
      relatedUserId: updated.id,
    );

    notifyListeners();
    return true;
  }

  /// Biometric Quick Login
  Future<bool> loginWithBiometrics({
    required BiometricType type,
    required UserState userState,
    required NotificationState notificationState,
    required MockBiometricService biometricService,
    String? targetEmail,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await biometricService.authenticate(type: type);

    if (result != BiometricAuthResult.success) {
      _errorMessage = "Échec de l'authentification biométrique.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Find the user to log in (default to Amine or targetEmail)
    AppUser? user;
    if (targetEmail != null) {
      user = userState.findByEmail(targetEmail);
    } else {
      final candidates = userState.allUsers.where(
        (u) =>
            type == BiometricType.fingerprint
                ? u.biometricFingerprintEnabled
                : u.biometricFaceEnabled,
      );
      if (candidates.isNotEmpty) {
        user = candidates.first;
      } else if (userState.allUsers.isNotEmpty) {
        user = userState.allUsers.first;
      }
    }

    if (user == null) {
      _errorMessage = "Aucun profil configuré pour cette biométrie.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    if (user.isSuspended) {
      _errorMessage = "Votre compte est suspendu. Connexion biométrique bloquée.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updated = user.copyWith(lastLoginAt: DateTime.now());
    userState.updateUser(updated);
    _currentUser = updated;
    _isLoading = false;

    notificationState.addNotification(
      title: 'Connexion biométrique',
      message:
          'Connexion via ${type.label.toLowerCase()} réussie (${updated.fullName}).',
      type: NotificationType.loginDetected,
      relatedUserId: updated.id,
    );

    notifyListeners();
    return true;
  }

  /// Register a new user in local state
  Future<bool> registerUser({
    required String fullName,
    required String email,
    required String password,
    required UserState userState,
    required NotificationState notificationState,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));

    final cleanEmail = email.trim().toLowerCase();
    if (userState.findByEmail(cleanEmail) != null) {
      _errorMessage = "Un compte existe déjà avec cette adresse email.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final newUser = AppUser(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      email: cleanEmail,
      role: UserRole.user,
      status: UserStatus.active,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      biometricFingerprintEnabled: false,
      biometricFaceEnabled: false,
      level: 1,
      heightCm: 170,
      weightKg: 65,
      birthDate: DateTime(2000, 1, 1),
      deviceInfo: 'Appareil mobile StepQuest',
    );

    userState.addUser(newUser);
    _currentUser = newUser;
    _isLoading = false;

    notificationState.addNotification(
      title: 'Compte créé',
      message: "Un nouvel utilisateur s'est inscrit : ${newUser.fullName}.",
      type: NotificationType.accountCreated,
      relatedUserId: newUser.id,
    );

    notifyListeners();
    return true;
  }

  /// Update the current authenticated user's profile
  void updateCurrentProfile({
    required AppUser updatedUser,
    required UserState userState,
    required NotificationState notificationState,
  }) {
    userState.updateUser(updatedUser);
    _currentUser = updatedUser;

    notificationState.addNotification(
      title: 'Profil modifié',
      message: 'Le profil de ${updatedUser.fullName} a été mis à jour.',
      type: NotificationType.profileUpdated,
      relatedUserId: updatedUser.id,
    );

    notifyListeners();
  }

  /// Delete current user account (User space)
  void deleteCurrentAccount({
    required UserState userState,
    required NotificationState notificationState,
  }) {
    if (_currentUser == null) return;
    final deleted = _currentUser!;
    userState.deleteUser(deleted.id);

    notificationState.addNotification(
      title: 'Compte supprimé',
      message: 'Le compte de ${deleted.fullName} a été supprimé.',
      type: NotificationType.accountDeleted,
    );

    _currentUser = null;
    notifyListeners();
  }

  /// Request password reset
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Sign Out
  void signOut() {
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }
}
