import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class CoinBalance extends StatelessWidget {
  final int balance;
  final VoidCallback? onTap;
  final bool isCompact;

  const CoinBalance({
    super.key,
    required this.balance,
    this.onTap,
    this.isCompact = false,
  });

  String _formatBalance(int value) {
    // e.g. 1 250 with space separator
    final str = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 10 : 12,
          vertical: isCompact ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B)
              : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.45),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: isCompact ? 18 : 20,
              height: isCompact ? 18 : 20,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Text(
                  '🪙',
                  style: TextStyle(fontSize: isCompact ? 11 : 12),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _formatBalance(balance),
              style: TextStyle(
                fontSize: isCompact ? 13 : 14,
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
                letterSpacing: 0.2,
              ),
            ),
            if (!isCompact) ...[
              const SizedBox(width: 3),
              Text(
                'Coins',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
