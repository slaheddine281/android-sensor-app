import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/app_user.dart';
import '../../../models/user_notification.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';

class AddUserAdminScreen extends StatefulWidget {
  const AddUserAdminScreen({super.key});

  @override
  State<AddUserAdminScreen> createState() => _AddUserAdminScreenState();
}

class _AddUserAdminScreenState extends State<AddUserAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  UserRole _selectedRole = UserRole.user;
  UserStatus _selectedStatus = UserStatus.active;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    // Vérifier si l'email existe déjà dans l'état local
    if (context.users.findByEmail(email) != null) {
      setState(() {
        _errorMessage = 'Un compte existe déjà avec cette adresse email.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final newUser = AppUser(
      id: 'u-${DateTime.now().millisecondsSinceEpoch}',
      fullName: name,
      email: email,
      role: _selectedRole,
      status: _selectedStatus,
      createdAt: DateTime.now(),
      lastLoginAt: null,
      biometricFingerprintEnabled: false,
      biometricFaceEnabled: false,
      heightCm: 175,
      weightKg: 70,
      level: 1,
      deviceInfo: 'Créé via le panneau d\'administration',
    );

    try {
      await context.users.createUserInSupabase(newUser);

      if (!mounted) return;

      context.notifications.addNotification(
        title: 'Utilisateur créé',
        message:
            'L\'administrateur a ajouté le profil ${newUser.fullName}.',
        type: NotificationType.accountCreated,
        relatedUserId: newUser.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Utilisateur ${newUser.fullName} créé avec succès !'),
          backgroundColor: AppColors.secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la création : $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Ajouter un utilisateur',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar Placeholder avec icône d'ajout
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark
                          ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                          : AppColors.primarySoft,
                      border: Border.all(
                        color: AppColors.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _nameController.text.trim().isNotEmpty
                            ? _nameController.text.trim()[0].toUpperCase()
                            : '+',
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3)),
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

                // Nom complet
                AppTextField(
                  label: 'Nom complet',
                  hint: 'Ex: Fedi Bejaoui',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Veuillez saisir un nom complet valide';
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
                    if (val == null || !val.contains('@') || !val.contains('.')) {
                      return 'Veuillez saisir une adresse email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Dropdown Rôle (matching EditUserAdminScreen)
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
                      child: Text('Utilisateur standard'),
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

                // Sélecteur de statut (matching EditUserAdminScreen)
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
                                : (isDark
                                    ? AppColors.navyCard
                                    : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedStatus == UserStatus.active
                                  ? AppColors.secondary
                                  : (isDark
                                      ? AppColors.navyCard
                                      : AppColors.divider),
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
                                    : (isDark
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary),
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
                                : (isDark
                                    ? AppColors.navyCard
                                    : AppColors.background),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedStatus == UserStatus.suspended
                                  ? AppColors.error
                                  : (isDark
                                      ? AppColors.navyCard
                                      : AppColors.divider),
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
                                    : (isDark
                                        ? AppColors.textMuted
                                        : AppColors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Boutons d'action conformes
                AppButton(
                  label: 'Créer l\'utilisateur',
                  isLoading: _isLoading,
                  onPressed: _handleCreate,
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
