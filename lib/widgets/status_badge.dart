import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/app_user.dart';

class StatusBadge extends StatelessWidget {
  final UserStatus status;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = status == UserStatus.active;
    final dotColor = isActive ? AppColors.secondary : AppColors.error;
    final bgColor = isDark
        ? (isActive
            ? const Color(0xFF064E3B).withValues(alpha: 0.5)
            : const Color(0xFF7F1D1D).withValues(alpha: 0.5))
        : (isActive ? AppColors.secondarySoft : AppColors.errorSoft);
    final textColor = isDark
        ? (isActive ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5))
        : (isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B));

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dotColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
