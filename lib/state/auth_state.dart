import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_notification.dart';
import '../core/constants/supabase_constants.dart';
import '../services/mock_biometric_service.dart';
import 'user_state.dart';
import 'notification_state.dart';

class AuthState extends ChangeNotifier {
  AppUser? _currentUser;
  bool _rememberMe = true;
  bool _isLoading = false;
  bool _isPasswordRecovery = false;
  String? _errorMessage;

  AppUser? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get rememberMe => _rememberMe;
  bool get isLoading => _isLoading;
  bool get isPasswordRecovery => _isPasswordRecovery;
  String? get errorMessage => _errorMessage;

  SupabaseClient? get _supabase => SupabaseConstants.client;

  void setPasswordRecovery(bool value) {
    _isPasswordRecovery = value;
    notifyListeners();
  }

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

  /// Fetch a profile row from public.profiles by user UUID
  Future<AppUser?> _fetchProfile(String userId) async {
    final sb = _supabase;
    if (sb == null) return null;
    try {
      final data = await sb
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } catch (e) {
      debugPrint('_fetchProfile error: $e');
      return null;
    }
  }

  /// Fetch a profile row from public.profiles by e-mail (Face ID login when
  /// no Supabase session and the local user list is still empty).
  Future<AppUser?> fetchProfileByEmail(String email) async {
    final sb = _supabase;
    if (sb == null) return null;
    try {
      final data = await sb
          .from(SupabaseConstants.profilesTable)
          .select()
          .eq('email', email.trim().toLowerCase())
          .maybeSingle();
      if (data == null) return null;
      return AppUser.fromMap(data);
    } catch (e) {
      debugPrint('fetchProfileByEmail error: $e');
      return null;
    }
  }

  /// Check session on splash screen (uses Supabase persisted session when available)
  Future<bool> checkExistingSession(UserState userState) async {
    _isLoading = true;
    notifyListeners();

    final sb = _supabase;
    if (sb != null) {
      try {
        final session = sb.auth.currentSession;
        if (session != null) {
          final profile = await _fetchProfile(session.user.id);
          if (profile != null) {
            _currentUser = profile;
            if (userState.findById(profile.id) == null) {
              userState.addUser(profile);
            }
            if (profile.isAdmin) {
              await userState.loadUsersFromSupabase();
            }
            _isLoading = false;
            notifyListeners();
            return true;
          }
        }
      } catch (e) {
        debugPrint('checkExistingSession error: $e');
      }
    }

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

    final cleanEmail = emailOrUsername.trim().toLowerCase();
    final sb = _supabase;

    if (sb != null) {
      try {
        final response = await sb.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        if (response.user == null) {
          _errorMessage = 'Identifiants incorrects. Veuillez réessayer.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final profile = await _fetchProfile(response.user!.id);
        if (profile == null) {
          _errorMessage = 'Profil introuvable. Contactez un administrateur.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (profile.isSuspended) {
          await sb.auth.signOut();
          _errorMessage =
              'Ce compte a été suspendu par un administrateur. Connexion impossible.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await sb
            .from(SupabaseConstants.profilesTable)
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', profile.id);

        final updated = profile.copyWith(lastLoginAt: DateTime.now());
        _currentUser = updated;

        if (userState.findById(updated.id) == null) {
          userState.addUser(updated);
        } else {
          userState.updateUser(updated);
        }

        if (updated.isAdmin) {
          await userState.loadUsersFromSupabase();
        }

        notificationState.addNotification(
          title: 'Connexion réussie',
          message: 'Connexion effectuée avec succès (${updated.fullName}).',
          type: NotificationType.loginDetected,
          relatedUserId: updated.id,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        // Fall back to in-memory check if network error or test mode
        debugPrint('Supabase loginUser fallback: $e');
      }
    }

    // In-memory fallback (used in unit tests / offline)
    AppUser? targetUser = userState.findByEmail(cleanEmail);
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

    if (password.length < 4) {
      _errorMessage = "Mot de passe trop court (min. 4 caractères).";
      _isLoading = false;
      notifyListeners();
      return false;
    }

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

    final cleanEmail = email.trim().toLowerCase();
    final sb = _supabase;

    if (sb != null) {
      try {
        final response = await sb.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );

        if (response.user == null) {
          _errorMessage = "Identifiants d'administrateur introuvables.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        final profile = await _fetchProfile(response.user!.id);
        if (profile == null) {
          await sb.auth.signOut();
          _errorMessage = "Profil administrateur introuvable.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (!profile.isAdmin) {
          await sb.auth.signOut();
          _errorMessage =
              "Accès refusé : Ce compte n'a pas les privilèges administrateur.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        if (profile.isSuspended) {
          await sb.auth.signOut();
          _errorMessage = "Ce compte administrateur est suspendu.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await sb
            .from(SupabaseConstants.profilesTable)
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', profile.id);

        final updated = profile.copyWith(lastLoginAt: DateTime.now());
        _currentUser = updated;

        if (userState.findById(updated.id) == null) {
          userState.addUser(updated);
        } else {
          userState.updateUser(updated);
        }

        if (updated.isAdmin) {
          await userState.loadUsersFromSupabase();
        }

        notificationState.addNotification(
          title: 'Connexion Administrateur',
          message: 'Session admin ouverte par ${updated.fullName}.',
          type: NotificationType.loginDetected,
          relatedUserId: updated.id,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        debugPrint('Supabase loginAdmin fallback: $e');
      }
    }

    // In-memory fallback
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
    bool biometricVerified = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    // Sur mobile, l'écran appelle d'abord le capteur natif puis nous transmet
    // `biometricVerified: true` pour éviter de demander deux fois le Face ID.
    // Sur le Web, le scan facial 128D a également déjà été effectué.
    if (!biometricVerified) {
      final result = await biometricService.authenticate(type: type);

      if (result != BiometricAuthResult.success) {
        _errorMessage = MockBiometricService.messageFor(result);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    AppUser? user;
    final sb = _supabase;
    if (sb != null) {
      final session = sb.auth.currentSession;
      if (session != null) {
        user = await _fetchProfile(session.user.id);
      }
    }

    // Récupère l'e-mail lié à cet appareil si aucun e-mail n'a été spécifié
    final boundEmail = await biometricService.boundAccountEmail();
    final effectiveEmail = (targetEmail != null && targetEmail.trim().isNotEmpty)
        ? targetEmail.trim().toLowerCase()
        : boundEmail?.trim().toLowerCase();

    if (user == null && effectiveEmail != null && effectiveEmail.isNotEmpty) {
      user = userState.findByEmail(effectiveEmail) ??
          await fetchProfileByEmail(effectiveEmail);
    }

    // Restauration et synchronisation avec le profil local mémorisé sur l'appareil
    if (biometricService.isNativePlatform) {
      final cached = await biometricService.cachedBoundProfile();
      if (cached != null) {
        final matchesEmail = effectiveEmail == null ||
            effectiveEmail.isEmpty ||
            cached.email.trim().toLowerCase() == effectiveEmail;
        if (user == null && matchesEmail) {
          user = cached;
        } else if (user != null && matchesEmail) {
          user = user.copyWith(
            biometricFingerprintEnabled: user.biometricFingerprintEnabled ||
                cached.biometricFingerprintEnabled,
            biometricFaceEnabled:
                user.biometricFaceEnabled || cached.biometricFaceEnabled,
            faceEmbedding: user.faceEmbedding ?? cached.faceEmbedding,
            facePhotoUrl: user.facePhotoUrl ?? cached.facePhotoUrl,
          );
        }
      }
    }

    if (user == null) {
      final candidates = userState.allUsers.where((u) {
        if (type == BiometricType.fingerprint) {
          return u.biometricFingerprintEnabled;
        }
        return u.biometricFaceEnabled || u.hasFaceRegistered;
      });
      if (candidates.isNotEmpty) {
        user = candidates.first;
      }
    }

    if (user == null) {
      _errorMessage = (effectiveEmail != null && effectiveEmail.isNotEmpty)
          ? "Profil introuvable pour $effectiveEmail. Connectez-vous d'abord avec votre mot de passe."
          : (type == BiometricType.fingerprint
              ? "Aucun profil avec empreinte digitale configurée."
              : "Aucun profil configuré pour cette biométrie.");
      _isLoading = false;
      notifyListeners();
      return false;
    }

    // Sécurité : vérification que la biométrie demandée est bien activée
    if (type == BiometricType.fingerprint) {
      if (!user.biometricFingerprintEnabled) {
        _errorMessage =
            "L'empreinte digitale n'est pas activée pour ce compte. Activez-la dans votre profil ou paramètres.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } else {
      if (!user.hasFaceRegistered && !user.biometricFaceEnabled) {
        _errorMessage =
            "Aucun visage n'est enregistré pour ce compte. Activez Face ID dans les paramètres.";
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    if (user.isSuspended) {
      _errorMessage = "Votre compte est suspendu. Connexion biométrique bloquée.";
      _isLoading = false;
      notifyListeners();
      return false;
    }

    final updated = user.copyWith(lastLoginAt: DateTime.now());
    if (userState.findById(updated.id) != null) {
      userState.updateUser(updated);
    } else {
      userState.addUser(updated);
    }
    _currentUser = updated;
    _isLoading = false;

    notificationState.addNotification(
      title: 'Connexion biométrique',
      message:
          'Connexion via reconnaissance faciale Face ID réussie (${updated.fullName}).',
      type: NotificationType.loginDetected,
      relatedUserId: updated.id,
    );

    notifyListeners();
    return true;
  }

  /// Register a new user via Supabase Auth + profiles table
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

    final cleanEmail = email.trim().toLowerCase();
    final sb = _supabase;

    if (sb != null) {
      try {
        final response = await sb.auth.signUp(
          email: cleanEmail,
          password: password,
          data: {
            'full_name': fullName.trim(),
            'role': 'user',
          },
        );

        if (response.user == null) {
          _errorMessage = "Échec de la création du compte. Réessayez.";
          _isLoading = false;
          notifyListeners();
          return false;
        }

        await Future.delayed(const Duration(milliseconds: 800));
        AppUser? profile = await _fetchProfile(response.user!.id);

        if (profile == null) {
          await sb.from(SupabaseConstants.profilesTable).upsert({
            'id': response.user!.id,
            'full_name': fullName.trim(),
            'email': cleanEmail,
            'role': 'user',
            'status': 'active',
            'level': 1,
            'biometric_fingerprint_enabled': false,
            'biometric_face_enabled': false,
            'created_at': DateTime.now().toIso8601String(),
            'last_login_at': DateTime.now().toIso8601String(),
          });
          profile = await _fetchProfile(response.user!.id);
        }

        profile ??= AppUser(
          id: response.user!.id,
          fullName: fullName.trim(),
          email: cleanEmail,
          role: UserRole.user,
          status: UserStatus.active,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          biometricFingerprintEnabled: false,
          biometricFaceEnabled: false,
          level: 1,
        );

        _currentUser = profile;

        if (userState.findById(profile.id) == null) {
          userState.addUser(profile);
        }

        notificationState.addNotification(
          title: 'Compte créé',
          message: "Un nouvel utilisateur s'est inscrit : ${profile.fullName}.",
          type: NotificationType.accountCreated,
          relatedUserId: profile.id,
        );

        _isLoading = false;
        notifyListeners();
        return true;
      } on AuthException catch (e) {
        _errorMessage = _mapAuthError(e.message);
        _isLoading = false;
        notifyListeners();
        return false;
      } catch (e) {
        debugPrint('Supabase registerUser fallback: $e');
      }
    }

    // In-memory fallback (used in unit tests / offline)
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
  Future<void> updateCurrentProfile({
    required AppUser updatedUser,
    required UserState userState,
    required NotificationState notificationState,
  }) async {
    final sb = _supabase;
    if (sb != null) {
      try {
        await sb
            .from(SupabaseConstants.profilesTable)
            .update({
              'full_name': updatedUser.fullName,
              'avatar_url': updatedUser.avatarUrl,
              'height_cm': updatedUser.heightCm,
              'weight_kg': updatedUser.weightKg,
              'birth_date': updatedUser.birthDate?.toIso8601String(),
              'level': updatedUser.level,
              'device_info': updatedUser.deviceInfo,
              'biometric_fingerprint_enabled':
                  updatedUser.biometricFingerprintEnabled,
              'biometric_face_enabled': updatedUser.biometricFaceEnabled,
              'face_embedding': updatedUser.faceEmbedding,
              'face_photo_url': updatedUser.facePhotoUrl,
            })
            .eq('id', updatedUser.id);
      } catch (e) {
        debugPrint('updateCurrentProfile Supabase error: $e');
      }
    }

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

  /// Delete current user account
  Future<void> deleteCurrentAccount({
    required UserState userState,
    required NotificationState notificationState,
  }) async {
    if (_currentUser == null) return;
    final deleted = _currentUser!;

    final sb = _supabase;
    if (sb != null) {
      try {
        await sb
            .from(SupabaseConstants.profilesTable)
            .update({'status': 'suspended'})
            .eq('id', deleted.id);
        await sb.auth.signOut();
      } catch (e) {
        debugPrint('deleteCurrentAccount error: $e');
      }
    }

    userState.deleteUser(deleted.id);

    notificationState.addNotification(
      title: 'Compte supprimé',
      message: 'Le compte de ${deleted.fullName} a été supprimé.',
      type: NotificationType.accountDeleted,
    );

    _currentUser = null;
    notifyListeners();
  }

  /// Request password reset via Supabase
  Future<bool> requestPasswordReset(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final sb = _supabase;
    if (sb != null) {
      try {
        String? redirectTo;
        if (kIsWeb) {
          redirectTo = Uri.base.origin;
        }
        await sb.auth.resetPasswordForEmail(
          email.trim().toLowerCase(),
          redirectTo: redirectTo,
        );
      } catch (e) {
        debugPrint('requestPasswordReset error: $e');
        _errorMessage = _mapAuthError(e.toString());
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Update password in Supabase for current recovery or authenticated session
  Future<bool> updatePassword(
    String newPassword, {
    String? email,
    String? resetCode,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final sb = _supabase;
    if (sb != null) {
      try {
        // 1. Tenter d'extraire la session depuis l'URL si elle n'est pas encore chargée
        if (sb.auth.currentSession == null && kIsWeb) {
          try {
            final url = Uri.base;
            final urlStr = url.toString();
            if (urlStr.contains('access_token') ||
                urlStr.contains('code=') ||
                urlStr.contains('type=recovery')) {
              await sb.auth.getSessionFromUrl(url);
            }
          } catch (e) {
            debugPrint('getSessionFromUrl in updatePassword error: $e');
          }
        }

        // 2. Si un code OTP ou jeton a été saisi avec l'e-mail, valider avec verifyOTP
        if (sb.auth.currentSession == null &&
            email != null &&
            email.trim().isNotEmpty &&
            resetCode != null &&
            resetCode.trim().isNotEmpty) {
          try {
            await sb.auth.verifyOTP(
              email: email.trim().toLowerCase(),
              token: resetCode.trim(),
              type: OtpType.recovery,
            );
          } catch (e) {
            debugPrint('verifyOTP error: $e');
            _errorMessage = 'Code de réinitialisation invalide ou expiré.';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        }

        // 3. Vérifier la présence de la session active
        if (sb.auth.currentSession == null) {
          _errorMessage =
              'Session de réinitialisation introuvable. Veuillez cliquer sur le lien reçu dans votre boîte e-mail ou saisir le code de vérification reçu.';
          _isLoading = false;
          notifyListeners();
          return false;
        }

        // 4. Mettre à jour le mot de passe de l'utilisateur
        final res = await sb.auth.updateUser(
          UserAttributes(password: newPassword),
        );

        if (res.user != null) {
          _isPasswordRecovery = false;
          _isLoading = false;
          notifyListeners();
          return true;
        }
      } catch (e) {
        debugPrint('updatePassword error: $e');
        _errorMessage = _mapAuthError(e.toString());
        _isLoading = false;
        notifyListeners();
        return false;
      }
    }

    // Mode simulation / hors-ligne pour les tests
    _isPasswordRecovery = false;
    _isLoading = false;
    notifyListeners();
    return true;
  }

  /// Sign Out
  Future<void> signOut() async {
    final sb = _supabase;
    if (sb != null) {
      try {
        await sb.auth.signOut();
      } catch (e) {
        debugPrint('signOut error: $e');
      }
    }
    _currentUser = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// Map Supabase Auth error messages to French
  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Un compte existe déjà avec cette adresse email.';
    }
    if (msg.contains('password should be at least')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (msg.contains('unable to validate email address')) {
      return 'Adresse email invalide.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erreur réseau. Vérifiez votre connexion internet.';
    }
    if (msg.contains('email rate limit')) {
      return 'Trop de tentatives. Réessayez dans quelques minutes.';
    }
    return 'Erreur d\'authentification. Réessayez.';
  }
}
