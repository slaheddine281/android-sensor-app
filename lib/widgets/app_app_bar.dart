import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isDarkTheme;

  const AppAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isDarkTheme = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final effectiveDark =
        isDarkTheme || Theme.of(context).brightness == Brightness.dark;
    final fg = foregroundColor ??
        (effectiveDark ? Colors.white : AppColors.textPrimary);
    final bg = backgroundColor ??
        (effectiveDark ? AppColors.navyCard : Colors.white);

    Widget? effectiveLeading = leading;
    if (effectiveLeading == null && showBackButton && Navigator.canPop(context)) {
      effectiveLeading = IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        color: fg,
        onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
      );
    }

    return AppBar(
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: 0,
      centerTitle: true,
      title: Text(
        title,
        style: AppTextStyles.titleMedium.copyWith(color: fg),
      ),
      leading: effectiveLeading,
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: effectiveDark
              ? const Color(0xFF334155)
              : AppColors.divider,
          height: 1,
        ),
      ),
    );
  }
}
