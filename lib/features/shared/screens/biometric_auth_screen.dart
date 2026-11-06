import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';

// Import conditionnel Web pour HtmlElementView
import '../../user/screens/face_enrollment_screen_web.dart'
    if (dart.library.io) '../../user/screens/face_enrollment_screen_stub.dart';

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
  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  bool _isVerifying = false;
  bool _cameraActive = false;
  bool? _isSuccess;
  String _statusMessage = '';
  Timer? _autoScanTimer;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.08, end: 0.90).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    if (widget.type == BiometricType.face) {
      _statusMessage = 'Démarrage de la reconnaissance faciale...';
      // Démarrer la caméra automatiquement après le premier frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startCameraAndPrepare();
      });
    } else {
      _statusMessage = 'Placez votre doigt sur le capteur d\'empreinte.';
    }
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _animController.dispose();
    if (widget.type == BiometricType.face) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // ignore: use_build_context_synchronously
        context.faceRecognition.stopCamera();
      });
    }
    super.dispose();
  }

  /// Démarre la caméra automatiquement et prépare la détection faciale
  Future<void> _startCameraAndPrepare() async {
    if (!mounted) return;

    setState(() {
      _isVerifying = false;
      _cameraActive = false;
      _statusMessage = 'Initialisation de la caméra...';
    });

    final faceService = context.faceRecognition;
    final camOk = await faceService.startCamera();

    if (!mounted) return;

    setState(() {
      _cameraActive = camOk;
      _isVerifying = false;
      _statusMessage = camOk
          ? 'Visage détecté dans le cadre. Vérification...'
          : 'Caméra indisponible. Vérifiez vos autorisations.';
    });

    if (camOk) {
      // Déclenchement automatique de la capture après 1.4s (comme Face ID Apple)
      _autoScanTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && !_isVerifying && _isSuccess == null) {
          _captureAndVerifyFace();
        }
      });
    }
  }

  /// Capture la photo et valide l'empreinte faciale
  Future<void> _captureAndVerifyFace() async {
    if (_isVerifying || !mounted) return;

    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = 'Analyse biométrique en cours...';
    });

    final faceService = context.faceRecognition;
    final result = await faceService.scanFace();

    if (!mounted) return;

    if (!result.success || result.faceEmbeddingJson == null) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = result.message.isNotEmpty
            ? result.message
            : 'Aucun visage net détecté. Rapprochez-vous et réessayez.';
      });
      return;
    }

    final targetUser = widget.targetEmail != null
        ? context.users.findByEmail(widget.targetEmail!)
        : (context.auth.currentUser ??
            (context.users.allUsers.isNotEmpty
                ? context.users.allUsers.first
                : null));

    bool match = true;
    int confidence = 96;

    if (targetUser != null && targetUser.hasFaceRegistered) {
      final comp = faceService.compareFaces(
        storedEmbedding: targetUser.faceEmbedding!,
        liveEmbedding: result.faceEmbeddingJson!,
      );
      match = comp.isMatch;
      confidence = comp.confidencePercentage;
    }

    if (match) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
        _statusMessage = '✓ Visage reconnu ($confidence%) ! Connexion en cours...';
      });

      await faceService.stopCamera();

      if (!widget.isSimulationTestOnly && mounted) {
        await context.auth.loginWithBiometrics(
          type: widget.type,
          userState: context.users,
          notificationState: context.notifications,
          biometricService: context.biometrics,
          targetEmail: widget.targetEmail,
        );
      }

      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage =
            'Visage non reconnu ($confidence% de similarité). Veuillez vous replacer au centre.';
      });
    }
  }

  /// Simulation d'authentification pour les tests et l'onboarding
  Future<void> _triggerSimulatedScan({required bool succeed}) async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = widget.type == BiometricType.fingerprint
          ? 'Lecture de l\'empreinte...'
          : 'Analyse biométrique faciale...';
    });

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;

    if (succeed) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
        _statusMessage = 'Authentification biométrique réussie !';
      });

      if (!widget.isSimulationTestOnly) {
        await context.auth.loginWithBiometrics(
          type: widget.type,
          userState: context.users,
          notificationState: context.notifications,
          biometricService: context.biometrics,
          targetEmail: widget.targetEmail,
        );
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = 'Biométrie non reconnue. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color accentColor = AppColors.primary;
    if (_isSuccess == true) {
      accentColor = AppColors.secondary;
    } else if (_isSuccess == false) {
      accentColor = AppColors.error;
    }

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Visual Scanner (Caméra ou Empreinte) ───────────────────
                  Center(
                    child: widget.type == BiometricType.face
                        ? _buildFaceCameraWidget(accentColor)
                        : _buildFingerprintWidget(accentColor),
                  ),
                  const SizedBox(height: 24),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    widget.type == BiometricType.face
                        ? 'Reconnaissance Faciale'
                        : 'Authentification biométrique',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Message de statut réactif ─────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.navyCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isSuccess == true
                            ? AppColors.secondary.withValues(alpha: 0.5)
                            : _isSuccess == false
                                ? AppColors.error.withValues(alpha: 0.5)
                                : const Color(0xFF334155),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isVerifying
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
                                  : AppColors.primaryLight,
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
                                      : Colors.white70,
                              height: 1.35,
                            ),
                          ),
                        ),
                        if (_isVerifying)
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
                  const SizedBox(height: 24),

                  // ── Bouton principal d'action ─────────────────────────────
                  if (widget.type == BiometricType.face) ...[
                    AppButton(
                      label: _isSuccess == true
                          ? 'Visage validé'
                          : _isVerifying
                              ? 'Analyse en cours...'
                              : 'Vérifier mon visage',
                      icon: Icons.face_retouching_natural_rounded,
                      isLoading: _isVerifying,
                      onPressed: (_isVerifying || _isSuccess == true)
                          ? null
                          : _captureAndVerifyFace,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // ── Bouton Annuler / Mot de passe ─────────────────────────
                  AppButton.secondary(
                    label: 'Se connecter par mot de passe',
                    icon: Icons.lock_outline_rounded,
                    onPressed: () => Navigator.of(context).pop(false),
                  ),

                  // ── Section Simulation (visible UNIQUEMENT en mode test) ──
                  if (widget.isSimulationTestOnly) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.navyCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'SIMULATION DE TEST',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Succès',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: _isVerifying
                                      ? null
                                      : () => _triggerSimulatedScan(succeed: true),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFFCA5A5),
                                    side: const BorderSide(
                                        color: Color(0xFF64748B)),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Échec',
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: _isVerifying
                                      ? null
                                      : () => _triggerSimulatedScan(succeed: false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Scanner biométrique facial moderne avec caméra intégrée et laser animé
  Widget _buildFaceCameraWidget(Color glowColor) {
    return Container(
      width: 230,
      height: 280,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: glowColor, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Flux Caméra ───────────────────────────────────────────────────
          if (kIsWeb)
            buildCameraView()
          else
            const Center(
              child: Icon(
                Icons.face_rounded,
                size: 70,
                color: Colors.white24,
              ),
            ),

          // ── Ovale guide facial ────────────────────────────────────────────
          Center(
            child: Container(
              width: 160,
              height: 215,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(110),
                border: Border.all(
                  color: _isSuccess == true
                      ? AppColors.secondary
                      : _isSuccess == false
                          ? AppColors.error
                          : Colors.white.withValues(alpha: 0.4),
                  width: 2.2,
                ),
              ),
            ),
          ),

          // ── Ligne laser de balayage animé ─────────────────────────────────
          if (_isVerifying || _cameraActive)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, _) {
                return Positioned(
                  top: 270 * _scanAnimation.value,
                  left: 18,
                  right: 18,
                  child: Container(
                    height: 2.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          glowColor,
                          glowColor,
                          Colors.transparent,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.8),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          // ── Coins de visée Face ID ────────────────────────────────────────
          ..._buildCornerCrosshairs(glowColor),

          // ── Overlay de succès ─────────────────────────────────────────────
          if (_isSuccess == true)
            Container(
              color: AppColors.secondary.withValues(alpha: 0.25),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 72,
                  color: AppColors.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Icône d'empreinte digitale animée
  Widget _buildFingerprintWidget(Color glowColor) {
    return AnimatedBuilder(
      animation: _scanAnimation,
      builder: (context, _) {
        return Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: glowColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: glowColor.withValues(alpha: 0.5),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.35),
                blurRadius: 32,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Center(
            child: _isSuccess == true
                ? const Icon(Icons.check_circle_rounded,
                    size: 64, color: AppColors.secondary)
                : _isSuccess == false
                    ? const Icon(Icons.error_outline_rounded,
                        size: 64, color: AppColors.error)
                    : Icon(
                        Icons.fingerprint_rounded,
                        size: 70,
                        color: glowColor,
                      ),
          ),
        );
      },
    );
  }

  /// 4 coins de ciblage Face ID
  List<Widget> _buildCornerCrosshairs(Color color) {
    const size = 18.0;
    const thickness = 2.5;
    const offset = 12.0;

    Widget corner({
      bool top = false,
      bool bottom = false,
      bool left = false,
      bool right = false,
    }) {
      return Positioned(
        top: top ? offset : null,
        bottom: bottom ? offset : null,
        left: left ? offset : null,
        right: right ? offset : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border(
              top: top
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              bottom: bottom
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              left: left
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
              right: right
                  ? BorderSide(color: color, width: thickness)
                  : BorderSide.none,
            ),
          ),
        ),
      );
    }

    return [
      corner(top: true, left: true),
      corner(top: true, right: true),
      corner(bottom: true, left: true),
      corner(bottom: true, right: true),
    ];
  }
}
