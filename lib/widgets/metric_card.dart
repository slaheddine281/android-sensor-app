import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final IconData? icon;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyCard : Colors.white;
    final border = isDark ? const Color(0xFF334155) : AppColors.divider;
    final labelColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
    final valColor = (valueColor == AppColors.textPrimary && isDark)
        ? Colors.white
        : valueColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: valColor,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
