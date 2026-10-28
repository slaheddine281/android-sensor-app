import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class RoleBadge extends StatelessWidget {
  final UserRole role;
  final bool compact;

  const RoleBadge({
    super.key,
    required this.role,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isAdmin = role == UserRole.admin;
    final color = isAdmin
        ? AppColors.primaryLight
        : (isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary);
    final bgColor = isAdmin
        ? (isDark
            ? const Color(0xFF1E3A8A).withValues(alpha: 0.35)
            : AppColors.primarySoft)
        : (isDark ? const Color(0xFF334155) : AppColors.background);
    final borderColor = isAdmin
        ? AppColors.primary.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF475569) : AppColors.border);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAdmin ? Icons.admin_panel_settings : Icons.person_outline,
            size: compact ? 12 : 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isAdmin ? 'Admin' : 'Utilisateur',
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
