import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/app_text_field.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _confirmController = TextEditingController();
  bool _understandConsequences = false;
  bool _isDeleting = false;

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    final user = context.auth.currentUser;
    if (user == null) return;

    if (!_understandConsequences) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez cocher la case attestant de votre accord.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_confirmController.text.trim().toUpperCase() != 'SUPPRIMER') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez taper "SUPPRIMER" pour valider l\'action.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    // Delete in Supabase + local state
    await context.auth.deleteCurrentAccount(
      userState: context.users,
      notificationState: context.notifications,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Votre compte a été supprimé avec succès.'),
        backgroundColor: AppColors.textPrimary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 4),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Suppression du compte',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Large Red Alert Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF7F1D1D).withValues(alpha: 0.35)
                        : AppColors.errorSoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 46,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Êtes-vous sûr de vouloir supprimer votre compte ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Cette action est irréversible. Toutes vos données personnelles associées à ${user?.email ?? 'votre compte'} seront effacées.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // Consequences card
              AppCard(
                borderColor: AppColors.error.withValues(alpha: 0.3),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Conséquences de la suppression :',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildConsequenceItem(
                      'Perte définitive de l\'historique d\'activité et progression',
                    ),
                    _buildConsequenceItem(
                      'Révocation immédiate des méthodes biométriques configurées',
                    ),
                    _buildConsequenceItem(
                      'Fermeture immédiate de votre session actuelle',
                    ),
                    _buildConsequenceItem(
                      'Suppression locale uniquement pendant l\'exécution (mode simulation)',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _understandConsequences,
                      activeColor: AppColors.error,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _understandConsequences = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Je comprends que la suppression est définitive et irréversible.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Confirmation input: Type "SUPPRIMER"
              AppTextField(
                label: 'Pour confirmer, tapez le mot "SUPPRIMER"',
                hint: 'SUPPRIMER',
                controller: _confirmController,
                prefixIcon: Icons.keyboard_outlined,
              ),
              const SizedBox(height: 28),

              // Buttons
              AppButton.destructive(
                label: 'Supprimer définitivement mon compte',
                isLoading: _isDeleting,
                onPressed: _handleDelete,
              ),
              const SizedBox(height: 12),

              AppButton.secondary(
                label: 'Annuler et revenir en arrière',
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsequenceItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

