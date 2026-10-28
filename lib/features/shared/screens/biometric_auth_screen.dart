import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';

class BiometricAuthScreen extends StatefulWidget {
  final BiometricType type;
  final String? targetEmail;
  final bool isSimulationTestOnly;

  const BiometricAuthScreen({
    super.key,
    this.type = BiometricType.fingerprint,
    this.targetEmail,
    this.isSimulationTestOnly = false,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isVerifying = false;
  bool? _isSuccess;
  String _statusMessage = 'Placez votre doigt sur le capteur pour continuer.';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.type == BiometricType.face) {
      _statusMessage = 'Positionnez votre visage devant la caméra.';
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerScan({required bool succeed}) async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = widget.type == BiometricType.fingerprint
          ? 'Lecture de l\'empreinte en cours...'
          : 'Analyse biométrique faciale en cours...';
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    if (succeed) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
        _statusMessage = 'Authentification biométrique réussie !';
      });

      if (!widget.isSimulationTestOnly) {
        // Authenticate the user in AuthState
        await context.auth.loginWithBiometrics(
          type: widget.type,
          userState: context.users,
          notificationState: context.notifications,
          biometricService: context.biometrics,
          targetEmail: widget.targetEmail,
        );
      }

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage =
            'Empreinte non reconnue. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color glowColor = AppColors.primary;
    if (_isSuccess == true) {
      glowColor = AppColors.secondary;
    } else if (_isSuccess == false) {
      glowColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Biometric Scanner matching mockup Screen 17
              Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isVerifying ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: glowColor.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: glowColor.withValues(alpha: 0.4),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(alpha: 0.35),
                              blurRadius: 36,
                              spreadRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: _isSuccess == true
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  size: 68,
                                  color: AppColors.secondary,
                                )
                              : _isSuccess == false
                                  ? const Icon(
                                      Icons.error_outline_rounded,
                                      size: 68,
                                      color: AppColors.error,
                                    )
                                  : Icon(
                                      widget.type == BiometricType.fingerprint
                                          ? Icons.fingerprint_rounded
                                          : Icons.face_rounded,
                                      size: 72,
                                      color: AppColors.primaryLight,
                                    ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Authentification requise',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _isSuccess == false
                      ? const Color(0xFFFCA5A5)
                      : _isSuccess == true
                          ? const Color(0xFF6EE7B7)
                          : const Color(0xFF94A3B8),
                  height: 1.4,
                ),
              ),
              const Spacer(),

              // Simulation Controls
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.navyCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'CONTRÔLES DE SIMULATION BIOMÉTRIQUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.touch_app, size: 16),
                            label: const Text('Tester succès',
                                style: TextStyle(fontSize: 13)),
                            onPressed: _isVerifying
                                ? null
                                : () => _triggerScan(succeed: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFCA5A5),
                              side: const BorderSide(color: Color(0xFF64748B)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.block, size: 16),
                            label: const Text('Tester échec',
                                style: TextStyle(fontSize: 13)),
                            onPressed: _isVerifying
                                ? null
                                : () => _triggerScan(succeed: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              AppButton.secondary(
                label: 'Annuler',
                onPressed: () => Navigator.of(context).pop(false),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
