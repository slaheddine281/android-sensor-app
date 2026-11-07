import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import 'login_screen.dart';
import 'reset_password_screen.dart';
import 'user_home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _pillsFadeAnimation;
  late Animation<Offset> _pillsSlideAnimation;

  String _loadingStatus = 'Initialisation sécurisée...';
  double _progressValue = 0.15;

  @override
  void initState() {
    super.initState();

    // Contrôleur principal d'entrée
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutBack),
      ),
    );

    _pillsFadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _pillsSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Contrôleur de pulsation lumineuse continue (Halo néon)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.88, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // Étape 1 : Vérification URL
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      setState(() {
        _loadingStatus = 'Analyse de l\'environnement...';
        _progressValue = 0.45;
      });
    }

    // Vérifier si l'utilisateur arrive depuis un lien de réinitialisation de mot de passe (e-mail Supabase)
    final isRecoveryFromUrl =
        kIsWeb && Uri.base.toString().contains('type=recovery');

    if (isRecoveryFromUrl) {
      try {
        await SupabaseConstants.client?.auth.getSessionFromUrl(Uri.base);
      } catch (e) {
        debugPrint('SplashScreen getSessionFromUrl error: $e');
      }
    }

    // Étape 2 : Vérification session
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _loadingStatus = 'Vérification de la session active...';
        _progressValue = 0.85;
      });
    }

    if (!mounted) return;

    final authState = context.auth;
    final userState = context.users;

    if (isRecoveryFromUrl || authState.isPasswordRecovery) {
      authState.setPasswordRecovery(true);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
      return;
    }

    final hasSession = await authState.checkExistingSession(userState);

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    setState(() {
      _progressValue = 1.0;
      _loadingStatus = 'Prêt !';
    });

    if (authState.isPasswordRecovery) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
      );
      return;
    }

    if (hasSession && authState.currentUser != null) {
      if (authState.currentUser!.isAdmin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const UserHomeScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07111E),
      body: Stack(
        children: [
          // Arrière-plan dégradé futuriste avec nébuleuse
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0.0, -0.2),
                radius: 1.1,
                colors: [
                  Color(0xFF0F2B48),
                  Color(0xFF0A1828),
                  Color(0xFF050B14),
                ],
              ),
            ),
          ),

          // Lignes de scan légères en arrière-plan
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: CustomPaint(
                painter: _GridPatternPainter(),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // ── Emblem avec Halo Pulsant Animé ───────────────────────
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Halo lumineux extérieur pulsant
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, _) {
                                  return Container(
                                    width: 140 * _pulseAnimation.value,
                                    height: 140 * _pulseAnimation.value,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.primary.withValues(alpha: 0.35),
                                          AppColors.secondary.withValues(alpha: 0.12),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Anneau néon extérieur avec gradient
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primary,
                                      AppColors.secondary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.45),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3.0),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF0A1828),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.directions_run_rounded,
                                        size: 58,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),

                          // ── Titre Principal avec Reflet ──────────────────────
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Colors.white,
                                Color(0xFFE2E8F0),
                                AppColors.primaryLight,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ).createShader(bounds),
                            child: const Text(
                              'StepQuest',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Slogan officiel de l'application
                          const Text(
                            'Atteins tes objectifs',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF94A3B8),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Badges technologiques animés (Pills) ──────────────────
                  FadeTransition(
                    opacity: _pillsFadeAnimation,
                    child: SlideTransition(
                      position: _pillsSlideAnimation,
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildTechPill(
                            icon: Icons.face_retouching_natural_rounded,
                            label: 'Face ID IA',
                            color: AppColors.secondary,
                          ),
                          _buildTechPill(
                            icon: Icons.shield_rounded,
                            label: 'Sécurité Supabase',
                            color: AppColors.primaryLight,
                          ),
                          _buildTechPill(
                            icon: Icons.bolt_rounded,
                            label: 'Suivi Temps Réel',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // ── Barre de progression & Statut moderne ────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _loadingStatus,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(_progressValue * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                                begin: 0.0, end: _progressValue),
                            duration: const Duration(milliseconds: 400),
                            builder: (context, val, _) {
                              return LinearProgressIndicator(
                                value: val,
                                minHeight: 4,
                                backgroundColor: const Color(0xFF1E293B),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 0.5;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
