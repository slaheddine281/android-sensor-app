import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
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
        _faceEnabled = user.biometricFaceEnabled || user.hasFaceRegistered;
      }
      _isInitialized = true;
    }
  }

  Future<void> _handleToggleFace(bool value) async {
    setState(() {
      _faceEnabled = value;
    });

    final currentUser = context.auth.currentUser;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        biometricFaceEnabled: value,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'Face ID activé avec succès.'
              : 'Face ID désactivé.',
        ),
        backgroundColor: value ? AppColors.secondary : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDeleteFace() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon visage'),
        content: const Text(
          'Voulez-vous supprimer les données biométriques de votre visage ? Vous ne pourrez plus vous connecter avec Face ID.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final currentUser = context.auth.currentUser;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        faceEmbedding: null,
        biometricFaceEnabled: false,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );

      await context.biometrics.clearDeviceBinding();
    }

    if (!mounted) return;

    setState(() {
      _faceEnabled = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données Face ID supprimées avec succès.'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                                'Face ID',
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
                                                ? 'Face ID actif'
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
                          onChanged: _handleToggleFace,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 14),

                    // Bouton Enrôlement / Scanner Visage
                    AppButton(
                      label: _usesNativeBiometrics
                          ? (hasFaceRegistered
                              ? 'Mettre à jour mon Face ID'
                              : 'Activer Face ID')
                          : (hasFaceRegistered
                              ? 'Recalibrer / Mettre à jour mon visage'
                              : 'Scanner et enregistrer mon visage'),
                      icon: _usesNativeBiometrics
                          ? Icons.face_retouching_natural_rounded
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

                    if (hasFaceRegistered) ...[
                      const SizedBox(height: 10),
                      AppButton.destructive(
                        label: 'Supprimer mon visage enregistré',
                        icon: Icons.delete_outline_rounded,
                        onPressed: _handleDeleteFace,
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
                            ? 'StepQuest utilise le Face ID / capteur biométrique natif de votre téléphone. Aucune image de votre visage n\'est partagée.'
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
            ],
          ),
        ),
      ),
    );
  }
}
