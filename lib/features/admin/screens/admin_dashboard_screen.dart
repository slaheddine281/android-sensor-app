import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/role_badge.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/user_activity_chart.dart';
import '../../../widgets/user_avatar.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../user/screens/login_screen.dart';
import 'user_details_screen.dart';
import 'users_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final int _navIndex = 0;
  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    // Charger immédiatement tous les utilisateurs depuis Supabase à l'ouverture du tableau de bord
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.users.loadUsersFromSupabase();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UsersListScreen()),
      );
    } else if (index == 2) {
      _showAdminSettingsDialog();
    }
  }

  void _showAdminSettingsDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Paramètres Administrateur',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sync_rounded,
                      color: AppColors.primary, size: 20),
                ),
                title: Text('Actualiser les profils (Supabase)',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        isDark ? AppColors.textMuted : AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  context.users.loadUsersFromSupabase();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Synchronisation avec Supabase effectuée.'),
                      backgroundColor: AppColors.secondary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.notifications_outlined,
                      color: AppColors.primary, size: 20),
                ),
                title: Text('Notifications Système',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                trailing: Icon(Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color:
                        isDark ? AppColors.textMuted : AppColors.textSecondary),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              Divider(
                color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      const Icon(Icons.logout, color: AppColors.error, size: 20),
                ),
                title: const Text('Déconnexion Session Admin',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    )),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await context.auth.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.users;
    final currentAdmin = context.auth.currentUser;
    final unreadCount = context.notifications.unreadCount;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allUsers = userState.allUsers;

    final totalUsers = userState.totalUsersCount;
    final faceIdUsers = userState.faceIdUsersCount;
    final fingerprintUsers = userState.fingerprintUsersCount;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await context.users.loadUsersFromSupabase();
          },
          child: FadeTransition(
            opacity: _fadeIn,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header avec Dégradé Moderne & Actions
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2A47), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Avatar administrateur
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                                width: 2),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              (currentAdmin?.firstName ?? 'A')[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Bonjour ${currentAdmin?.firstName ?? "Admin"}',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('🛡️',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              const SizedBox(height: 3),
                              const Text(
                                'Panneau d\'administration StepQuest',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bouton synchronisation directe
                        IconButton(
                          tooltip: 'Synchroniser avec Supabase',
                          onPressed: () {
                            context.users.loadUsersFromSupabase();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Synchronisation en cours...'),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Cloche de notifications
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 4,
                                  top: 4,
                                  child: Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: AppColors.error,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.navyHeader, width: 2),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Barre de chargement lors de la synchronisation Supabase
                  if (userState.isLoadingUsers)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.divider,
                        color: AppColors.primary,
                        minHeight: 3,
                      ),
                    ),

                  // Section Title & Subtitle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Vue d\'ensemble',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Appuyez pour filtrer',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 4 Cartes Métriques Interactives (Cliquables pour filtrer directement !)
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Total utilisateurs',
                          value: '${userState.totalUsersCount}',
                          valueColor:
                              isDark ? Colors.white : AppColors.textPrimary,
                          icon: Icons.people_alt_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UsersListScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Comptes actifs',
                          value: '${userState.activeUsersCount}',
                          valueColor: AppColors.secondary,
                          icon: Icons.check_circle_outline_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UsersListScreen(
                                  initialStatusFilter: UserStatus.active,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: MetricCard(
                          label: 'Suspendus',
                          value: '${userState.suspendedUsersCount}',
                          valueColor: AppColors.error,
                          icon: Icons.block_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UsersListScreen(
                                  initialStatusFilter: UserStatus.suspended,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MetricCard(
                          label: 'Admins',
                          value: '${userState.adminUsersCount}',
                          valueColor: AppColors.primary,
                          icon: Icons.admin_panel_settings_rounded,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const UsersListScreen(
                                  initialRoleFilter: UserRole.admin,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Carte d'Adoption Biométrique (Innovante & Spécifique à StepQuest !)
                  _buildBiometricAdoptionCard(
                    totalUsers: totalUsers,
                    faceIdUsers: faceIdUsers,
                    fingerprintUsers: fingerprintUsers,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Graphique interactif
                  const UserActivityChart(),
                  const SizedBox(height: 20),

                  // Section Utilisateurs Récents (Interactif)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Comptes récents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UsersListScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Voir tout >',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Liste des utilisateurs récents
                  ...allUsers.take(4).map(
                        (user) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecentUserCard(user, isDark),
                        ),
                      ),

                  const SizedBox(height: 10),

                  // Actions rapides
                  Text(
                    'Actions rapides',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildQuickActionTile(
                    icon: Icons.manage_accounts_rounded,
                    iconBg: isDark
                        ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                        : AppColors.primarySoft,
                    iconColor: AppColors.primary,
                    title: 'Gestion des utilisateurs',
                    subtitle:
                        '${userState.totalUsersCount} profils enregistrés dans Supabase',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const UsersListScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  _buildQuickActionTile(
                    icon: Icons.notifications_active_rounded,
                    iconBg: isDark
                        ? AppColors.tertiary.withValues(alpha: 0.2)
                        : AppColors.tertiarySoft,
                    iconColor: AppColors.tertiary,
                    title: 'Centre de notifications',
                    subtitle: unreadCount > 0
                        ? '$unreadCount notification${unreadCount > 1 ? 's' : ''} non lue${unreadCount > 1 ? 's' : ''}'
                        : 'Système à jour',
                    isDark: isDark,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        onTap: _onBottomNavTapped,
        items: AppBottomNavigation.adminNavItems,
      ),
    );
  }

  Widget _buildBiometricAdoptionCard({
    required int totalUsers,
    required int faceIdUsers,
    required int fingerprintUsers,
    required bool isDark,
  }) {
    final faceRatio = totalUsers > 0 ? (faceIdUsers / totalUsers) : 0.0;
    final fpRatio = totalUsers > 0 ? (fingerprintUsers / totalUsers) : 0.0;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.fingerprint_rounded,
                    color: AppColors.secondary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sécurité & Biométrie',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Adoption des capteurs Face ID & Empreinte',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Face ID progress bar
          Row(
            children: [
              const Icon(Icons.face_rounded,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reconnaissance Faciale (Face ID)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$faceIdUsers / $totalUsers (${(faceRatio * 100).round()}%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: faceRatio,
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              color: AppColors.primary,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 14),

          // Fingerprint progress bar
          Row(
            children: [
              const Icon(Icons.fingerprint_rounded,
                  size: 16, color: AppColors.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Capteur Empreinte Digitale',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$fingerprintUsers / $totalUsers (${(fpRatio * 100).round()}%)',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fpRatio,
              backgroundColor: isDark
                  ? const Color(0xFF1E293B)
                  : const Color(0xFFE2E8F0),
              color: AppColors.secondary,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentUserCard(AppUser user, bool isDark) {
    return AppCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(userId: user.id),
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          // Avatar
          _buildUserAvatarThumb(user, isDark),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    RoleBadge(role: user.role, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: user.status, compact: true),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 13,
            color: isDark ? AppColors.textMuted : AppColors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatarThumb(AppUser user, bool isDark) {
    if (user.facePhotoUrl != null &&
        user.facePhotoUrl!.startsWith('data:image')) {
      try {
        final commaIdx = user.facePhotoUrl!.indexOf(',');
        if (commaIdx != -1) {
          final bytes =
              base64Decode(user.facePhotoUrl!.substring(commaIdx + 1));
          return Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: user.isAdmin
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF334155) : AppColors.divider),
                width: 1.5,
              ),
              image: DecorationImage(
                image: MemoryImage(bytes),
                fit: BoxFit.cover,
              ),
            ),
          );
        }
      } catch (_) {}
    }
    return UserAvatar(user: user, radius: 19);
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
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
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? AppColors.textMuted : AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
