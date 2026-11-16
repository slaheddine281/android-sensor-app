import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/user_avatar.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../shared/screens/notifications_screen.dart';
import 'account_settings_screen.dart';
import 'biometric_setup_screen.dart';
import 'edit_profile_screen.dart';
import 'user_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final int _navIndex = 0;

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser ??
        (context.users.allUsers.isNotEmpty ? context.users.allUsers.first : null);

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
        body: const Center(
          child: Text('Veuillez vous connecter.'),
        ),
      );
    }
    final unreadCount = context.notifications.unreadCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Greeting & Notification Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Bonjour, ${user.firstName}',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text('👋', style: TextStyle(fontSize: 20)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prêt à relever de nouveaux défis ?',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Notification bell with badge
                  Stack(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.navyCard : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : AppColors.divider,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.notifications_outlined,
                            size: 20,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 10,
                          top: 10,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (user.isAdmin) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded,
                          color: AppColors.primaryLight, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Compte Administrateur',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const Text(
                              'Supervisez les utilisateurs et les statistiques.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const AdminDashboardScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Tableau de bord',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],

              // Level & Progress Card
              AppCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: user, radius: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
                                          : AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Niveau 3',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primaryLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Membre actif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Résumé forme & morphologie utile (non redondant)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A)
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildMiniStat(
                            icon: Icons.height_rounded,
                            label: 'Taille',
                            value: '${user.heightCm ?? 170} cm',
                            isDark: isDark,
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? const Color(0xFF334155) : AppColors.divider,
                          ),
                          _buildMiniStat(
                            icon: Icons.fitness_center_rounded,
                            label: 'Poids',
                            value: '${user.weightKg?.toStringAsFixed(0) ?? 65} kg',
                            isDark: isDark,
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: isDark ? const Color(0xFF334155) : AppColors.divider,
                          ),
                          _buildMiniStat(
                            icon: Icons.verified_user_outlined,
                            label: 'Face ID',
                            value: (user.biometricFaceEnabled &&
                                    user.hasFaceRegistered)
                                ? 'Actif'
                                : 'Inactif',
                            valueColor: (user.biometricFaceEnabled &&
                                    user.hasFaceRegistered)
                                ? AppColors.secondary
                                : AppColors.textSecondary,
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Section Accès Rapide avec actions ciblées (sans doublon avec la barre inférieure)
              Text(
                'Accès rapide',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              _buildQuickAccessTile(
                icon: Icons.face_rounded,
                iconColor: AppColors.secondary,
                title: 'Reconnaissance Faciale Face ID',
                subtitle: (user.biometricFaceEnabled && user.hasFaceRegistered)
                    ? 'Gérer ou recalibrer votre scan facial'
                    : 'Activer la connexion par visage',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const BiometricSetupScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildQuickAccessTile(
                icon: Icons.edit_note_rounded,
                iconColor: AppColors.primaryLight,
                title: 'Modifier mes mensurations',
                subtitle: 'Mettre à jour taille, poids et profil',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              _buildQuickAccessTile(
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFFF59E0B),
                title: 'Centre de notifications',
                subtitle: 'Historique des alertes et connexions',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
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

  Widget _buildMiniStat({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? Colors.white : AppColors.textPrimary),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDestructive
                  ? (isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.3) : AppColors.errorSoft)
                  : (isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.3) : AppColors.primarySoft),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDestructive
                        ? AppColors.error
                        : (isDark ? Colors.white : AppColors.textPrimary),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDestructive ? AppColors.error : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
