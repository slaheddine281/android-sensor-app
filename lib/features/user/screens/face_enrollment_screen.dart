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
  bool _modelLoading = true;
  String _statusMessage = 'Démarrage de la caméra...';

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.88).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Initialiser la caméra après le premier frame (évite l'erreur initState)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initCamera();
    });
  }

  Future<void> _initCamera() async {
    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _cameraActive = false;
      _statusMessage = 'Démarrage de la caméra...';
    });

    final faceService = context.faceRecognition;
    final camOk = await faceService.startCamera();

    if (!mounted) return;

    setState(() {
      _cameraActive = camOk;
      _statusMessage = camOk
          ? 'Placez votre visage dans l\'ovale puis appuyez sur "Capturer".'
          : kIsWeb
              ? 'Impossible d\'accéder à la caméra. Vérifiez les permissions.'
              : 'La reconnaissance faciale est disponible dans la version Web uniquement.';
    });

    final modelsLoaded = await faceService.initializeModels();
    if (!mounted) return;
    setState(() {
      _modelLoading = false;
      if (camOk && !modelsLoaded) {
        _statusMessage =
            'Modèles IA non chargés. Vérifiez la connexion puis réessayez.';
      }
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    context.faceRecognition.stopCamera();
    super.dispose();
  }

  Future<void> _handleCaptureFace() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Analyse des caractéristiques faciales en cours...';
    });

    final faceService = context.faceRecognition;
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
        _statusMessage = '✓ Visage enregistré avec succès !';
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
        _statusMessage = result.message;
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
          'Voulez-vous supprimer les données biométriques de votre visage ?',
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
      _statusMessage = 'Données biométriques supprimées.';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Carte d'état ──────────────────────────────────────────────
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hasFace
                            ? AppColors.secondary.withValues(alpha: 0.15)
                            : AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        hasFace
                            ? Icons.face_retouching_natural_rounded
                            : Icons.face_rounded,
                        color: accentColor,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasFace
                                ? 'Visage configuré'
                                : 'Aucun visage enregistré',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasFace
                                ? 'Face ID actif — connexion par reconnaissance faciale.'
                                : 'Scannez votre visage pour activer le Face ID.',
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
                          color:
                              AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
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
              const SizedBox(height: 20),

              // ── Fenêtre caméra + guide facial ────────────────────────────
              Center(
                child: Container(
                  width: 260,
                  height: 320,
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
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // ── Flux caméra via HtmlElementView (Web uniquement) ──
                      if (kIsWeb)
                        buildCameraView()
                      else
                        // Placeholder sombre si caméra inactive
                        Container(
                          color: const Color(0xFF0F172A),
                          child: Center(
                            child: Icon(
                              _cameraActive
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              size: 48,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),

                      // ── Ovale guide facial ────────────────────────────────
                      Center(
                        child: Container(
                          width: 185,
                          height: 248,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(120),
                            border: Border.all(
                              color: _cameraActive
                                  ? accentColor.withValues(alpha: 0.85)
                                  : Colors.white.withValues(alpha: 0.25),
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),

                      // ── Laser de scan animé (pendant traitement) ──────────
                      if (_isProcessing)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, _) {
                            return Positioned(
                              top: 310 * _scanAnimation.value,
                              left: 20,
                              right: 20,
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

                      // ── Coins de visée ────────────────────────────────────
                      ..._buildCornerCrosshairs(accentColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Barre de chargement des modèles IA ───────────────────────
              if (_modelLoading)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chargement des modèles IA...',
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

              // ── Message de statut ─────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          : (_statusMessage.startsWith('✓') ||
                                  hasFace && _cameraActive)
                              ? Icons.check_circle_rounded
                              : _cameraActive
                                  ? Icons.videocam_rounded
                                  : Icons.info_outline_rounded,
                      color: _isProcessing
                          ? AppColors.primary
                          : (_statusMessage.startsWith('✓') || hasFace)
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
                      SizedBox(
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
              const SizedBox(height: 20),

              // ── Bouton principal ──────────────────────────────────────────
              AppButton(
                label: hasFace
                    ? 'Mettre à jour mon visage'
                    : 'Capturer mon visage',
                icon: Icons.camera_alt_outlined,
                isLoading: _isProcessing,
                onPressed: _isProcessing || !_cameraActive
                  ? null
                  : _handleCaptureFace,
              ),
              const SizedBox(height: 12),

              // ── Bouton supprimer (si visage enregistré) ───────────────────
              if (hasFace) ...[
                AppButton.destructive(
                  label: 'Supprimer mon visage',
                  icon: Icons.delete_outline_rounded,
                  onPressed: _isProcessing ? null : _handleRemoveFace,
                ),
                const SizedBox(height: 12),
              ],

              // ── Bouton retour ─────────────────────────────────────────────
              AppButton.secondary(
                label: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit les 4 coins de visée du scanner
  List<Widget> _buildCornerCrosshairs(Color color) {
    const size = 20.0;
    const thickness = 3.0;
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
