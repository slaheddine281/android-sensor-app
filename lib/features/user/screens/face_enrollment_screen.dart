import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';

// Imports conditionnels Web uniquement
import 'face_enrollment_screen_web.dart'
    if (dart.library.io) 'face_enrollment_screen_stub.dart';

class FaceEnrollmentScreen extends StatefulWidget {
  const FaceEnrollmentScreen({super.key});

  @override
  State<FaceEnrollmentScreen> createState() => _FaceEnrollmentScreenState();
}

class _FaceEnrollmentScreenState extends State<FaceEnrollmentScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  bool _isProcessing = false;
  bool _cameraActive = false;
  bool _modelLoading = false;
  String _statusMessage = 'Démarrage de la caméra...';

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.06, end: 0.90).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Initialiser la caméra après le premier rendu
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCamera();
    });
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _cameraActive = false;
      _statusMessage = 'Ouverture de la caméra...';
    });

    final faceService = context.faceRecognition;
    final camOk = await faceService.startCamera();

    if (!mounted) return;

    setState(() {
      _cameraActive = camOk;
      _statusMessage = camOk
          ? 'Placez votre visage au centre du cadre puis appuyez sur "Capturer".'
          : 'Accès caméra en attente. Vérifiez que votre navigateur autorise la webcam.';
    });

    // Préchargement des modèles d'analyse faciale
    if (!faceService.modelsLoaded) {
      setState(() => _modelLoading = true);
      faceService.initializeModels().then((_) {
        if (mounted) setState(() => _modelLoading = false);
      });
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: use_build_context_synchronously
      context.faceRecognition.stopCamera();
    });
    super.dispose();
  }

  Future<void> _handleCaptureFace() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Extraction des 128 points biométriques en cours...';
    });

    final faceService = context.faceRecognition;

    // Si la caméra n'était pas active, essayer de la réactiver
    if (!_cameraActive) {
      final camOk = await faceService.startCamera();
      if (!camOk) {
        if (!mounted) return;
        setState(() {
          _isProcessing = false;
          _statusMessage = 'Impossible d\'accéder à la caméra. Vérifiez les autorisations.';
        });
        return;
      }
      setState(() => _cameraActive = true);
    }

    final result = await faceService.scanFace();

    if (!mounted) return;

    if (result.success && result.faceEmbeddingJson != null) {
      final currentUser = context.auth.currentUser;
      if (currentUser != null) {
        final updated = currentUser.copyWith(
          faceEmbedding: result.faceEmbeddingJson,
          facePhotoUrl: result.photoBase64 ?? currentUser.facePhotoUrl,
          biometricFaceEnabled: true,
        );

        await context.auth.updateCurrentProfile(
          updatedUser: updated,
          userState: context.users,
          notificationState: context.notifications,
        );
      }

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = '✓ Empreinte faciale enregistrée et Face ID activé avec succès !';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visage enregistré et activé avec succès !'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _statusMessage = result.message.isNotEmpty
            ? result.message
            : 'Aucun visage net détecté. Placez-vous bien face à la caméra.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleRemoveFace() async {
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
        faceEmbedding: '',
        facePhotoUrl: '',
        biometricFaceEnabled: false,
      );

      await context.auth.updateCurrentProfile(
        updatedUser: updated,
        userState: context.users,
        notificationState: context.notifications,
      );
    }

    if (!mounted) return;

    setState(() {
      _statusMessage = 'Données biométriques faciales supprimées.';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Empreinte faciale supprimée.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser;
    final hasFace = user?.hasFaceRegistered ?? false;
    final accentColor = hasFace ? AppColors.secondary : AppColors.primary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(title: 'Reconnaissance Faciale'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Carte d'état Face ID ─────────────────────────────────
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: hasFace
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            hasFace
                                ? Icons.face_retouching_natural_rounded
                                : Icons.face_rounded,
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
                                hasFace
                                    ? 'Face ID configuré'
                                    : 'Aucun visage enregistré',
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
                                hasFace
                                    ? 'Actif — Déverrouillez votre compte instantanément.'
                                    : 'Enregistrez votre visage pour activer la connexion rapide.',
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
                        if (hasFace)
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
                  const SizedBox(height: 18),

                  // ── Fenêtre Caméra & Guide Facial ────────────────────────
                  Center(
                    child: Container(
                      width: 240,
                      height: 290,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _cameraActive
                              ? accentColor
                              : const Color(0xFF334155),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (_cameraActive ? accentColor : Colors.black)
                                .withValues(alpha: 0.3),
                            blurRadius: 26,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // ── Flux Caméra ──────────────────────────────────
                          if (kIsWeb)
                            buildCameraView()
                          else
                            const Center(
                              child: Icon(
                                Icons.face_rounded,
                                size: 64,
                                color: Colors.white24,
                              ),
                            ),

                          // ── Ovale guide facial ───────────────────────────
                          Center(
                            child: Container(
                              width: 170,
                              height: 225,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(110),
                                border: Border.all(
                                  color: _cameraActive
                                      ? accentColor.withValues(alpha: 0.85)
                                      : Colors.white.withValues(alpha: 0.3),
                                  width: 2.2,
                                ),
                              ),
                            ),
                          ),

                          // ── Laser de scan animé ──────────────────────────
                          if (_isProcessing)
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, _) {
                                return Positioned(
                                  top: 280 * _scanAnimation.value,
                                  left: 16,
                                  right: 16,
                                  child: Container(
                                    height: 2.5,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          AppColors.secondary,
                                          AppColors.secondary,
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.secondary
                                              .withValues(alpha: 0.8),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          // ── Coins de visée Face ID ───────────────────────
                          ..._buildCornerCrosshairs(accentColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Indicateur de modèles IA (si en cours) ────────────────
                  if (_modelLoading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: accentColor.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Optimisation des modèles biométriques...',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // ── Message de statut ─────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isProcessing
                              ? Icons.sync_rounded
                              : _statusMessage.startsWith('✓')
                                  ? Icons.check_circle_rounded
                                  : Icons.info_outline_rounded,
                          color: _statusMessage.startsWith('✓')
                              ? AppColors.secondary
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
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
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
                  const SizedBox(height: 18),

                  // ── Bouton principal de capture ───────────────────────────
                  AppButton(
                    label: hasFace
                        ? 'Mettre à jour mon visage'
                        : 'Capturer mon visage',
                    icon: Icons.camera_alt_rounded,
                    isLoading: _isProcessing,
                    onPressed: _isProcessing ? null : _handleCaptureFace,
                  ),
                  const SizedBox(height: 10),

                  // ── Bouton Supprimer mon visage (si configuré) ─────────────
                  if (hasFace) ...[
                    AppButton.destructive(
                      label: 'Supprimer mon visage',
                      icon: Icons.delete_outline_rounded,
                      onPressed: _isProcessing ? null : _handleRemoveFace,
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
