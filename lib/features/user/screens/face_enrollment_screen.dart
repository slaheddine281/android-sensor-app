import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';

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
  String _statusMessage = 'Initialisation des modèles d\'IA faciale...';

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    setState(() {
      _isProcessing = false;
      _statusMessage = 'Démarrage de la caméra...';
    });

    final faceService = context.faceRecognition;
    final camOk = await faceService.startCamera();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _statusMessage = camOk
          ? 'Placez votre visage au centre du cadre puis appuyez sur "Capturer".'
          : 'Caméra prête. Vous pouvez capturer votre visage.';
    });

    // Chargement des modèles IA en arrière-plan sans bloquer l'interface
    faceService.initializeModels();
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
      _statusMessage = 'Détection et analyse des 68 points caractéristiques...';
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
        _statusMessage = 'Visage enregistré et lié à votre profil avec succès !';
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Reconnaissance Faciale',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
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
                        Icons.face_rounded,
                        color: hasFace ? AppColors.secondary : AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasFace ? 'Visage configuré' : 'Aucun visage enregistré',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            hasFace
                                ? 'Votre profil utilise la reconnaissance faciale pour la connexion.'
                                : 'Scannez votre visage avec la caméra pour activer Face ID.',
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Camera Scanner Viewport
              Center(
                child: Container(
                  width: 260,
                  height: 320,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: hasFace ? AppColors.secondary : AppColors.primary,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (hasFace ? AppColors.secondary : AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Oval Face Guide
                      Container(
                        width: 190,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2,
                            strokeAlign: BorderSide.strokeAlignCenter,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.face_retouching_natural_rounded,
                            size: 80,
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                      ),

                      // Animated Laser Beam
                      if (_isProcessing)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, _) {
                            return Positioned(
                              top: 320 * _scanAnimation.value,
                              left: 20,
                              right: 20,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.secondary.withValues(alpha: 0.8),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Corner crosshairs
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.primaryLight, width: 3),
                              left: BorderSide(color: AppColors.primaryLight, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.primaryLight, width: 3),
                              right: BorderSide(color: AppColors.primaryLight, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.primaryLight, width: 3),
                              left: BorderSide(color: AppColors.primaryLight, width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: AppColors.primaryLight, width: 3),
                              right: BorderSide(color: AppColors.primaryLight, width: 3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          : (hasFace ? Icons.check_circle : Icons.info_outline),
                      color: hasFace ? AppColors.secondary : AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Capture Button
              AppButton(
                label: hasFace
                    ? 'Mettre à jour mon visage'
                    : 'Scanner & Enregistrer mon visage',
                icon: Icons.camera_alt_outlined,
                isLoading: _isProcessing,
                onPressed: _handleCaptureFace,
              ),
              const SizedBox(height: 12),

              // Delete button if face exists
              if (hasFace) ...[
                AppButton.destructive(
                  label: 'Supprimer mon visage',
                  icon: Icons.delete_outline_rounded,
                  onPressed: _handleRemoveFace,
                ),
                const SizedBox(height: 12),
              ],

              // Back button
              AppButton.secondary(
                label: 'Retour',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
