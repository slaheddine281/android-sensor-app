import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class PasswordStrengthResult {
  final int score; // 0 à 4
  final String label;
  final Color color;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasDigit;
  final bool hasSpecialChar;

  const PasswordStrengthResult({
    required this.score,
    required this.label,
    required this.color,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasDigit,
    required this.hasSpecialChar,
  });

  static PasswordStrengthResult evaluate(String password) {
    if (password.isEmpty) {
      return const PasswordStrengthResult(
        score: 0,
        label: 'Non renseigné',
        color: AppColors.textMuted,
        hasMinLength: false,
        hasUppercase: false,
        hasLowercase: false,
        hasDigit: false,
        hasSpecialChar: false,
      );
    }

    final hasMinLength = password.length >= 8;
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    final hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]').hasMatch(password);

    int score = 0;
    if (hasMinLength) score++;
    if (hasUppercase && hasLowercase) score++;
    if (hasDigit) score++;
    if (hasSpecialChar) score++;

    String label;
    Color color;

    switch (score) {
      case 0:
      case 1:
        label = 'Faible';
        color = const Color(0xFFEF4444); // Rouge
        break;
      case 2:
        label = 'Moyen';
        color = const Color(0xFFF59E0B); // Ambre / Jaune
        break;
      case 3:
        label = 'Bon';
        color = const Color(0xFF3B82F6); // Bleu vif
        break;
      case 4:
      default:
        label = 'Très fort';
        color = const Color(0xFF10B981); // Émeraude / Vert
        break;
    }

    return PasswordStrengthResult(
      score: score,
      label: label,
      color: color,
      hasMinLength: hasMinLength,
      hasUppercase: hasUppercase,
      hasLowercase: hasLowercase,
      hasDigit: hasDigit,
      hasSpecialChar: hasSpecialChar,
    );
  }
}

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final bool showCriteria;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.showCriteria = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = PasswordStrengthResult.evaluate(password);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Barre de force (4 segments)
        Row(
          children: [
            for (int i = 1; i <= 4; i++)
              Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                  decoration: BoxDecoration(
                    color: i <= result.score
                        ? result.color
                        : (isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Text(
              result.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: result.color,
              ),
            ),
          ],
        ),

        if (showCriteria) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF0F172A).withValues(alpha: 0.6)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                _buildCriterionItem(
                  'Au moins 8 caractères',
                  result.hasMinLength,
                  isDark,
                ),
                const SizedBox(height: 4),
                _buildCriterionItem(
                  'Majuscule (A-Z) & Minuscule (a-z)',
                  result.hasUppercase && result.hasLowercase,
                  isDark,
                ),
                const SizedBox(height: 4),
                _buildCriterionItem(
                  'Au moins un chiffre (0-9)',
                  result.hasDigit,
                  isDark,
                ),
                const SizedBox(height: 4),
                _buildCriterionItem(
                  'Caractère spécial (!@#\$%...)',
                  result.hasSpecialChar,
                  isDark,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCriterionItem(String text, bool isMet, bool isDark) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          size: 14,
          color: isMet
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46))
                  : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ),
        ),
      ],
    );
  }
}

