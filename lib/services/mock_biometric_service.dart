import 'dart:async';

enum BiometricType {
  face('Reconnaissance faciale'),
  @Deprecated('Empreinte supprimée au profit de Face ID')
  fingerprint('Empreinte digitale');

  final String label;
  const BiometricType(this.label);
}

enum BiometricAuthResult {
  success,
  failed,
  canceled,
  notEnrolled,
}

/// Simulated Biometric Authentication Service
class MockBiometricService {
  bool _hardwareSupported = true;
  final bool _fingerprintSensorWorking = true;
  final bool _faceSensorWorking = true;

  bool get isHardwareSupported => _hardwareSupported;
  bool get isFingerprintAvailable => _hardwareSupported && _fingerprintSensorWorking;
  bool get isFaceAvailable => _hardwareSupported && _faceSensorWorking;

  void setHardwareSupported(bool value) {
    _hardwareSupported = value;
  }

  /// Simulate authenticating with fingerprint or face
  Future<BiometricAuthResult> authenticate({
    required BiometricType type,
    bool forceSuccess = true,
  }) async {
    // Artificial slight delay to simulate hardware scanning
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!_hardwareSupported) {
      return BiometricAuthResult.notEnrolled;
    }

    if (forceSuccess) {
      return BiometricAuthResult.success;
    } else {
      return BiometricAuthResult.failed;
    }
  }
}
