import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class UserActivityChart extends StatelessWidget {
  const UserActivityChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyCard : Colors.white;
    final border = isDark ? const Color(0xFF334155) : AppColors.divider;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Text(
            'Évolution des utilisateurs',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: CustomPaint(
              painter: _CurveChartPainter(isDark: isDark),
              child: Container(),
            ),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MonthLabel('Jan'),
              _MonthLabel('Fév'),
              _MonthLabel('Mar'),
              _MonthLabel('Avr'),
              _MonthLabel('Mai'),
              _MonthLabel('Juin'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  final String label;
  const _MonthLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        color: isDark ? const Color(0xFF94A3B8) : AppColors.textMuted,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

class _CurveChartPainter extends CustomPainter {
  final bool isDark;
  _CurveChartPainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    // Background subtle grid lines
    final gridColor = isDark ? const Color(0xFF334155) : AppColors.divider;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Normalized points for Jan to Juin (values 0.0 to 1.0)
    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.20, size.height * 0.75),
      Offset(size.width * 0.40, size.height * 0.60),
      Offset(size.width * 0.60, size.height * 0.50),
      Offset(size.width * 0.80, size.height * 0.35),
      Offset(size.width, size.height * 0.20),
    ];

    // Build smooth cubic bezier curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Gradient fill path
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.25),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke path
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Point dots
    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
    final dotOuter = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotOuter);
      canvas.drawCircle(p, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
