import 'package:flutter/material.dart';
import 'auth_state.dart';
import 'user_state.dart';
import 'notification_state.dart';
import 'app_settings_state.dart';
import '../services/mock_biometric_service.dart';
import '../services/face_recognition_service.dart';

class AppStateProvider extends InheritedWidget {
  final AuthState authState;
  final UserState userState;
  final NotificationState notificationState;
  final AppSettingsState settingsState;
  final MockBiometricService biometricService;
  final FaceRecognitionService faceService;

  const AppStateProvider({
    super.key,
    required this.authState,
    required this.userState,
    required this.notificationState,
    required this.settingsState,
    required this.biometricService,
    required this.faceService,
    required super.child,
  });

  static AppStateProvider of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AppStateProvider>();
    assert(provider != null, 'No AppStateProvider found in context');
    return provider!;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => true;
}

extension AppStateExtensions on BuildContext {
  AuthState get auth => AppStateProvider.of(this).authState;
  UserState get users => AppStateProvider.of(this).userState;
  NotificationState get notifications =>
      AppStateProvider.of(this).notificationState;
  AppSettingsState get settings => AppStateProvider.of(this).settingsState;
  MockBiometricService get biometrics =>
      AppStateProvider.of(this).biometricService;
  FaceRecognitionService get faceRecognition =>
      AppStateProvider.of(this).faceService;
}
