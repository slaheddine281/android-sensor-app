import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, destructive, ghost, outline }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final Color? customBackgroundColor;
  final Color? customForegroundColor;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
    this.customBackgroundColor,
    this.customForegroundColor,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
  })  : variant = AppButtonVariant.secondary,
        customBackgroundColor = null,
        customForegroundColor = null;

  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
  })  : variant = AppButtonVariant.destructive,
        customBackgroundColor = null,
        customForegroundColor = null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg;
    Color fg;
    BorderSide? border;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = customBackgroundColor ?? AppColors.primary;
        fg = customForegroundColor ?? Colors.white;
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? const Color(0xFF1E293B) : AppColors.background;
        fg = isDark ? Colors.white : AppColors.textPrimary;
        border = BorderSide(
          color: isDark ? const Color(0xFF334155) : AppColors.border,
          width: 1,
        );
        break;
      case AppButtonVariant.destructive:
        bg = AppColors.error;
        fg = Colors.white;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        fg = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;
        break;
    }

    Widget content;
    if (isLoading) {
      content = SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          valueColor: AlwaysStoppedAnimation<Color>(fg),
        ),
      );
    } else {
      content = Row(
        mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: fg),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      );
    }

    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: bg,
      foregroundColor: fg,
      disabledBackgroundColor: bg.withValues(alpha: 0.5),
      elevation: 0,
      side: border,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
    );

    final button = SizedBox(
      height: height,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        style: buttonStyle,
        onPressed: isLoading ? null : onPressed,
        child: content,
      ),
    );

    return button;
  }
}

/// Specialized pill-style Biometric Quick Login button from Screen 02
class BiometricQuickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const BiometricQuickButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : AppColors.divider,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E3A8A).withValues(alpha: 0.4)
                    : AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 20, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
