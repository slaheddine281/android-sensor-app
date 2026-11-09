import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';

class FingerprintEnrollmentScreen extends StatefulWidget {
  const FingerprintEnrollmentScreen({super.key});

  @override
  State<FingerprintEnrollmentScreen> createState() =>
      _FingerprintEnrollmentScreenState();
}

class _FingerprintEnrollmentScreenState extends State<FingerprintEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  MockBiometricService? _biometricService;
  bool _isProcessing = false;
  bool? _isSuccess;
  bool _isLockedOut = false;
  String _statusMessage =
      'Appuyez sur "Enregistrer mon empreinte" puis posez votre doigt sur le capteur.';

  bool get _usesNativeBiometrics {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _biometricService = context.biometrics;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleEnrollFingerprint() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _isSuccess = null;
      _isLockedOut = false;
      _statusMessage =
          'Posez votre doigt sur le capteur d\'empreinte du téléphone...';
    });

    final result = await _biometricService?.authenticate(
          type: BiometricType.fingerprint,
          reason: 'Enregistrez votre empreinte digitale pour sécuriser votre compte StepQuest',
        ) ??
        BiometricAuthResult.unavailable;

    if (!mounted) return;

    if (result != BiometricAuthResult.success) {
      final locked = result == BiometricAuthResult.lockedOut;
      setState(() {
        _isProcessing = false;
        _isSuccess = false;
        _isLockedOut = locked;
        _statusMessage = MockBiometricService.messageFor(result);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(MockBiometricService.messageFor(result)),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final currentUser = context.auth.currentUser;
    if (currentUser != null) {
      final updated = currentUser.copyWith(
        biometricFingerprintEnabled: true,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );

      // Lie le compte à cet appareil pour l'authentification biométrique
      await _biometricService?.bindAccountToDevice(currentUser.email);
      await _biometricService?.cacheBoundProfile(updated);
    }

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _statusMessage =
          '✓ Empreinte digitale enregistrée et activée avec succès sur votre profil !';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empreinte digitale enregistrée avec succès dans votre profil !'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDirectActivation() async {
    final currentUser = context.auth.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isProcessing = true;
      _isSuccess = null;
      _statusMessage = 'Activation de l\'empreinte sur votre profil...';
    });

    final updated = currentUser.copyWith(
      biometricFingerprintEnabled: true,
    );

    await context.auth.updateCurrentProfile(
      updatedUser: updated,
      userState: context.users,
      notificationState: context.notifications,
    );

    await _biometricService?.bindAccountToDevice(currentUser.email);
    await _biometricService?.cacheBoundProfile(updated);

    if (!mounted) return;
    setState(() {
      _isProcessing = false;
      _isSuccess = true;
      _isLockedOut = false;
      _statusMessage =
          '✓ Empreinte digitale activée avec succès sur votre profil !';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empreinte digitale activée avec succès dans votre profil !'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleRemoveFingerprint() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer mon empreinte'),
        content: const Text(
          'Voulez-vous désactiver l\'authentification par empreinte digitale sur votre profil ?',
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
        biometricFingerprintEnabled: false,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );

      // Si Face ID n'est pas activé non plus, on efface la liaison locale
      if (!updated.biometricFaceEnabled && !updated.hasFaceRegistered) {
        await _biometricService?.clearDeviceBinding();
      } else {
        await _biometricService?.cacheBoundProfile(updated);
      }
    }

    if (!mounted) return;

    setState(() {
      _isSuccess = null;
      _statusMessage = 'Empreinte digitale désactivée de votre profil.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empreinte digitale désactivée.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser;
    final hasFingerprint = user?.biometricFingerprintEnabled ?? false;
    final accentColor = hasFingerprint ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(title: 'Empreinte Digitale'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Carte d'état Empreinte ──────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: hasFingerprint
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.fingerprint_rounded,
                            color: accentColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasFingerprint
                                    ? 'Empreinte configurée'
                                    : 'Aucune empreinte enregistrée',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                hasFingerprint
                                    ? 'Active — Déverrouillez votre compte d\'un simple toucher.'
                                    : 'Enregistrez votre empreinte pour activer la connexion rapide.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasFingerprint)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'ACTIF',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.secondary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Scanner Visuel Empreinte avec cercles pulsants ────────
                  Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale = _pulseAnimation.value;
                        Color glowColor = accentColor;
                        if (_isSuccess == true) {
                          glowColor = AppColors.secondary;
                        } else if (_isSuccess == false) {
                          glowColor = AppColors.error;
                        }

                        return Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0F172A),
                            border: Border.all(
                              color: glowColor,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.35 * scale),
                                blurRadius: 36 * scale,
                                spreadRadius: 6 * scale,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Anneau d'onde extérieure
                                Container(
                                  width: 160 * scale,
                                  height: 160 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: glowColor.withValues(alpha: 0.25),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                // Icône empreinte
                                Icon(
                                  Icons.fingerprint_rounded,
                                  size: 96,
                                  color: _isSuccess == true
                                      ? AppColors.secondary
                                      : _isSuccess == false
                                          ? AppColors.error
                                          : glowColor,
                                ),
                                if (_isProcessing)
                                  const SizedBox(
                                    width: 180,
                                    height: 180,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Message de statut ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess == true
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : _isSuccess == false
                                ? AppColors.error.withValues(alpha: 0.5)
                                : isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isProcessing
                              ? Icons.sync_rounded
                              : _isSuccess == true
                                  ? Icons.check_circle_rounded
                                  : _isSuccess == false
                                      ? Icons.error_outline_rounded
                                      : Icons.info_outline_rounded,
                          color: _isSuccess == true
                              ? AppColors.secondary
                              : _isSuccess == false
                                  ? AppColors.error
                                  : accentColor,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _statusMessage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _isSuccess == false
                                  ? const Color(0xFFFCA5A5)
                                  : _isSuccess == true
                                      ? const Color(0xFF6EE7B7)
                                      : isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (_isProcessing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Bannière d'aide en cas de verrouillage Android ─────────
                  if (_isLockedOut) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(
                            children: [
                              Icon(Icons.lock_clock_rounded,
                                  color: AppColors.error, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Sécurité Android : Capteur bloqué 30s',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.error,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Votre téléphone a détecté trop d\'essais consécutifs. Pour débloquer immédiatement :\n'
                            '1. Verrouillez l\'écran de votre téléphone avec le bouton d\'alimentation.\n'
                            '2. Déverrouillez-le avec votre code PIN ou schéma habituel.\n'
                            '3. Revenez dans l\'application et relancez l\'enregistrement.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF991B1B),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // ── Bouton principal d'enrôlement ─────────────────────────
                  AppButton(
                    label: hasFingerprint
                        ? 'Mettre à jour mon empreinte'
                        : 'Enregistrer mon empreinte digitale',
                    icon: Icons.fingerprint_rounded,
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _handleEnrollFingerprint,
                  ),
                  const SizedBox(height: 10),

                  if (_isLockedOut || _isSuccess == false) ...[
                    AppButton.secondary(
                      label: 'Activer l\'accès empreinte pour ce compte',
                      icon: Icons.check_circle_outline_rounded,
                      onPressed: _isProcessing ? null : _handleDirectActivation,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Bouton Supprimer (si configurée) ─────────────────────
                  if (hasFingerprint) ...[
                    AppButton.destructive(
                      label: 'Supprimer mon empreinte',
                      icon: Icons.delete_outline_rounded,
                      onPressed: _isProcessing ? null : _handleRemoveFingerprint,
                    ),
                    const SizedBox(height: 10),
                  ],

                  // ── Bouton Retour ─────────────────────────────────────────
                  AppButton.secondary(
                    label: 'Retour',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

