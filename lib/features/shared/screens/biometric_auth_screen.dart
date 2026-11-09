import 'dart:async';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../services/face_recognition_service.dart';
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
    this.type = BiometricType.face,
    this.targetEmail,
    this.isSimulationTestOnly = false,
  });

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  static const Duration _cameraTimeout = Duration(seconds: 12);
  static const Duration _scanTimeout = Duration(seconds: 20);

  late AnimationController _animController;
  late Animation<double> _scanAnimation;

  FaceRecognitionService? _faceService;
  MockBiometricService? _biometricService;

  bool _isVerifying = false;
  bool _cameraActive = false;
  bool? _isSuccess;
  String _statusMessage = '';
  Timer? _autoScanTimer;
  bool _autoScanStarted = false;

  /// Sur téléphone (Android/iOS), on utilise le capteur biométrique natif.
  /// Sur le Web, on garde le scan facial IA via la webcam.
  /// L'empreinte digitale utilise TOUJOURS le natif (jamais la caméra web).
  bool get _usesNativeBiometrics {
    if (widget.type == BiometricType.fingerprint) {
      // L'empreinte est toujours gérée par le capteur natif (local_auth)
      return !kIsWeb;
    }
    // Face ID : web → caméra IA, mobile → capteur natif
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

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

    _statusMessage = _usesNativeBiometrics
        ? (widget.type == BiometricType.fingerprint
            ? 'Posez votre doigt sur le capteur d\'empreinte du téléphone...'
            : 'Présentez votre visage au capteur biométrique du téléphone...')
        : 'Démarrage de la reconnaissance faciale Face ID...';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_usesNativeBiometrics) {
        _authenticateWithDevice();
      } else {
        _startCameraAndPrepare();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _faceService = context.faceRecognition;
    _biometricService = context.biometrics;
  }

  @override
  void dispose() {
    _autoScanTimer?.cancel();
    _animController.dispose();
    // Ne jamais utiliser `context` ici : le widget est déjà démonté.
    // On arrête explicitement le flux caméra pour éviter qu'il continue
    // à tourner en arrière-plan après la fermeture de l'écran.
    _faceService?.stopCamera();
    super.dispose();
  }

  // ── Mode natif (Android / iOS) ──────────────────────────────────────────────

  Future<void> _authenticateWithDevice() async {
    if (_isVerifying || _isSuccess == true || !mounted) return;

    // On détermine d'abord le compte concerné : la biométrie système prouve
    // seulement l'identité du propriétaire de l'appareil, pas le compte.
    final accountEmail = await _resolveNativeAccountEmail();
    if (!mounted || accountEmail == null) return;

    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage =
          'Authentification biométrique en cours... Validez avec ${widget.type == BiometricType.fingerprint ? 'votre empreinte' : 'votre visage ou votre empreinte'}.';
    });

    final result = await _biometricService?.authenticate(
          type: widget.type,
          reason: 'Authentifiez-vous pour accéder à StepQuest',
        ) ??
        BiometricAuthResult.unavailable;

    if (!mounted) return;

    if (result != BiometricAuthResult.success) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = MockBiometricService.messageFor(result);
      });
      return;
    }

    setState(() {
      _isVerifying = false;
      _isSuccess = true;
      _statusMessage = '✓ Identité confirmée ! Connexion en cours...';
    });

    await _completeLogin(targetEmail: accountEmail);
  }

  /// Retourne l'e-mail du compte à connecter, ou `null` en affichant la raison.
  ///
  /// Sur mobile, le Face ID natif est lié au compte enrôlé sur CET appareil.
  /// Sans cette vérification, il suffirait de saisir l'e-mail d'autrui puis de
  /// valider son propre doigt pour ouvrir le compte d'un autre utilisateur.
  Future<String?> _resolveNativeAccountEmail() async {
    final sessionUser = context.auth.currentUser;
    final typedEmail = (widget.targetEmail ?? '').trim();

    if (sessionUser != null) {
      if (typedEmail.isNotEmpty &&
          typedEmail.toLowerCase() !=
              sessionUser.email.trim().toLowerCase()) {
        if (mounted) {
          setState(() {
            _isSuccess = false;
            _statusMessage =
                'Cet appareil est déjà connecté avec ${sessionUser.email}.';
          });
        }
        return null;
      }
      return sessionUser.email;
    }

    final boundEmail = await _biometricService?.boundAccountEmail();
    if (!mounted) return null;

    if (boundEmail == null || boundEmail.isEmpty) {
      setState(() {
        _isSuccess = false;
        _statusMessage = widget.type == BiometricType.fingerprint
            ? 'L\'empreinte digitale n\'est pas activée sur cet appareil. Connectez-vous avec votre mot de passe, puis activez l\'empreinte dans les paramètres.'
            : 'Face ID n\'est pas activé sur cet appareil. Connectez-vous avec votre mot de passe, puis activez Face ID dans les paramètres.';
      });
      return null;
    }

    if (typedEmail.isNotEmpty && typedEmail.toLowerCase() != boundEmail) {
      setState(() {
        _isSuccess = false;
        _statusMessage = widget.type == BiometricType.fingerprint
            ? 'Cette empreinte est associée à un autre compte sur cet appareil.'
            : 'Ce Face ID est associé à un autre compte sur cet appareil.';
      });
      return null;
    }

    return boundEmail;
  }

  Future<void> _completeLogin({String? targetEmail}) async {
    if (!widget.isSimulationTestOnly) {
      final loggedIn = await context.auth.loginWithBiometrics(
        type: widget.type,
        userState: context.users,
        notificationState: context.notifications,
        biometricService: context.biometrics,
        targetEmail: (targetEmail ?? widget.targetEmail)?.trim(),
        // La biométrie a déjà été validée juste avant.
        biometricVerified: true,
      );

      if (!mounted) return;

      if (!loggedIn) {
        setState(() {
          _isVerifying = false;
          _isSuccess = false;
          _statusMessage = context.auth.errorMessage ??
              (widget.type == BiometricType.fingerprint
                  ? 'Connexion par empreinte impossible. Utilisez votre mot de passe.'
                  : 'Connexion Face ID impossible. Utilisez votre mot de passe.');
        });
        return;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop(true);
  }

  // ── Mode Web (scan facial IA) ───────────────────────────────────────────────

  /// Démarre la caméra automatiquement et prépare la détection faciale
  Future<void> _startCameraAndPrepare() async {
    if (!mounted || _usesNativeBiometrics) return;

    setState(() {
      _isVerifying = false;
      _cameraActive = false;
      _statusMessage = 'Initialisation de la caméra...';
    });

    final faceService = _faceService ?? context.faceRecognition;

    bool camOk;
    try {
      camOk = await faceService.startCamera().timeout(_cameraTimeout);
    } on TimeoutException {
      camOk = false;
    } catch (_) {
      camOk = false;
    }

    if (!mounted) return;

    setState(() {
      _cameraActive = camOk;
      _isVerifying = false;
      _statusMessage = camOk
          ? 'Placez votre visage au centre du cadre. Vérification...'
          : 'Caméra indisponible. Vérifiez les autorisations de la caméra.';
    });

    if (camOk && !_autoScanStarted) {
      _autoScanStarted = true;
      // Déclenchement automatique de la capture après 1.4s (comme Face ID)
      _autoScanTimer = Timer(const Duration(milliseconds: 1400), () {
        if (mounted && !_isVerifying && _isSuccess == null) {
          _captureAndVerifyFace();
        }
      });
    }
  }

  /// Capture la photo et valide l'empreinte faciale
  Future<void> _captureAndVerifyFace() async {
    if (_isVerifying || !mounted || _usesNativeBiometrics) return;

    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = 'Analyse biométrique en cours...';
    });

    final faceService = _faceService ?? context.faceRecognition;

    // Un scan ne doit JAMAIS rester bloqué indéfiniment (surtout sur mobile).
    FaceDetectionResult result;
    try {
      result = await faceService.scanFace().timeout(_scanTimeout);
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage =
            'Le scan a pris trop de temps. Replacez votre visage et réessayez.';
      });
      return;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = 'Erreur pendant le scan : $e';
      });
      return;
    }

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

    final typedEmail = (widget.targetEmail ?? '').trim();
    AppUser? targetUser;
    if (typedEmail.isNotEmpty) {
      targetUser = context.users.findByEmail(typedEmail);
    } else {
      targetUser = context.auth.currentUser;
      // Aucun e-mail saisi : si un seul visage est enregistré, on l'utilise.
      if (targetUser == null) {
        final registered =
            context.users.allUsers.where((u) => u.hasFaceRegistered).toList();
        if (registered.length == 1) targetUser = registered.first;
      }
    }

    if (targetUser == null) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = typedEmail.isEmpty
            ? 'Saisissez votre adresse e-mail, puis relancez la reconnaissance faciale.'
            : 'Aucun compte ne correspond à cette adresse e-mail.';
      });
      return;
    }

    // Sécurité : sans visage enregistré, aucun scan ne peut être validé.
    if (!targetUser.hasFaceRegistered) {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage = 'Aucun visage n\'est enregistré pour ce compte.';
      });
      return;
    }

    final comp = faceService.compareFaces(
      storedEmbedding: targetUser.faceEmbedding!,
      liveEmbedding: result.faceEmbeddingJson!,
    );

    if (comp.isMatch) {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
        _statusMessage =
            '✓ Visage reconnu (${comp.confidencePercentage}%) ! Connexion en cours...';
      });

      await faceService.stopCamera();
      if (mounted) setState(() => _cameraActive = false);

      await _completeLogin(targetEmail: targetUser.email);
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = false;
        _statusMessage =
            'Visage non reconnu (${comp.confidencePercentage}% de similarité). Veuillez vous replacer au centre.';
      });
    }
  }

  /// Simulation d'authentification pour les tests et l'onboarding
  Future<void> _triggerSimulatedScan({required bool succeed}) async {
    setState(() {
      _isVerifying = true;
      _isSuccess = null;
      _statusMessage = 'Analyse biométrique faciale Face ID...';
    });

    await Future<void>.delayed(const Duration(milliseconds: 1000));
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
          targetEmail: (widget.targetEmail ?? '').trim().isEmpty
              ? null
              : widget.targetEmail!.trim(),
          biometricVerified: true,
        );
      }

      await Future<void>.delayed(const Duration(milliseconds: 600));
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
                  // ── Visual Scanner Face ID Caméra ─────────────────────────
                  Center(
                    child: _buildFaceCameraWidget(accentColor),
                  ),
                  const SizedBox(height: 24),

                  // ── Titre ──────────────────────────────────────────────────
                  Text(
                    widget.type == BiometricType.fingerprint
                        ? 'Empreinte Digitale'
                        : 'Reconnaissance Faciale Face ID',
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
                  if (widget.type == BiometricType.face || _usesNativeBiometrics) ...[
                    AppButton(
                      label: _isSuccess == true
                          ? (widget.type == BiometricType.fingerprint
                              ? 'Empreinte validée'
                              : 'Visage validé')
                          : _isVerifying
                              ? 'Analyse en cours...'
                              : _usesNativeBiometrics
                                  ? (widget.type == BiometricType.fingerprint
                                      ? 'Vérifier avec l\'empreinte'
                                      : 'Vérifier avec Face ID')
                                  : 'Vérifier mon visage',
                      icon: widget.type == BiometricType.fingerprint
                          ? Icons.fingerprint_rounded
                          : Icons.face_retouching_natural_rounded,
                      isLoading: _isVerifying,
                      onPressed: (_isVerifying || _isSuccess == true)
                          ? null
                          : _usesNativeBiometrics
                              ? _authenticateWithDevice
                              : _cameraActive
                                  ? _captureAndVerifyFace
                                  : _startCameraAndPrepare,
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
    // Pour l'empreinte digitale : affichage d'un widget dédié sans caméra
    if (widget.type == BiometricType.fingerprint) {
      return _buildFingerprintWidget(glowColor);
    }
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
          // ── Flux Caméra (Web uniquement) ─────────────────────────────────
          if (kIsWeb)
            buildCameraView()
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.face_retouching_natural_rounded,
                    size: 70,
                    color: _isSuccess == true
                        ? AppColors.secondary
                        : Colors.white24,
                  ),
                  if (_usesNativeBiometrics) ...[
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18),
                      child: Text(
                        'Capteur biométrique du téléphone',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
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

          // ── Ligne laser de balayage animé (Web) ───────────────────────────
          if (kIsWeb && (_isVerifying || _cameraActive))
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

  /// Widget visuel dédié à l'empreinte digitale (pas de caméra)
  Widget _buildFingerprintWidget(Color glowColor) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final pulse = 0.85 + 0.15 * _animController.value;
        return Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            shape: BoxShape.circle,
            border: Border.all(color: glowColor, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.4 * pulse),
                blurRadius: 32 * pulse,
                spreadRadius: 4 * pulse,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.fingerprint_rounded,
              size: 90,
              color: _isSuccess == true
                  ? AppColors.secondary
                  : _isSuccess == false
                      ? AppColors.error
                      : glowColor.withValues(alpha: 0.7 + 0.3 * pulse),
            ),
          ),
        );
      },
    );
  }
}
