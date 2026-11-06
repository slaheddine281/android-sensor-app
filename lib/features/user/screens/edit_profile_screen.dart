import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/user_avatar.dart';
import 'face_enrollment_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _birthDateController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  DateTime? _selectedBirthDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _birthDateController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = context.auth.currentUser ??
          (context.users.allUsers.isNotEmpty ? context.users.allUsers.first : null);
      _nameController.text = user?.fullName ?? '';
      _emailController.text = user?.email ?? '';
      _selectedBirthDate = user?.birthDate ?? DateTime(2003, 1, 12);
      _birthDateController.text =
          AppDateFormatter.formatShort(_selectedBirthDate);
      _heightController.text = '${user?.heightCm ?? 170}';
      _weightController.text = '${user?.weightKg?.toInt() ?? 65}';
      _isInitialized = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(2003, 1, 12),
      firstDate: DateTime(1930),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateController.text = AppDateFormatter.formatShort(picked);
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final currentUser = context.auth.currentUser ??
        (context.users.allUsers.isNotEmpty ? context.users.allUsers.first : null);
    if (currentUser == null) return;

    final updated = currentUser.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      birthDate: _selectedBirthDate,
      heightCm: int.tryParse(_heightController.text.trim()) ?? 170,
      weightKg: double.tryParse(_weightController.text.trim()) ?? 65.0,
    );

    await context.auth.updateCurrentProfile(
      updatedUser: updated,
      userState: context.users,
      notificationState: context.notifications,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil mis à jour avec succès !'),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser ??
        (context.users.allUsers.isNotEmpty ? context.users.allUsers.first : null);
    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.navyDark : Colors.white,
        appBar: const AppAppBar(title: 'Modifier mon profil'),
        body: const Center(child: Text('Veuillez vous connecter.')),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : Colors.white,
      appBar: const AppAppBar(
        title: 'Modifier mon profil',
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
                    radius: 46,
                    showEditBadge: true,
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Simulation : Sélection d\'une photo de profil depuis la galerie.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Full name
                AppTextField(
                  label: 'Nom complet',
                  hint: 'Votre nom complet',
                  controller: _nameController,
                  prefixIcon: Icons.person_outline,
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Veuillez saisir votre nom complet';
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
                      return 'Veuillez saisir un email valide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Birth date
                GestureDetector(
                  onTap: _pickBirthDate,
                  child: AbsorbPointer(
                    child: AppTextField(
                      label: 'Date de naissance',
                      hint: '12 janv 2003',
                      controller: _birthDateController,
                      prefixIcon: Icons.calendar_today_outlined,
                      suffixIcon: const Icon(Icons.arrow_drop_down,
                          color: AppColors.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Row: Height & Weight matching mockup Screen 08
                Row(
                  children: [
                    Expanded(
                      child: AppTextField(
                        label: 'Taille (cm)',
                        hint: '170',
                        controller: _heightController,
                        prefixIcon: Icons.height_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final n = int.tryParse(val ?? '');
                          if (n == null || n < 50 || n > 250) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: AppTextField(
                        label: 'Poids (kg)',
                        hint: '65',
                        controller: _weightController,
                        prefixIcon: Icons.fitness_center_rounded,
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          final n = double.tryParse(val ?? '');
                          if (n == null || n < 20 || n > 300) {
                            return 'Invalide';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Reconnaissance Faciale (Face ID) - Raccourci vers la configuration
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FaceEnrollmentScreen(),
                      ),
                    );
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.navyCard : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: user.hasFaceRegistered
                            ? AppColors.secondary.withValues(alpha: 0.4)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: user.hasFaceRegistered
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.face_rounded,
                            color: user.hasFaceRegistered
                                ? AppColors.secondary
                                : AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reconnaissance Faciale (Face ID)',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.hasFaceRegistered
                                    ? 'Configuré & Actif'
                                    : 'Non configuré — Toucher pour configurer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: user.hasFaceRegistered
                                      ? AppColors.secondary
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

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
