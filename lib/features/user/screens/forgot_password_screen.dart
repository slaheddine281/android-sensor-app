import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSubmitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    await context.auth.requestPasswordReset(_emailController.text);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      _isSubmitted = true;
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _isSubmitted
                ? _buildSuccessView(context, isDark)
                : _buildFormView(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView(BuildContext context, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Illustration matching mockup Screen 04
          Center(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                    : AppColors.primarySoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primaryLight.withValues(alpha: 0.25),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.mark_email_read_rounded,
                  size: 52,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Mot de passe oublié ?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Entrez votre e-mail et nous vous enverrons un lien pour réinitialiser votre mot de passe.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Email Field
          AppTextField(
            label: 'E-mail',
            hint: 'votre@email.com',
            controller: _emailController,
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) {
              if (val == null || val.trim().isEmpty || !val.contains('@')) {
                return 'Veuillez saisir une adresse email valide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          AppButton(
            label: 'Envoyer le lien',
            isLoading: _isLoading,
            onPressed: _handleSendResetLink,
          ),
          const SizedBox(height: 24),

          // Back to login
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, size: 16, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Retour à la connexion',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
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
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                  : AppColors.secondarySoft,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 52,
                color: AppColors.secondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Lien de réinitialisation simulé !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Dans un environnement de production avec serveur distant, un lien de réinitialisation sécurisé aurait été envoyé à :\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        AppButton(
          label: 'Retour à la connexion',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
