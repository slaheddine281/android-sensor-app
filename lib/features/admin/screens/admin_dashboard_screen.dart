import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/metric_card.dart';
import '../../../widgets/user_activity_chart.dart';
import '../../shared/screens/notifications_screen.dart';
import '../../user/screens/login_screen.dart';
import 'users_list_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    // Synchronisation automatique des utilisateurs depuis Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.users.loadUsersFromSupabase();
    });
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

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await context.users.loadUsersFromSupabase();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar conforme au design général StepQuest
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bonjour ${currentAdmin?.firstName ?? "Admin"}',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark ? Colors.white : AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 20)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tableau de bord',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),

                    // Actions en haut à droite : Actualisation & Notifications
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Actualiser depuis Supabase',
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
                              color: isDark ? AppColors.navyCard : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : AppColors.divider,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.sync_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.navyCard : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : AppColors.divider,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  size: 20,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 8,
                                  top: 8,
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
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Indicateur de chargement
                if (userState.isLoadingUsers)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      backgroundColor: AppColors.divider,
                      color: AppColors.primary,
                      minHeight: 3,
                    ),
                  ),

                // 4 Cartes Métriques (2x2) interactives (Cliquer pour filtrer directement)
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
                        label: 'Actifs',
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

                // Graphique de croissance avec DONNÉES RÉELLES calculées depuis Supabase
                const UserActivityChart(),
                const SizedBox(height: 20),

                // Carte d'Action Rapide épurée
                AppCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const UsersListScreen(),
                      ),
                    );
                  },
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                              : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.manage_accounts_rounded,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gestion des utilisateurs',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Consulter, filtrer, suspendre ou modifier',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMuted
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color:
                            isDark ? AppColors.textMuted : AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
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
}
