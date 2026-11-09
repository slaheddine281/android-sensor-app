import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';

enum BiometricType {
  face('Reconnaissance faciale'),
  fingerprint('Empreinte digitale');

  final String label;
  const BiometricType(this.label);
}

enum BiometricAuthResult {
  success,
  failed,
  canceled,
  notEnrolled,
  unavailable,
}

/// Service biométrique unifié.
///
/// - Sur le Web, la vérification faciale est assurée par `face-api.js`
///   (`FaceRecognitionService`) : [authenticate] confirme simplement que la
///   comparaison 128D a déjà réussi.
/// - Sur Android / iOS, on délègue au capteur biométrique natif du téléphone
///   (Face ID, Face Unlock, empreinte) via `local_auth`.
class MockBiometricService {
  /// Marqueur stocké dans `face_embedding` lorsqu'un appareil mobile utilise
  /// la biométrie native (il n'y a pas d'embedding 128D à calculer).
  static const String deviceBiometricMarker = 'device-biometric';

  /// Clé locale liant le Face ID natif au compte enrôlé sur cet appareil.
  static const String _boundAccountKey = 'stepquest.face_id.bound_account_email';

  /// Profil minimal du compte lié, pour permettre la connexion Face ID même
  /// sans session Supabase active (après redémarrage de l'application).
  static const String _cachedProfileKey = 'stepquest.face_id.bound_profile';

  final LocalAuthentication _localAuth = LocalAuthentication();

  bool _hardwareSupported = true;
  final bool _fingerprintSensorWorking = true;
  final bool _faceSensorWorking = true;

  bool get isHardwareSupported => _hardwareSupported;
  bool get isFingerprintAvailable =>
      _hardwareSupported && _fingerprintSensorWorking;
  bool get isFaceAvailable => _hardwareSupported && _faceSensorWorking;

  /// Vrai lorsque l'on peut utiliser le capteur biométrique du système.
  bool get isNativePlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  void setHardwareSupported(bool value) {
    _hardwareSupported = value;
  }

  /// Associe ce Face ID natif à un compte précis.
  ///
  /// C'est indispensable : la biométrie système prouve seulement « c'est le
  /// propriétaire de l'appareil », pas de quel compte StepQuest il s'agit.
  /// Sans cette liaison, n'importe qui pourrait saisir l'e-mail d'un autre
  /// utilisateur puis valider son propre doigt.
  Future<void> bindAccountToDevice(String email) async {
    if (kIsWeb || email.trim().isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_boundAccountKey, email.trim().toLowerCase());
    } catch (_) {
      // La liaison est un confort : un échec ne doit pas bloquer l'enrôlement.
    }
  }

  /// E-mail du compte lié au Face ID de cet appareil, ou `null`.
  Future<String?> boundAccountEmail() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_boundAccountKey);
      if (value == null || value.trim().isEmpty) return null;
      return value.trim();
    } catch (_) {
      return null;
    }
  }

  /// Supprime la liaison locale (désactivation du Face ID).
  Future<void> clearDeviceBinding() async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_boundAccountKey);
      await prefs.remove(_cachedProfileKey);
    } catch (_) {
      // Rien à faire : l'état serveur reste la source de vérité.
    }
  }

  /// Mémorise localement le profil lié au Face ID de cet appareil.
  Future<void> cacheBoundProfile(AppUser user) async {
    if (kIsWeb) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cachedProfileKey, jsonEncode(user.toMap()));
    } catch (_) {
      // Cache facultatif : la connexion Supabase reste prioritaire.
    }
  }

  /// Profil mémorisé lors de l'enrôlement, ou `null`.
  Future<AppUser?> cachedBoundProfile() async {
    if (kIsWeb) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cachedProfileKey);
      if (raw == null || raw.trim().isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return AppUser.fromMap(decoded);
    } catch (_) {
      return null;
    }
  }

  /// Vérifie si l'appareil possède un capteur biométrique utilisable.
  Future<bool> canUseDeviceBiometrics() async {
    if (!isNativePlatform) return false;
    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return false;
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  /// Authentifie l'utilisateur.
  ///
  /// [forceSuccess] n'est conservé que pour la compatibilité des tests et du
  /// Web où la vérification faciale a déjà eu lieu.
  Future<BiometricAuthResult> authenticate({
    required BiometricType type,
    bool forceSuccess = false,
    String reason = 'Authentifiez-vous pour accéder à StepQuest',
  }) async {
    // Web : le scan facial 128D a déjà validé l'identité.
    if (kIsWeb) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!_hardwareSupported) return BiometricAuthResult.notEnrolled;
      return BiometricAuthResult.success;
    }

    if (!isNativePlatform || !_hardwareSupported) {
      return BiometricAuthResult.unavailable;
    }

    try {
      final supported = await _localAuth.isDeviceSupported();
      if (!supported) return BiometricAuthResult.notEnrolled;

      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return BiometricAuthResult.notEnrolled;

      final ok = await _localAuth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          // Windows Hello ne sait pas fonctionner en mode « biométrie seule »
          // (le plugin lève UnsupportedError). Ailleurs on l'exige.
          biometricOnly: defaultTargetPlatform != TargetPlatform.windows,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      return ok ? BiometricAuthResult.success : BiometricAuthResult.failed;
    } on PlatformException catch (e) {
      switch (e.code) {
        case auth_error.notAvailable:
        case auth_error.notEnrolled:
        case auth_error.passcodeNotSet:
          return BiometricAuthResult.notEnrolled;
        case auth_error.lockedOut:
        case auth_error.permanentlyLockedOut:
          return BiometricAuthResult.failed;
        case auth_error.otherOperatingSystem:
        case auth_error.biometricOnlyNotSupported:
          return BiometricAuthResult.unavailable;
        default:
          return BiometricAuthResult.failed;
      }
    } catch (_) {
      return BiometricAuthResult.unavailable;
    }
  }

  /// Message utilisateur associé à un échec biométrique.
  static String messageFor(BiometricAuthResult result) {
    switch (result) {
      case BiometricAuthResult.success:
        return 'Authentification biométrique réussie.';
      case BiometricAuthResult.failed:
        return 'Biométrie non reconnue. Veuillez réessayer.';
      case BiometricAuthResult.canceled:
        return 'Authentification biométrique annulée.';
      case BiometricAuthResult.notEnrolled:
        return 'Aucune biométrie n\'est configurée sur cet appareil. Ajoutez un visage ou une empreinte dans les réglages du téléphone.';
      case BiometricAuthResult.unavailable:
        return 'La biométrie n\'est pas disponible sur cet appareil.';
    }
  }
}
