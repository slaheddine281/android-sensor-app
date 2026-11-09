import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../shared/screens/biometric_auth_screen.dart';
import 'face_enrollment_screen.dart';
import 'user_home_screen.dart';

class BiometricSetupScreen extends StatefulWidget {
  final bool isInitialOnboarding;

  const BiometricSetupScreen({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  State<BiometricSetupScreen> createState() => _BiometricSetupScreenState();
}

class _BiometricSetupScreenState extends State<BiometricSetupScreen> {
  bool _faceEnabled = true;
  bool _fingerprintEnabled = false;
  bool _isSaving = false;
  bool _isInitialized = false;

  /// Sur téléphone, on s'appuie sur la biométrie native du système.
  bool get _usesNativeBiometrics {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.auth.currentUser;
      if (user != null) {
        _faceEnabled = user.biometricFaceEnabled;
        _fingerprintEnabled = user.biometricFingerprintEnabled;
      }
      _isInitialized = true;
    }
  }

  Future<void> _handleTestBiometrics() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const BiometricAuthScreen(
          type: BiometricType.face,
          isSimulationTestOnly: true,
        ),
      ),
    );
  }

  Future<void> _handleSavePreferences() async {
    setState(() {
      _isSaving = true;
    });

    final currentUser = context.auth.currentUser;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        biometricFingerprintEnabled: _fingerprintEnabled,
        biometricFaceEnabled: _faceEnabled,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences biométriques enregistrées avec succès.'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    setState(() {
      _isSaving = false;
    });

    if (widget.isInitialOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = context.auth.currentUser;
    final hasFaceRegistered = currentUser?.hasFaceRegistered == true;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Sécurité Biométrique Face ID',
        showBackButton: !widget.isInitialOnboarding,
        actions: [
          if (widget.isInitialOnboarding)
            TextButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const UserHomeScreen()),
                );
              },
              child: const Text(
                'Passer',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                'Reconnaissance Faciale Face ID',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Protégez votre compte avec l\'authentification faciale haute précision par intelligence artificielle.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Carte Face ID Principale
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.face_retouching_natural_rounded,
                            color: AppColors.primaryLight,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Face ID IA',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _faceEnabled && hasFaceRegistered
                                          ? AppColors.secondary
                                          : _faceEnabled
                                              ? const Color(0xFFF59E0B)
                                              : AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _faceEnabled
                                        ? (hasFaceRegistered
                                            ? (_usesNativeBiometrics
                                                ? 'Face ID activé sur cet appareil'
                                                : 'Modèle 128D configuré')
                                            : 'Visage non configuré')
                                        : 'Désactivé',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _faceEnabled && hasFaceRegistered
                                          ? AppColors.secondary
                                          : _faceEnabled
                                              ? const Color(0xFFF59E0B)
                                              : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _faceEnabled,
                          activeThumbColor: AppColors.primary,
                          activeTrackColor: AppColors.primarySoft,
                          onChanged: (val) {
                            setState(() {
                              _faceEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Bouton Enrôlement / Scanner Visage
                    AppButton(
                      label: _usesNativeBiometrics
                          ? (hasFaceRegistered
                              ? 'Mettre à jour Face ID'
                              : 'Activer Face ID')
                          : (hasFaceRegistered
                              ? 'Recalibrer / Mettre à jour mon visage'
                              : 'Scanner et enregistrer mon visage'),
                      icon: _usesNativeBiometrics
                          ? Icons.fingerprint_rounded
                          : Icons.camera_enhance_rounded,
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const FaceEnrollmentScreen(),
                          ),
                        );
                        if (mounted) setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Carte Empreinte Digitale ───────────────────────────────────
              AppCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                : AppColors.secondarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            color: AppColors.secondary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Empreinte digitale',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _fingerprintEnabled
                                          ? AppColors.secondary
                                          : AppColors.textMuted,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _fingerprintEnabled
                                        ? (_usesNativeBiometrics
                                            ? 'Empreinte activée sur cet appareil'
                                            : 'Empreinte activée')
                                        : 'Désactivée',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _fingerprintEnabled
                                          ? AppColors.secondary
                                          : AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _fingerprintEnabled,
                          activeThumbColor: AppColors.secondary,
                          activeTrackColor:
                              AppColors.secondary.withValues(alpha: 0.2),
                          onChanged: (val) {
                            setState(() {
                              _fingerprintEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                    if (_fingerprintEnabled && _usesNativeBiometrics) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Tester l\'empreinte digitale',
                        icon: Icons.fingerprint_rounded,
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BiometricAuthScreen(
                                type: BiometricType.fingerprint,
                                isSimulationTestOnly: true,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Carte d'information explicative
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.25)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.primaryLight.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.security_rounded,
                      color: AppColors.primaryLight,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _usesNativeBiometrics
                            ? 'StepQuest utilise le Face ID / capteur biométrique natif de votre téléphone. Aucune image de votre visage n\'est enregistrée ni partagée par l\'application.'
                            : 'StepQuest utilise un réseau neuronal pour générer une empreinte vectorielle 128D stockée de manière sécurisée. Vos données faciales ne sont jamais partagées.',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tester Face ID
              AppButton(
                label: 'Tester le scanner Face ID',
                icon: Icons.face_rounded,
                onPressed: _handleTestBiometrics,
              ),
              const SizedBox(height: 12),

              // Sauvegarder
              AppButton.secondary(
                label: 'Enregistrer les préférences',
                isLoading: _isSaving,
                onPressed: _handleSavePreferences,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
