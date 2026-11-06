import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../models/user_notification.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/user_avatar.dart';

class EditUserAdminScreen extends StatefulWidget {
  final String userId;

  const EditUserAdminScreen({super.key, required this.userId});

  @override
  State<EditUserAdminScreen> createState() => _EditUserAdminScreenState();
}

class _EditUserAdminScreenState extends State<EditUserAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  UserRole _selectedRole = UserRole.user;
  UserStatus _selectedStatus = UserStatus.active;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.users.findById(widget.userId);
      _nameController.text = user?.fullName ?? '';
      _emailController.text = user?.email ?? '';
      _selectedRole = user?.role ?? UserRole.user;
      _selectedStatus = user?.status ?? UserStatus.active;
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.users.findById(widget.userId);
    if (user == null) return;

    // Safety check: Prevent downgrading the last admin
    if (user.role == UserRole.admin && _selectedRole != UserRole.admin) {
      final remainingAdmins = context.users.allUsers
          .where((u) => u.role == UserRole.admin && u.id != user.id)
          .length;
      if (remainingAdmins == 0) {
        setState(() {
          _errorMessage =
              'Impossible de retirer le rôle admin : il doit rester au moins un administrateur actif.';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final updated = user.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      role: _selectedRole,
      status: _selectedStatus,
    );

    await context.users.updateUserInSupabase(updated);

    if (!mounted) return;

    context.notifications.addNotification(
      title: 'Profil utilisateur modifié',
      message:
          'Les informations administratives de ${updated.fullName} ont été mises à jour.',
      type: NotificationType.profileUpdated,
      relatedUserId: updated.id,
    );

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Utilisateur ${updated.fullName} mis à jour.'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.users.findById(widget.userId);

    if (user == null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Modifier l\'utilisateur'),
        body: const Center(child: Text('Utilisateur introuvable')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Modifier l\'utilisateur',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar with camera badge
                Center(
                  child: UserAvatar(
                    user: user,
                    name: _nameController.text,
                    radius: 44,
                    showEditBadge: true,
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Simulation : Changement d\'avatar de l\'utilisateur.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                                color: AppColors.error, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Name
                AppTextField(
                  label: 'Nom complet',
                  hint: 'Nom complet',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Veuillez saisir un nom valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email
                AppTextField(
                  label: 'Email',
                  hint: 'exemple@email.com',
                  controller: _emailController,
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || !val.contains('@')) {
                      return 'Veuillez saisir une adresse email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Role Dropdown matching mockup Screen 15
                Text(
                  'Rôle',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.shield_outlined,
                        color: AppColors.textSecondary, size: 20),
                    filled: true,
                    fillColor: isDark ? AppColors.navyCard : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.divider),
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.navyCard : Colors.white,
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.user,
                      child: Text('Utilisateur'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Administrateur'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedRole = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Status Segmented Selector matching mockup Screen 15
                Text(
                  'Statut',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStatus = UserStatus.active;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedStatus == UserStatus.active
                                ? AppColors.secondary
                                : (isDark ? AppColors.navyCard : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedStatus == UserStatus.active
                                  ? AppColors.secondary
                                  : (isDark ? AppColors.navyCard : AppColors.divider),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Actif',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedStatus == UserStatus.active
                                    ? Colors.white
                                    : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedStatus = UserStatus.suspended;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedStatus == UserStatus.suspended
                                ? AppColors.error
                                : (isDark ? AppColors.navyCard : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedStatus == UserStatus.suspended
                                  ? AppColors.error
                                  : (isDark ? AppColors.navyCard : AppColors.divider),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Suspendu',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _selectedStatus == UserStatus.suspended
                                    ? Colors.white
                                    : (isDark ? AppColors.textMuted : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Submit Button
                AppButton(
                  label: 'Enregistrer',
                  isLoading: _isLoading,
                  onPressed: _handleSave,
                ),
                const SizedBox(height: 12),

                AppButton.secondary(
                  label: 'Annuler',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
