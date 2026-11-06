import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../models/user_notification.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/role_badge.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/user_avatar.dart';
import 'add_user_admin_screen.dart';
import 'admin_dashboard_screen.dart';
import 'edit_user_admin_screen.dart';
import 'user_details_screen.dart';

class UsersListScreen extends StatefulWidget {
  final UserStatus? initialStatusFilter;
  final UserRole? initialRoleFilter;

  const UsersListScreen({
    super.key,
    this.initialStatusFilter,
    this.initialRoleFilter,
  });

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  UserStatus? _selectedStatus;
  UserRole? _selectedRole;
  final int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter;
    _selectedRole = widget.initialRoleFilter;

    // Charger tous les profils depuis Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.users.loadUsersFromSupabase();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pop();
    }
  }

  void _handleToggleStatus(AppUser user) {
    final willSuspend = user.isActive;
    showAppConfirmationDialog(
      context: context,
      title: willSuspend ? 'Suspendre le compte ?' : 'Réactiver le compte ?',
      description: willSuspend
          ? 'L\'utilisateur "${user.fullName}" ne pourra plus se connecter tant que son compte n\'est pas réactivé.'
          : 'L\'utilisateur "${user.fullName}" retrouvera l\'accès immédiat à son compte.',
      confirmLabel: willSuspend ? 'Suspendre' : 'Réactiver',
      type: willSuspend
          ? ConfirmationDialogType.warning
          : ConfirmationDialogType.info,
      onConfirm: () {
        final newStatus =
            willSuspend ? UserStatus.suspended : UserStatus.active;
        context.users.updateUserStatus(user.id, newStatus);

        context.notifications.addNotification(
          title: willSuspend ? 'Compte suspendu' : 'Compte réactivé',
          message: willSuspend
              ? 'Le compte de ${user.fullName} a été suspendu.'
              : 'Le compte de ${user.fullName} a été réactivé.',
          type: willSuspend
              ? NotificationType.accountSuspended
              : NotificationType.accountReactivated,
          relatedUserId: user.id,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Statut de ${user.fullName} mis à jour : ${newStatus.label}'),
            backgroundColor:
                willSuspend ? AppColors.tertiary : AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _handleDeleteUser(AppUser user) {
    showAppConfirmationDialog(
      context: context,
      title: 'Supprimer l\'utilisateur ?',
      description:
          'Êtes-vous sûr de vouloir supprimer définitivement le profil de "${user.fullName}" ? Cette action marquera le compte comme suspendu dans la base de données.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
      onConfirm: () {
        try {
          context.users.deleteUser(user.id);

          context.notifications.addNotification(
            title: 'Compte supprimé',
            message:
                'Le compte de ${user.fullName} a été supprimé par l\'administrateur.',
            type: NotificationType.accountDeleted,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Utilisateur ${user.fullName} supprimé.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = context.users.filter(
      query: _searchQuery,
      statusFilter: _selectedStatus,
      roleFilter: _selectedRole,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = context.users.isLoadingUsers;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Utilisateurs',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        backgroundColor: isDark ? AppColors.navyCard : Colors.white,
        foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            );
          },
        ),
        actions: [
          // Bouton synchroniser
          IconButton(
            tooltip: 'Actualiser depuis Supabase',
            icon: Icon(
              Icons.sync_rounded,
              size: 22,
              color: isDark ? Colors.white70 : AppColors.textPrimary,
            ),
            onPressed: () {
              context.users.loadUsersFromSupabase();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Actualisation des profils...'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          // Bouton Ajouter un utilisateur (Navigation conforme vers AddUserAdminScreen)
          IconButton(
            tooltip: 'Ajouter un utilisateur',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                    : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: AppColors.primary, size: 20),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AddUserAdminScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await context.users.loadUsersFromSupabase();
          },
          child: Column(
            children: [
              // Indicateur de chargement
              if (isLoading)
                const LinearProgressIndicator(
                  backgroundColor: AppColors.divider,
                  color: AppColors.primary,
                  minHeight: 3,
                ),

              // Barre de recherche et filtres
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: isDark ? AppColors.navyCard : Colors.white,
                child: Column(
                  children: [
                    // Champ de recherche
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un utilisateur...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: isDark
                            ? AppColors.navyDark
                            : AppColors.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filtres horizontaux
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildStatusFilterChip(null, 'Tous', isDark),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip(
                              UserStatus.active, 'Actifs', isDark),
                          const SizedBox(width: 8),
                          _buildStatusFilterChip(
                              UserStatus.suspended, 'Suspendus', isDark),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 24,
                            color: isDark
                                ? const Color(0xFF1E293B)
                                : AppColors.divider,
                          ),
                          const SizedBox(width: 12),
                          _buildRoleFilterChip(null, 'Tous rôles', isDark),
                          const SizedBox(width: 8),
                          _buildRoleFilterChip(UserRole.admin, 'Admins', isDark),
                          const SizedBox(width: 8),
                          _buildRoleFilterChip(
                              UserRole.user, 'Utilisateurs', isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
              ),

              // Liste des utilisateurs
              Expanded(
                child: filteredUsers.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'Aucun utilisateur trouvé',
                        description:
                            'Aucun compte ne correspond à vos critères de recherche ou de filtre.',
                        action: TextButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedStatus = null;
                              _selectedRole = null;
                            });
                          },
                          child: const Text('Réinitialiser les filtres'),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildUserTile(user, isDark);
                        },
                      ),
              ),
            ],
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

  Widget _buildStatusFilterChip(
      UserStatus? status, String label, bool isDark) {
    final isSelected = _selectedStatus == status;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedStatus = status;
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppColors.textPrimary),
      ),
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : AppColors.divider),
          width: 1,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildRoleFilterChip(UserRole? role, String label, bool isDark) {
    final isSelected = _selectedRole == role;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedRole = role;
        });
      },
      selectedColor: AppColors.navyHeader,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppColors.textPrimary),
      ),
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.navyHeader
              : (isDark ? const Color(0xFF1E293B) : AppColors.divider),
          width: 1,
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildUserTile(AppUser user, bool isDark) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => UserDetailsScreen(userId: user.id),
          ),
        );
      },
      child: Row(
        children: [
          UserAvatar(user: user, radius: 22),
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
                const SizedBox(height: 3),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusBadge(status: user.status, compact: true),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert,
                size: 20, color: AppColors.textSecondary),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (val) {
              if (val == 'details') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => UserDetailsScreen(userId: user.id),
                  ),
                );
              } else if (val == 'edit') {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditUserAdminScreen(userId: user.id),
                  ),
                );
              } else if (val == 'toggle_status') {
                _handleToggleStatus(user);
              } else if (val == 'delete') {
                _handleDeleteUser(user);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'details',
                child: Row(
                  children: [
                    Icon(Icons.visibility_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Consulter'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Modifier'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle_status',
                child: Row(
                  children: [
                    Icon(
                      user.isActive
                          ? Icons.block_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: user.isActive
                          ? AppColors.tertiary
                          : AppColors.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.isActive ? 'Suspendre' : 'Réactiver',
                      style: TextStyle(
                        color: user.isActive
                            ? AppColors.tertiary
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Supprimer',
                        style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
