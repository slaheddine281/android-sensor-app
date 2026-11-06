import 'dart:convert';
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
  bool _onlyBiometric = false;
  final int _navIndex = 1;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter;
    _selectedRole = widget.initialRoleFilter;

    // Charger immédiatement tous les utilisateurs depuis Supabase
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

  void _showAddUserDialog() {
    final userState = context.users;
    final notifState = context.notifications;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole newRole = UserRole.user;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return AlertDialog(
            backgroundColor: isDark ? AppColors.navyCard : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Nouvel utilisateur',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nom complet',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ex: Fedi Bejaoui',
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Adresse email',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'exemple@domaine.com',
                      prefixIcon: const Icon(Icons.email_outlined, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Rôle du compte',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserRole>(
                    initialValue: newRole,
                    dropdownColor: isDark ? AppColors.navyCard : Colors.white,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.shield_outlined, size: 20),
                      filled: true,
                      fillColor: isDark ? AppColors.navyDark : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: UserRole.user,
                        child: Text('Utilisateur standard'),
                      ),
                      DropdownMenuItem(
                        value: UserRole.admin,
                        child: Text('Administrateur'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          newRole = val;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        final email = emailController.text.trim().toLowerCase();
                        if (name.isEmpty || email.isEmpty || !email.contains('@')) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Veuillez saisir un nom et un email valide.'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setDialogState(() {
                          isSubmitting = true;
                        });

                        final newUser = AppUser(
                          id: 'u-${DateTime.now().millisecondsSinceEpoch}',
                          fullName: name,
                          email: email,
                          role: newRole,
                          status: UserStatus.active,
                          createdAt: DateTime.now(),
                          lastLoginAt: null,
                          biometricFingerprintEnabled: false,
                          biometricFaceEnabled: false,
                          heightCm: 175,
                          weightKg: 70,
                          level: 1,
                          deviceInfo: 'Créé via le panneau d\'administration',
                        );

                        await userState.createUserInSupabase(newUser);

                        notifState.addNotification(
                          title: 'Utilisateur créé',
                          message:
                              'L\'administrateur a ajouté le profil ${newUser.fullName}.',
                          type: NotificationType.accountCreated,
                          relatedUserId: newUser.id,
                        );

                        if (ctx.mounted) {
                          Navigator.of(ctx).pop();
                        }
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                                'Utilisateur ${newUser.fullName} ajouté avec succès !'),
                            backgroundColor: AppColors.secondary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                child: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Créer le compte'),
              ),
            ],
          );
        },
      ),
    );
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
    final userState = context.users;
    final allUsers = userState.allUsers;

    // Filtrage
    var filteredUsers = userState.filter(
      query: _searchQuery,
      statusFilter: _selectedStatus,
      roleFilter: _selectedRole,
    );

    if (_onlyBiometric) {
      filteredUsers = filteredUsers
          .where((u) =>
              u.biometricFaceEnabled ||
              u.hasFaceRegistered ||
              u.biometricFingerprintEnabled)
          .toList();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = userState.isLoadingUsers;

    // Statistiques pour les badges de filtres
    final totalCount = allUsers.length;
    final activeCount =
        allUsers.where((u) => u.status == UserStatus.active).length;
    final suspendedCount =
        allUsers.where((u) => u.status == UserStatus.suspended).length;
    final adminCount =
        allUsers.where((u) => u.role == UserRole.admin).length;
    final userCount =
        allUsers.where((u) => u.role == UserRole.user).length;
    final bioCount = allUsers
        .where((u) =>
            u.biometricFaceEnabled ||
            u.hasFaceRegistered ||
            u.biometricFingerprintEnabled)
        .length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Utilisateurs',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
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
          // Bouton synchroniser / actualiser
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
          IconButton(
            tooltip: 'Ajouter un utilisateur',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: _showAddUserDialog,
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

              // Search Bar & Filter Row
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                color: isDark ? AppColors.navyCard : Colors.white,
                child: Column(
                  children: [
                    // Search input
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
                        hintText: 'Rechercher par nom, email ou rôle...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
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

                    // Filter Chips horizontaux
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterBadgeChip(
                            label: 'Tous',
                            count: totalCount,
                            isSelected: _selectedStatus == null &&
                                _selectedRole == null &&
                                !_onlyBiometric,
                            onTap: () {
                              setState(() {
                                _selectedStatus = null;
                                _selectedRole = null;
                                _onlyBiometric = false;
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadgeChip(
                            label: 'Actifs',
                            count: activeCount,
                            color: AppColors.secondary,
                            isSelected: _selectedStatus == UserStatus.active,
                            onTap: () {
                              setState(() {
                                _selectedStatus =
                                    _selectedStatus == UserStatus.active
                                        ? null
                                        : UserStatus.active;
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadgeChip(
                            label: 'Suspendus',
                            count: suspendedCount,
                            color: AppColors.error,
                            isSelected: _selectedStatus == UserStatus.suspended,
                            onTap: () {
                              setState(() {
                                _selectedStatus =
                                    _selectedStatus == UserStatus.suspended
                                        ? null
                                        : UserStatus.suspended;
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 1,
                            height: 24,
                            color:
                                isDark ? AppColors.navyDark : AppColors.divider,
                          ),
                          const SizedBox(width: 10),
                          _buildFilterBadgeChip(
                            label: 'Admins',
                            count: adminCount,
                            color: AppColors.primary,
                            isSelected: _selectedRole == UserRole.admin,
                            onTap: () {
                              setState(() {
                                _selectedRole =
                                    _selectedRole == UserRole.admin
                                        ? null
                                        : UserRole.admin;
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadgeChip(
                            label: 'Utilisateurs',
                            count: userCount,
                            isSelected: _selectedRole == UserRole.user,
                            onTap: () {
                              setState(() {
                                _selectedRole =
                                    _selectedRole == UserRole.user
                                        ? null
                                        : UserRole.user;
                              });
                            },
                            isDark: isDark,
                          ),
                          const SizedBox(width: 8),
                          _buildFilterBadgeChip(
                            label: 'Biométrie',
                            count: bioCount,
                            icon: Icons.fingerprint_rounded,
                            isSelected: _onlyBiometric,
                            onTap: () {
                              setState(() {
                                _onlyBiometric = !_onlyBiometric;
                              });
                            },
                            isDark: isDark,
                          ),
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

              // Results count header
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filteredUsers.length} profil${filteredUsers.length > 1 ? 's' : ''} affiché${filteredUsers.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.textMuted : AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty ||
                        _selectedStatus != null ||
                        _selectedRole != null ||
                        _onlyBiometric)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _selectedStatus = null;
                            _selectedRole = null;
                            _onlyBiometric = false;
                          });
                        },
                        child: const Text(
                          'Réinitialiser',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // List of Users
              Expanded(
                child: filteredUsers.isEmpty
                    ? EmptyState(
                        icon: Icons.person_search_rounded,
                        title: 'Aucun utilisateur trouvé',
                        description:
                            'Aucun compte ne correspond à vos critères de recherche ou de filtre.',
                        action: TextButton.icon(
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Réinitialiser les filtres'),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                              _selectedStatus = null;
                              _selectedRole = null;
                              _onlyBiometric = false;
                            });
                          },
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: filteredUsers.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _buildInteractiveUserTile(user, isDark);
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

  Widget _buildFilterBadgeChip({
    required String label,
    required int count,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    Color? color,
    IconData? icon,
  }) {
    final activeColor = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor
              : (isDark ? AppColors.navyDark : AppColors.background),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor
                : (isDark ? const Color(0xFF1E293B) : AppColors.divider),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : AppColors.textPrimary),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : (isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveUserTile(AppUser user, bool isDark) {
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
          // Avatar amélioré avec support photo si disponible
          _buildUserAvatar(user, isDark),
          const SizedBox(width: 14),

          // Informations utilisateur
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
                          fontSize: 15,
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
                const SizedBox(height: 6),

                // Badges additionnels (Statut + Biométrie)
                Row(
                  children: [
                    StatusBadge(status: user.status, compact: true),
                    if (user.hasFaceRegistered || user.biometricFaceEnabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.face_rounded,
                                size: 11, color: AppColors.primary),
                            SizedBox(width: 3),
                            Text(
                              'Face ID',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (user.biometricFingerprintEnabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.fingerprint_rounded,
                                size: 11, color: AppColors.secondary),
                            SizedBox(width: 3),
                            Text(
                              'Empreinte',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Menu popup d'actions
          PopupMenuButton<String>(
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.navyDark
                    : AppColors.background.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.more_vert,
                  size: 20, color: AppColors.textSecondary),
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icon(Icons.visibility_outlined,
                        size: 18, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Consulter le profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined,
                        size: 18, color: AppColors.secondary),
                    SizedBox(width: 10),
                    Text('Modifier les informations'),
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
                    const SizedBox(width: 10),
                    Text(
                      user.isActive ? 'Suspendre l\'accès' : 'Réactiver l\'accès',
                      style: TextStyle(
                        color: user.isActive
                            ? AppColors.tertiary
                            : AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline,
                        size: 18, color: AppColors.error),
                    SizedBox(width: 10),
                    Text(
                      'Supprimer',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserAvatar(AppUser user, bool isDark) {
    if (user.facePhotoUrl != null &&
        user.facePhotoUrl!.startsWith('data:image')) {
      try {
        final commaIdx = user.facePhotoUrl!.indexOf(',');
        if (commaIdx != -1) {
          final bytes =
              base64Decode(user.facePhotoUrl!.substring(commaIdx + 1));
          return Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: user.isAdmin
                    ? AppColors.primary
                    : (isDark ? const Color(0xFF334155) : AppColors.divider),
                width: 2,
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

    return UserAvatar(user: user, radius: 23);
  }
}
