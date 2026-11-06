import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/app_user.dart';
import '../../../models/user_notification.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/confirmation_dialog.dart';
import '../../../widgets/role_badge.dart';
import '../../../widgets/status_badge.dart';
import '../../../widgets/user_avatar.dart';
import 'edit_user_admin_screen.dart';

class UserDetailsScreen extends StatefulWidget {
  final String userId;

  const UserDetailsScreen({super.key, required this.userId});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleToggleStatus(AppUser user) {
    final willSuspend = user.isActive;
    showAppConfirmationDialog(
      context: context,
      title: willSuspend ? 'Suspendre le compte ?' : 'Réactiver le compte ?',
      description: willSuspend
          ? 'L\'utilisateur ne pourra plus se connecter tant que son compte n\'est pas réactivé.'
          : 'L\'utilisateur retrouvera l\'accès immédiat à son compte et ses fonctionnalités.',
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
                'Statut mis à jour : ${user.fullName} est maintenant ${newStatus.label.toLowerCase()}.'),
            backgroundColor:
                willSuspend ? AppColors.tertiary : AppColors.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _handleDelete(AppUser user) {
    showAppConfirmationDialog(
      context: context,
      title: 'Supprimer l\'utilisateur ?',
      description:
          'Êtes-vous sûr de vouloir supprimer définitivement le compte de "${user.fullName}" ? Cette opération retirera l\'utilisateur de l\'état local.',
      confirmLabel: 'Supprimer',
      isDestructive: true,
      onConfirm: () {
        try {
          context.users.deleteUser(user.id);

          context.notifications.addNotification(
            title: 'Compte supprimé',
            message: 'Le compte de ${user.fullName} a été supprimé.',
            type: NotificationType.accountDeleted,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Utilisateur ${user.fullName} supprimé.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).pop();
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
    final user = context.users.findById(widget.userId);

    if (user == null) {
      return Scaffold(
        appBar: const AppAppBar(title: 'Détails de l\'utilisateur'),
        body: const Center(child: Text('Utilisateur introuvable.')),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: const AppAppBar(
        title: 'Détails de l\'utilisateur',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              AppCard(
                padding: const EdgeInsets.all(20),
                backgroundColor: AppColors.navyHeader,
                borderColor: const Color(0xFF1E3A8A),
                child: Column(
                  children: [
                    UserAvatar(
                      user: user,
                      radius: 36,
                      borderColor: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
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
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Tab Bar: Informations / Activité / Appareils
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? AppColors.textMuted : AppColors.textSecondary,
                  labelStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'Informations'),
                    Tab(text: 'Activité'),
                    Tab(text: 'Appareils'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Tab View Content
              SizedBox(
                height: 380,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildInfoTab(user),
                    _buildActivityTab(user),
                    _buildDevicesTab(user),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              AppButton(
                label: 'Modifier',
                icon: Icons.edit_outlined,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EditUserAdminScreen(userId: user.id),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              AppButton(
                label: user.isActive ? 'Suspendre' : 'Réactiver',
                icon: user.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline,
                customBackgroundColor: user.isActive
                    ? AppColors.tertiary
                    : AppColors.secondary,
                onPressed: () => _handleToggleStatus(user),
              ),
              const SizedBox(height: 10),

              AppButton.destructive(
                label: 'Supprimer l\'utilisateur',
                icon: Icons.delete_outline,
                onPressed: () => _handleDelete(user),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(AppUser user) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView(
        children: [
          _buildDetailRow(
            label: 'ID utilisateur',
            value: user.id,
            trailing: IconButton(
              icon: const Icon(Icons.copy_rounded, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: user.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('ID copié dans le presse-papier'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Date d\'inscription',
            value: AppDateFormatter.formatShort(user.createdAt),
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Dernière connexion',
            value: user.lastLoginAt != null
                ? AppDateFormatter.formatWithTime(user.lastLoginAt)
                : 'Jamais',
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Rôle',
            value: user.role.label,
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Statut',
            value: user.status.label,
          ),
          const Divider(),
          _buildDetailRow(
            label: 'Niveau',
            value: 'Niveau ${user.level}',
          ),
          if (user.heightCm != null || user.weightKg != null) ...[
            const Divider(),
            _buildDetailRow(
              label: 'Morphologie',
              value: '${user.heightCm ?? "-"} cm · ${user.weightKg ?? "-"} kg',
            ),
          ],
          if (user.birthDate != null) ...[
            const Divider(),
            _buildDetailRow(
              label: 'Date de naissance',
              value: AppDateFormatter.formatShort(user.birthDate!),
            ),
          ],
          const Divider(),
          _buildDetailRow(
            label: 'Biométrie',
            value: user.biometricFingerprintEnabled && user.biometricFaceEnabled
                ? 'Empreinte (Activée) · Face ID (Activé)'
                : user.biometricFingerprintEnabled
                    ? 'Empreinte (Activée)'
                    : (user.biometricFaceEnabled || user.hasFaceRegistered)
                        ? 'Face ID (Activé)'
                        : 'Aucune',
          ),
          if (user.hasFaceRegistered) ...[
            const Divider(),
            _buildDetailRow(
              label: 'Face ID',
              value: 'Modèle biométrique 128D configuré',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityTab(AppUser user) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildActivityItem(
            icon: Icons.login_rounded,
            title: 'Dernière connexion simulée',
            time: user.lastLoginAt != null
                ? AppDateFormatter.formatWithTime(user.lastLoginAt)
                : 'Aucune connexion récente',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.app_registration_rounded,
            title: 'Création du compte',
            time: AppDateFormatter.formatWithTime(user.createdAt),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            icon: Icons.shield_outlined,
            title: 'Vérification biométrique',
            time: user.biometricFingerprintEnabled
                ? 'Empreinte digitale configurée'
                : 'Biométrie non activée',
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab(AppUser user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_android_rounded,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.deviceInfo ?? 'Smartphone Android 14',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Appareil principal enregistré',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'Sécurité de la session :',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '• Chiffrement local des données\n• Clé biométrique liée au matériel de l\'appareil\n• Aucune synchronisation distante (Mode hors-ligne / Sandbox)',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textMuted : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
                : AppColors.primarySoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
