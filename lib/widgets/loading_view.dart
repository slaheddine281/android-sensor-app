import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class LoadingView extends StatelessWidget {
  final String? message;
  final bool isDark;

  const LoadingView({
    super.key,
    this.message,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
