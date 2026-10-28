import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../models/user_notification.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'Toutes';

  @override
  Widget build(BuildContext context) {
    final notifState = context.notifications;
    final allNotifications = notifState.notifications;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = allNotifications.where((n) {
      if (_selectedFilter == 'Non lues') {
        return !n.isRead;
      } else if (_selectedFilter == 'Comptes') {
        return n.type == NotificationType.accountCreated ||
            n.type == NotificationType.accountDeleted ||
            n.type == NotificationType.profileUpdated;
      } else if (_selectedFilter == 'Sécurité') {
        return n.type == NotificationType.securityAlert ||
            n.type == NotificationType.accountSuspended ||
            n.type == NotificationType.accountReactivated ||
            n.type == NotificationType.roleChanged;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Notifications',
        actions: [
          if (notifState.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all_rounded,
                  size: 16, color: AppColors.primary),
              label: const Text(
                'Tout lire',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              onPressed: () {
                notifState.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Toutes les notifications sont marquées comme lues.'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chips Bar
            Container(
              color: isDark ? AppColors.navyCard : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Toutes', allNotifications.length, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Non lues', notifState.unreadCount, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Comptes', null, isDark),
                    const SizedBox(width: 8),
                    _buildFilterChip('Sécurité', null, isDark),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
            ),

            // List of Notifications
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'Aucune notification',
                      description:
                          'Vous êtes à jour ! Aucune notification ne correspond à ce filtre.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final notif = filtered[index];
                        return _buildNotificationCard(notif, notifState, isDark);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int? count, bool isDark) {
    final isSelected = _selectedFilter == label;
    return FilterChip(
      label: Text(count != null && count > 0 ? '$label ($count)' : label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
      ),
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppColors.primary
              : (isDark ? const Color(0xFF1E293B) : AppColors.divider),
        ),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildNotificationCard(
    UserNotification notif,
    dynamic notifState,
    bool isDark,
  ) {
    IconData icon;
    Color iconColor;
    Color iconBgColor;

    switch (notif.type) {
      case NotificationType.accountCreated:
        icon = Icons.person_add_alt_1_rounded;
        iconColor = AppColors.secondary;
        iconBgColor = isDark
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.secondarySoft;
        break;
      case NotificationType.accountSuspended:
        icon = Icons.block_rounded;
        iconColor = AppColors.error;
        iconBgColor = isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.errorSoft;
        break;
      case NotificationType.accountReactivated:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.secondary;
        iconBgColor = isDark
            ? AppColors.secondary.withValues(alpha: 0.15)
            : AppColors.secondarySoft;
        break;
      case NotificationType.securityAlert:
        icon = Icons.warning_amber_rounded;
        iconColor = AppColors.tertiary;
        iconBgColor = isDark
            ? AppColors.tertiary.withValues(alpha: 0.15)
            : AppColors.tertiarySoft;
        break;
      case NotificationType.roleChanged:
        icon = Icons.shield_outlined;
        iconColor = AppColors.primary;
        iconBgColor = isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primarySoft;
        break;
      case NotificationType.profileUpdated:
      case NotificationType.loginDetected:
        icon = Icons.login_rounded;
        iconColor = AppColors.primary;
        iconBgColor = isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primarySoft;
        break;
      case NotificationType.accountDeleted:
        icon = Icons.delete_outline_rounded;
        iconColor = AppColors.error;
        iconBgColor = isDark
            ? AppColors.error.withValues(alpha: 0.15)
            : AppColors.errorSoft;
        break;
    }

    final cardBg = notif.isRead
        ? (isDark ? AppColors.navyCard : Colors.white)
        : (isDark
            ? const Color(0xFF064E3B).withValues(alpha: 0.25)
            : const Color(0xFFF0FDF4));

    final cardBorder = notif.isRead
        ? (isDark ? const Color(0xFF1E293B) : AppColors.divider)
        : AppColors.secondary.withValues(alpha: 0.4);

    return AppCard(
      onTap: () {
        notifState.markAsRead(notif.id);
      },
      padding: const EdgeInsets.all(14),
      backgroundColor: cardBg,
      borderColor: cardBorder,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        notif.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              notif.isRead ? FontWeight.w600 : FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (!notif.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notif.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textMuted : AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppDateFormatter.formatWithTime(notif.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
