import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/role_badge.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/user_avatar.dart';
import 'account_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';
import 'user_home_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final int _navIndex = 1;

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
      );
    }
  }

  void _handleSignOut() {
    context.auth.signOut();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session terminée. À bientôt sur StepQuest !'),
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
    final user = context.auth.currentUser ?? context.users.allUsers.first;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Hero Banner with Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Curved Navy Background
                Container(
                  height: 190,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F2A47),
                        Color(0xFF1E3A8A),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const UserHomeScreen(),
                                ),
                              );
                            },
                          ),
                          const Text(
                            'Profil',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: Colors.white, size: 20),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Floating Avatar
                Positioned(
                  bottom: -46,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: UserAvatar(
                      user: user,
                      radius: 46,
                      borderColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 54),

            // User Name & Email
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    user.fullName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RoleBadge(role: user.role),
                      const SizedBox(width: 8),
                      StatusBadge(status: user.status),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Stats Row matching mockup Screen 07
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Niveau',
                          value: 'Niveau ${user.level}',
                          subtext: 'Progression',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Taille',
                          value: '${user.heightCm ?? 170} cm',
                          subtext: 'Taille',
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Poids',
                          value: '${user.weightKg?.toStringAsFixed(0) ?? 65} kg',
                          subtext: 'Poids',
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Personal Information Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Informations personnelles',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  AppCard(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          icon: Icons.person_outline,
                          label: 'Nom complet',
                          value: user.fullName,
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user.email,
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.cake_outlined,
                          label: 'Date de naissance',
                          value: AppDateFormatter.formatShort(user.birthDate),
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Membre depuis',
                          value: AppDateFormatter.formatShort(user.createdAt),
                          isDark: isDark,
                        ),
                        const Divider(),
                        _buildInfoRow(
                          icon: Icons.security_outlined,
                          label: 'Biométrie active',
                          value: user.biometricFingerprintEnabled &&
                                  user.biometricFaceEnabled
                              ? 'Empreinte · Visage'
                              : user.biometricFingerprintEnabled
                                  ? 'Empreinte uniquement'
                                  : user.biometricFaceEnabled
                                      ? 'Visage uniquement'
                                      : 'Aucune',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  AppButton(
                    label: 'Modifier mon profil',
                    icon: Icons.edit_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  AppButton.secondary(
                    label: 'Paramètres',
                    icon: Icons.settings_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  AppButton.destructive(
                    label: 'Déconnexion',
                    icon: Icons.logout_rounded,
                    onPressed: _handleSignOut,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        onTap: _onBottomNavTapped,
        items: AppBottomNavigation.userNavItems,
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtext,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.navyCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : AppColors.divider,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            subtext,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
