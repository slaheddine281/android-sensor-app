import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../core/constants/supabase_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialCode;

  const ResetPasswordScreen({
    super.key,
    this.initialEmail,
    this.initialCode,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  late final TextEditingController _codeController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  bool _isSuccess = false;
  bool _isSessionReady = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _codeController = TextEditingController(text: widget.initialCode ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    // Tenter de restaurer la session depuis l'URL (si l'utilisateur a cliqué sur le lien de son e-mail)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkAndRestoreSession();
    });
  }

  Future<void> _checkAndRestoreSession() async {
    final sb = SupabaseConstants.client;
    if (sb == null) return;

    if (sb.auth.currentSession != null) {
      if (mounted) setState(() => _isSessionReady = true);
      return;
    }

    if (kIsWeb) {
      try {
        final url = Uri.base;
        final urlStr = url.toString();
        if (urlStr.contains('access_token') ||
            urlStr.contains('code=') ||
            urlStr.contains('type=recovery')) {
          await sb.auth.getSessionFromUrl(url);
          if (mounted) {
            setState(() {
              _isSessionReady = sb.auth.currentSession != null;
            });
          }
        }
      } catch (e) {
        debugPrint('ResetPasswordScreen restore session error: $e');
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final success = await context.auth.updatePassword(
      _passwordController.text,
      email: _emailController.text.trim(),
      resetCode: _codeController.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _isSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Votre mot de passe a été réinitialisé avec succès !'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final errorMsg = context.auth.errorMessage ??
          'Échec de la réinitialisation du mot de passe. Veuillez réessayer.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _isSuccess
                  ? _buildSuccessView(context, isDark)
                  : _buildFormView(context, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, bool isDark) {
    final hasActiveSession = _isSessionReady ||
        SupabaseConstants.client?.auth.currentSession != null ||
        context.auth.isPasswordRecovery;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Illustration / Icône de réinitialisation
          Center(
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                    : AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_reset_rounded,
                  size: 46,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Nouveau mot de passe',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Saisissez votre nouveau mot de passe ci-dessous pour sécuriser votre compte.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Badge d'information sur la session
          if (hasActiveSession)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.verified_user_rounded,
                      color: AppColors.secondary, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Lien de récupération vérifié avec succès.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            // Si aucune session active n'est détectée depuis l'URL, afficher les champs e-mail et code
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Si vous n\'avez pas cliqué sur le lien de l\'e-mail, saisissez votre e-mail et le code à 6 chiffres reçu dans l\'e-mail.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Champ Email
            AppTextField(
              label: 'Adresse e-mail',
              hint: 'votre@email.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.email_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty || !val.contains('@')) {
                  return 'Veuillez saisir votre adresse e-mail';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),

            // Champ Code de confirmation
            AppTextField(
              label: 'Code reçu par e-mail (Token)',
              hint: 'Ex: 123456 ou code du mail',
              controller: _codeController,
              prefixIcon: Icons.pin_outlined,
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Veuillez saisir le code reçu par e-mail';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 16),

          // Champ Nouveau Mot de passe
          AppTextField(
            label: 'Nouveau mot de passe',
            hint: 'Au moins 6 caractères',
            controller: _passwordController,
            isPassword: true,
            prefixIcon: Icons.lock_outline_rounded,
            validator: (val) {
              if (val == null || val.trim().length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Champ Confirmer Mot de passe
          AppTextField(
            label: 'Confirmer le mot de passe',
            hint: 'Répétez le mot de passe',
            controller: _confirmPasswordController,
            isPassword: true,
            prefixIcon: Icons.lock_reset_rounded,
            validator: (val) {
              if (val != _passwordController.text) {
                return 'Les deux mots de passe ne correspondent pas';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Bouton Enregistrer
          AppButton(
            label: 'Mettre à jour mon mot de passe',
            icon: Icons.check_circle_outline_rounded,
            isLoading: _isLoading,
            onPressed: _handleUpdatePassword,
          ),
          const SizedBox(height: 14),

          // Retour à la connexion
          AppButton.secondary(
            label: 'Retour à la connexion',
            icon: Icons.arrow_back_rounded,
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(BuildContext context, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                  : AppColors.secondarySoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                size: 52,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Mot de passe mis à jour !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter avec vos nouveaux identifiants.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 26),
        AppButton(
          label: 'Se connecter maintenant',
          icon: Icons.login_rounded,
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    );
  }
}
