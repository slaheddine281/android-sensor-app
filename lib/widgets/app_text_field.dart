import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  final String? label;
  final String hint;
  final TextEditingController? controller;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool readOnly;
  final bool isDarkTheme;
  final int maxLines;

  const AppTextField({
    super.key,
    this.label,
    required this.hint,
    this.controller,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.readOnly = false,
    this.isDarkTheme = false,
    this.maxLines = 1,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) {
    final isDark =
        widget.isDarkTheme || Theme.of(context).brightness == Brightness.dark;

    final fillColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : AppColors.divider;
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final hintColor = isDark ? const Color(0xFF94A3B8) : AppColors.textMuted;
    final iconColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    Widget? suffix;
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: iconColor,
          size: 20,
        ),
        onPressed: () {
          setState(() {
            _obscured = !_obscured;
          });
        },
      );
    } else {
      suffix = widget.suffixIcon;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        TextFormField(
          controller: widget.controller,
          initialValue: widget.initialValue,
          obscureText: widget.isPassword && _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          maxLines: widget.maxLines,
          style: TextStyle(fontSize: 15, color: textColor),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(fontSize: 14, color: hintColor),
            filled: true,
            fillColor: fillColor,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: iconColor, size: 20)
                : null,
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
          ),
        ),
      ],
    );
  }
}
