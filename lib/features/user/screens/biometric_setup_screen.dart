import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../shared/screens/biometric_auth_screen.dart';
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
  late bool _fingerprintEnabled;
  late bool _faceEnabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.auth.currentUser;
    _fingerprintEnabled = user?.biometricFingerprintEnabled ?? true;
    _faceEnabled = user?.biometricFaceEnabled ?? true;
  }

  Future<void> _handleTestBiometrics() async {
    final type = _fingerprintEnabled
        ? BiometricType.fingerprint
        : BiometricType.face;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BiometricAuthScreen(
          type: type,
          isSimulationTestOnly: true,
        ),
      ),
    );
  }

  void _handleSavePreferences() {
    setState(() {
      _isSaving = true;
    });

    final currentUser = context.auth.currentUser;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        biometricFingerprintEnabled: _fingerprintEnabled,
        biometricFaceEnabled: _faceEnabled,
      );

      context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Préférences biométriques enregistrées.'),
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
    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Authentification biométrique',
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
                'Authentification biométrique',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choisissez vos méthodes d\'authentification biométrique.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Method 1: Fingerprint Card
              _buildBiometricCard(
                icon: Icons.fingerprint_rounded,
                title: 'Empreinte digitale',
                subtitle: 'Sécurisé et rapide',
                isEnabled: _fingerprintEnabled,
                isDark: isDark,
                onChanged: (val) {
                  setState(() {
                    _fingerprintEnabled = val;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Method 2: Face ID Card
              _buildBiometricCard(
                icon: Icons.face_rounded,
                title: 'Reconnaissance faciale',
                subtitle: 'Reconnaissance 3D',
                isEnabled: _faceEnabled,
                isDark: isDark,
                onChanged: (val) {
                  setState(() {
                    _faceEnabled = val;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Informational card matching mockup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
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
                      Icons.info_outline_rounded,
                      color: AppColors.primaryLight,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vous pouvez activer la biométrie pour une connexion plus rapide et plus sécurisée.',
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

              // Test Button matching mockup Screen 05
              AppButton(
                label: 'Tester la biométrie',
                onPressed: _handleTestBiometrics,
              ),
              const SizedBox(height: 12),

              // Save preferences button
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

  Widget _buildBiometricCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    required bool isDark,
    required ValueChanged<bool> onChanged,
  }) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                  : AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isEnabled
                            ? AppColors.secondary
                            : AppColors.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      isEnabled ? 'Activé' : 'Désactivé',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isEnabled
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
            value: isEnabled,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primarySoft,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
