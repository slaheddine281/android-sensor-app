import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import 'app_button.dart';

enum ConfirmationDialogType {
  warning(
    icon: Icons.priority_high_rounded,
    iconColor: AppColors.tertiary,
    iconBgColor: AppColors.tertiarySoft,
  ),
  danger(
    icon: Icons.error_outline_rounded,
    iconColor: AppColors.error,
    iconBgColor: AppColors.errorSoft,
  ),
  info(
    icon: Icons.info_outline_rounded,
    iconColor: AppColors.primary,
    iconBgColor: AppColors.primarySoft,
  );

  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  const ConfirmationDialogType({
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String description;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final ConfirmationDialogType type;
  final bool isDestructive;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    this.cancelLabel = 'Annuler',
    required this.onConfirm,
    this.onCancel,
    this.type = ConfirmationDialogType.danger,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent circular alert badge matching Screen 16
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: type.iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  type.icon,
                  color: type.iconColor,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: confirmLabel,
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
              variant: isDestructive
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
            ),
            const SizedBox(height: 10),
            AppButton(
              label: cancelLabel,
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onCancel != null) onCancel!();
              },
              variant: AppButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String description,
  required String confirmLabel,
  String cancelLabel = 'Annuler',
  required VoidCallback onConfirm,
  ConfirmationDialogType type = ConfirmationDialogType.danger,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => ConfirmationDialog(
      title: title,
      description: description,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      onConfirm: onConfirm,
      type: type,
      isDestructive: isDestructive,
    ),
  );
}

