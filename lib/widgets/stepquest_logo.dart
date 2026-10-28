import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class StepQuestLogo extends StatelessWidget {
  final double size;
  final bool isLight; // White text for dark/navy backgrounds
  final bool showTagline;
  final String? customTagline;

  const StepQuestLogo({
    super.key,
    this.size = 48,
    this.isLight = false,
    this.showTagline = false,
    this.customTagline,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = isLight || Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Custom drawn stylized StepQuest running figure / pulse emblem
            _StepQuestIcon(size: size),
            const SizedBox(width: 12),
            Text(
              'StepQuest',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: size * 0.58,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.navyHeader,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: 6),
          Text(
            customTagline ?? 'Atteins tes objectifs',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _StepQuestIcon extends StatelessWidget {
  final double size;

  const _StepQuestIcon({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.7, size * 0.7),
          painter: _LogoPainter(),
        ),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintBlue = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    final paintDark = Paint()
      ..color = AppColors.navyHeader
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round;

    // Head circle
    canvas.drawCircle(
      Offset(size.width * 0.65, size.height * 0.22),
      size.width * 0.14,
      paintBlue,
    );

    // Dynamic curved body (running swoop)
    final pathBody = Path();
    pathBody.moveTo(size.width * 0.60, size.height * 0.42);
    pathBody.cubicTo(
      size.width * 0.40, size.height * 0.45,
      size.width * 0.25, size.height * 0.65,
      size.width * 0.35, size.height * 0.88,
    );
    pathBody.cubicTo(
      size.width * 0.50, size.height * 0.75,
      size.width * 0.70, size.height * 0.60,
      size.width * 0.60, size.height * 0.42,
    );
    canvas.drawPath(pathBody, paintBlue);

    // Pulse / step accent on side
    final pathStep = Path();
    pathStep.moveTo(size.width * 0.15, size.height * 0.65);
    pathStep.lineTo(size.width * 0.30, size.height * 0.55);
    pathStep.lineTo(size.width * 0.45, size.height * 0.70);
    canvas.drawPath(pathStep, paintDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
