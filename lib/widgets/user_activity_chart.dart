import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class UserActivityChart extends StatefulWidget {
  const UserActivityChart({super.key});

  @override
  State<UserActivityChart> createState() => _UserActivityChartState();
}

class _UserActivityChartState extends State<UserActivityChart> {
  int _selectedPoint = 5; // Default selected is the latest month (Juin/Aujourd'hui)
  final List<String> _months = const ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin'];
  final List<int> _values = const [1, 1, 1, 2, 2, 2];

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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Croissance des utilisateurs',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tendance active et inscriptions',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Badge interactif sélectionné
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up_rounded,
                        size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${_months[_selectedPoint]}: ${_values[_selectedPoint]} util.',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Canvas de la courbe interactive
          SizedBox(
            height: 130,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final width = constraints.maxWidth;
                    final step = width / (_months.length - 1);
                    final tappedIdx =
                        (details.localPosition.dx / step).round().clamp(0, _months.length - 1);
                    setState(() {
                      _selectedPoint = tappedIdx;
                    });
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 130),
                    painter: _CurveChartPainter(
                      isDark: isDark,
                      selectedIndex: _selectedPoint,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Étiquettes cliquables pour chaque mois
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_months.length, (idx) {
              final isSel = idx == _selectedPoint;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPoint = idx;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSel
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _months[idx],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel
                          ? AppColors.primary
                          : (isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textMuted),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CurveChartPainter extends CustomPainter {
  final bool isDark;
  final int selectedIndex;

  _CurveChartPainter({
    this.isDark = false,
    this.selectedIndex = 5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Lignes de grille
    final gridColor = isDark ? const Color(0xFF334155) : AppColors.divider;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Points de données normalisés
    final points = [
      Offset(0, size.height * 0.85),
      Offset(size.width * 0.20, size.height * 0.80),
      Offset(size.width * 0.40, size.height * 0.70),
      Offset(size.width * 0.60, size.height * 0.45),
      Offset(size.width * 0.80, size.height * 0.35),
      Offset(size.width, size.height * 0.20),
    ];

    // Trajectoire courbe de Bézier
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Remplissage avec dégradé moderne
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.35),
          AppColors.primary.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Ligne principale de la courbe
    final strokePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);

    // Dessin des points
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isSel = i == selectedIndex;

      if (isSel) {
        // Halo de sélection
        final haloPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p, 10, haloPaint);

        // Ligne verticale de repère
        final markerPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(p.dx, 0), Offset(p.dx, size.height), markerPaint);
      }

      final dotOuter = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotPaint = Paint()
        ..color = isSel ? AppColors.secondary : AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, isSel ? 6 : 4.5, dotOuter);
      canvas.drawCircle(p, isSel ? 4.5 : 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CurveChartPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark;
  }
}
