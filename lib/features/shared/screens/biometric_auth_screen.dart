import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_biometric_service.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';

// Import conditionnel Web uniquement pour HtmlElementView
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
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isVerifying = false;
  bool? _isSuccess;
  bool _cameraOpen = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();

    _statusMessage = widget.type == BiometricType.face
        ? 'Appuyez sur "Scanner" pour démarrer la reconnaissance faciale.'
        : 'Placez votre doigt sur le capteur pour continuer.';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // Arrêter la caméra proprement à la fermeture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: use_build_context_synchronously
      context.faceRecognition.stopCamera();
    });
    super.dispose();
  }

  Future<void> _triggerRealCameraFaceScan() async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _cameraOpen = false;
      _statusMessage = 'Ouverture de la caméra...';
    });

    final faceService = context.faceRecognition;
    final camOk = await faceService.startCamera();

    if (!mounted) return;

    setState(() {
      _cameraOpen = camOk;
      _statusMessage = camOk
          ? 'Caméra active. Regardez l\'objectif puis appuyez sur "Capturer".'
          : kIsWeb
            ? 'Impossible d\'accéder à la caméra.'
            : 'La reconnaissance faciale est disponible dans la version Web uniquement.';
      if (!camOk) _isVerifying = false;
    });
  }

  Future<void> _captureAndVerifyFace() async {
    if (!mounted) return;
    setState(() {
      _statusMessage = 'Analyse du visage en cours...';
    });

    final faceService = context.faceRecognition;
    final result = await faceService.scanFace();

    if (!mounted) return;

    await faceService.stopCamera();

    if (!mounted) return;
    setState(() => _cameraOpen = false);

    if (!result.success || result.faceEmbeddingJson == null) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = result.message;
      });
      return;
    }

    final targetUser = widget.targetEmail != null
        ? context.users.findByEmail(widget.targetEmail!)
        : (context.auth.currentUser ??
            (context.users.allUsers.isNotEmpty
                ? context.users.allUsers.first
                : null));

    if (targetUser == null || !targetUser.hasFaceRegistered) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = 'Aucun visage n’est enregistré pour ce compte.';
      });
      return;
    }

    final comp = faceService.compareFaces(
      storedEmbedding: targetUser.faceEmbedding!,
      liveEmbedding: result.faceEmbeddingJson!,
    );
    final match = comp.isMatch;
    final confidence = comp.confidencePercentage;

    if (match) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
        _statusMessage =
            'Visage reconnu ($confidence% de similarité) ! Connexion...';
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

      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage =
            'Visage non reconnu ($confidence% de similarité). Réessayez.';
      });
    }
  }

  Future<void> _triggerSimulatedScan({required bool succeed}) async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = widget.type == BiometricType.fingerprint
          ? 'Lecture de l\'empreinte...'
          : 'Analyse biométrique faciale...';
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
        _statusMessage = 'Biométrie non reconnue. Veuillez réessayer.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color glowColor = AppColors.primary;
    if (_isSuccess == true) glowColor = AppColors.secondary;
    if (_isSuccess == false) glowColor = AppColors.error;

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

              // ── Icône / Caméra principale ──────────────────────────────
              if (widget.type == BiometricType.face)
                _buildFaceCameraWidget()
              else
                _buildBiometricIcon(glowColor),

              const SizedBox(height: 32),

              // ── Titre ──────────────────────────────────────────────────
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

              // ── Message de statut ──────────────────────────────────────
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

              // ── Boutons de scan facial réel ────────────────────────────
              if (widget.type == BiometricType.face) ...[
                if (!_cameraOpen)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        'Scanner mon visage',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      onPressed:
                          _isVerifying ? null : _triggerRealCameraFaceScan,
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.face_retouching_natural_rounded),
                      label: const Text(
                        'Capturer mon visage',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      onPressed:
                          _isVerifying ? null : _captureAndVerifyFace,
                    ),
                  ),
                const SizedBox(height: 14),
              ],

              // ── Contrôles de simulation (mode test) ────────────────────
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
                      'SIMULATION BIOMÉTRIQUE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF64748B),
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
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 16),
                            label: const Text('Succès',
                                style: TextStyle(fontSize: 13)),
                            onPressed: _isVerifying
                                ? null
                                : () => _triggerSimulatedScan(succeed: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFCA5A5),
                              side: const BorderSide(
                                  color: Color(0xFF64748B)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon:
                                const Icon(Icons.cancel_outlined, size: 16),
                            label: const Text('Échec',
                                style: TextStyle(fontSize: 13)),
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
              const SizedBox(height: 14),

              // ── Bouton annuler ─────────────────────────────────────────
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

  /// Icône biométrique animée (pour empreinte ou quand caméra fermée)
  Widget _buildBiometricIcon(Color glowColor) {
    return AnimatedBuilder(
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
                  ? const Icon(Icons.check_circle_rounded,
                      size: 68, color: AppColors.secondary)
                  : _isSuccess == false
                      ? const Icon(Icons.error_outline_rounded,
                          size: 68, color: AppColors.error)
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
    );
  }

  /// Fenêtre caméra intégrée pour la reconnaissance faciale
  Widget _buildFaceCameraWidget() {
    return Container(
      width: 220,
      height: 270,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.secondary, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withValues(alpha: 0.35),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Flux caméra
          if (kIsWeb) buildCameraView(),

          // Ovale guide
          Center(
            child: Container(
              width: 155,
              height: 205,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.85),
                  width: 2,
                ),
              ),
            ),
          ),

          // Coins de visée
          ..._miniCorners(),
        ],
      ),
    );
  }

  List<Widget> _miniCorners() {
    const c = AppColors.secondary;
    const t = 2.5;
    const s = 16.0;
    const o = 10.0;
    return [
      Positioned(top: o, left: o, child: _corner(s, t, c, top: true, left: true)),
      Positioned(top: o, right: o, child: _corner(s, t, c, top: true, right: true)),
      Positioned(bottom: o, left: o, child: _corner(s, t, c, bottom: true, left: true)),
      Positioned(bottom: o, right: o, child: _corner(s, t, c, bottom: true, right: true)),
    ];
  }

  Widget _corner(double size, double thick, Color color,
      {bool top = false, bool bottom = false, bool left = false, bool right = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: color, width: thick) : BorderSide.none,
          bottom: bottom ? BorderSide(color: color, width: thick) : BorderSide.none,
          left: left ? BorderSide(color: color, width: thick) : BorderSide.none,
          right: right ? BorderSide(color: color, width: thick) : BorderSide.none,
        ),
      ),
    );
  }
}
