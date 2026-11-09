import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import 'biometric_setup_screen.dart';
import 'delete_account_screen.dart';
import 'login_screen.dart';
import 'user_home_screen.dart';
import 'user_profile_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final int _navIndex = 2;

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    }
  }

  void _showChangePasswordDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.navyCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Changer le mot de passe',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Ancien mot de passe',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Nouveau mot de passe',
                prefixIcon: const Icon(Icons.lock_reset, size: 20),
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Confirmer le mot de passe',
                prefixIcon: const Icon(Icons.lock_reset, size: 20),
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Annuler',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newPass = newPasswordController.text;
              final confirmPass = confirmPasswordController.text;

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le mot de passe doit comporter au moins 6 caractères.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Les nouveaux mots de passe ne correspondent pas.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              Navigator.of(ctx).pop();
              final success = await context.auth.updatePassword(newPass);

              if (!mounted) return;

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe mis à jour avec succès.'),
                    backgroundColor: AppColors.secondary,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(context.auth.errorMessage ?? 'Erreur lors de la mise à jour.'),
                    backgroundColor: AppColors.error,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showUnitPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unité de mesure',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Métrique (kg, cm)',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              trailing: context.settings.unitSystem.contains('Métrique')
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.settings.setUnitSystem('Métrique (kg, cm)');
                Navigator.of(ctx).pop();
              },
            ),
            ListTile(
              title: Text(
                'Impérial (lbs, in)',
                style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
              ),
              trailing: context.settings.unitSystem.contains('Impérial')
                  ? const Icon(Icons.check, color: AppColors.primary)
                  : null,
              onTap: () {
                context.settings.setUnitSystem('Impérial (lbs, in)');
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSignOut() async {
    await context.auth.signOut();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déconnexion réussie.'),
        behavior: SnackBarBehavior.floating,
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
    final settings = context.settings;
    final user = context.auth.currentUser ??
        (context.users.allUsers.isNotEmpty ? context.users.allUsers.first : null);

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
        appBar: const AppAppBar(
          title: 'Paramètres du compte',
          showBackButton: false,
        ),
        body: const Center(
          child: Text('Veuillez vous connecter pour accéder aux paramètres.'),
        ),
      );
    }

    final faceIdSummary = user.biometricFingerprintEnabled && (user.biometricFaceEnabled || user.hasFaceRegistered)
        ? 'Empreinte · Face ID'
        : user.biometricFingerprintEnabled
            ? 'Empreinte activée'
            : (user.biometricFaceEnabled || user.hasFaceRegistered)
                ? 'Face ID activé'
                : 'Désactivé';

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Paramètres du compte',
        showBackButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Preferences
              Text(
                'Préférences',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Notifications
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.notifications_outlined,
                            color: AppColors.primaryLight, size: 20),
                      ),
                      title: Text(
                        'Notifications',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Gérer vos préférences',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      trailing: Switch(
                        value: settings.notificationsEnabled,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          settings.toggleNotifications(val);
                        },
                      ),
                    ),
                    const Divider(),

                    // Units
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.straighten_rounded,
                            color: AppColors.primaryLight, size: 20),
                      ),
                      title: Text(
                        'Unité de mesure',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        settings.unitSystem,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                      onTap: _showUnitPicker,
                    ),
                    const Divider(),

                    // Dark Mode
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.dark_mode_outlined,
                            color: AppColors.primaryLight, size: 20),
                      ),
                      title: Text(
                        'Mode sombre',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        settings.isDarkMode ? 'Activé' : 'Désactivé',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      trailing: Switch(
                        value: settings.isDarkMode,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          settings.toggleDarkMode(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Security
              Text(
                'Sécurité & Confidentialité',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              AppCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Biométrie (Face ID + Empreinte)
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF064E3B).withValues(alpha: 0.4)
                              : AppColors.secondarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint_rounded,
                            color: AppColors.secondary, size: 20),
                      ),
                      title: Text(
                        'Sécurité biométrique',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        faceIdSummary,
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BiometricSetupScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(),

                    // Change Password
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.lock_reset_rounded,
                            color: AppColors.primaryLight, size: 20),
                      ),
                      title: Text(
                        'Changer le mot de passe',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary),
                      ),
                      subtitle: Text(
                        'Sécurisez votre compte',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                      onTap: _showChangePasswordDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Actions: Logout & Delete Account matching mockup Screen 09
              AppButton.secondary(
                label: 'Déconnexion',
                icon: Icons.logout_rounded,
                onPressed: _handleSignOut,
              ),
              const SizedBox(height: 12),

              AppButton.destructive(
                label: 'Supprimer mon compte',
                icon: Icons.delete_forever_rounded,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DeleteAccountScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        onTap: _onBottomNavTapped,
        items: AppBottomNavigation.userNavItems,
      ),
    );
  }
}
