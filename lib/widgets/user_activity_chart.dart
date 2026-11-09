import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../state/app_state_provider.dart';

class UserActivityChart extends StatefulWidget {
  const UserActivityChart({super.key});

  @override
  State<UserActivityChart> createState() => _UserActivityChartState();
}

class _UserActivityChartState extends State<UserActivityChart> {
  int _selectedPoint = 5; // Default: mois actuel (dernier point)
  bool _showCumulative = true; // Mode cumulatif par défaut

  static const List<String> _monthNamesFr = [
    'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
    'Juil', 'Août', 'Sept', 'Oct', 'Nov', 'Déc'
  ];

  @override
  Widget build(BuildContext context) {
    final allUsers = context.users.allUsers;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyCard : Colors.white;
    final border = isDark ? const Color(0xFF1E293B) : AppColors.divider;
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;

    // Calcul dynamique des 6 derniers mois jusqu'au mois actuel
    final now = DateTime.now();
    final List<String> monthLabels = [];
    final List<int> values = [];

    for (int i = 5; i >= 0; i--) {
      // Mois cible
      final yearOffset = (now.month - i - 1) ~/ 12;
      final targetMonth = ((now.month - i - 1) % 12 + 12) % 12 + 1;
      final targetYear = now.year + yearOffset;
      final monthName = _monthNamesFr[targetMonth - 1];
      monthLabels.add(monthName);

      if (_showCumulative) {
        // Nombre total d'utilisateurs inscrits jusqu'à la fin de ce mois
        final endOfMonth = DateTime(targetYear, targetMonth + 1, 0, 23, 59, 59);
        final count =
            allUsers.where((u) => u.createdAt.isBefore(endOfMonth)).length;
        values.add(count);
      } else {
        // Nouvelles inscriptions spécifiques à ce mois
        final count = allUsers
            .where((u) =>
                u.createdAt.year == targetYear &&
                u.createdAt.month == targetMonth)
            .length;
        values.add(count);
      }
    }

    if (_selectedPoint >= values.length) {
      _selectedPoint = values.length - 1;
    }

    final selectedCount = values.isNotEmpty ? values[_selectedPoint] : 0;
    final selectedMonth =
        monthLabels.isNotEmpty ? monthLabels[_selectedPoint] : '';

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
          // En-tête avec titre et sélecteur de mode (Cumulatif vs Inscriptions)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
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
                  const SizedBox(height: 2),
                  Text(
                    _showCumulative
                        ? 'Total des comptes enregistrés'
                        : 'Nouvelles inscriptions par mois',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              // Bouton bascule mode
              InkWell(
                onTap: () {
                  setState(() {
                    _showCumulative = !_showCumulative;
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : AppColors.divider,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showCumulative
                            ? Icons.stacked_line_chart_rounded
                            : Icons.bar_chart_rounded,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _showCumulative ? 'Cumulé' : 'Inscriptions',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Badge de la donnée réelle sélectionnée
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.circle, size: 8, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '$selectedMonth : $selectedCount utilisateur${selectedCount > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Zone du graphique interactif basé sur les données réelles
          SizedBox(
            height: 130,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapDown: (details) {
                    final width = constraints.maxWidth;
                    final step = width / (monthLabels.length - 1);
                    final tappedIdx = (details.localPosition.dx / step)
                        .round()
                        .clamp(0, monthLabels.length - 1);
                    setState(() {
                      _selectedPoint = tappedIdx;
                    });
                  },
                  child: CustomPaint(
                    size: Size(constraints.maxWidth, 130),
                    painter: _RealDataCurvePainter(
                      values: values,
                      selectedIndex: _selectedPoint,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Mois réels affichés sur l'axe X
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(monthLabels.length, (idx) {
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
                    monthLabels[idx],
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

class _RealDataCurvePainter extends CustomPainter {
  final List<int> values;
  final int selectedIndex;
  final bool isDark;

  _RealDataCurvePainter({
    required this.values,
    required this.selectedIndex,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    // Lignes de repère horizontales
    final gridColor = isDark ? const Color(0xFF334155) : AppColors.divider;
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calcul du maximum réel pour l'échelle dynamique (minimum 1 pour éviter div par 0)
    final maxVal = max(1, values.fold<int>(0, (m, v) => max(m, v)));
    final double stepX = size.width / (values.length - 1);
    final double topMargin = 16.0;
    final double bottomMargin = 16.0;
    final double usableHeight = size.height - topMargin - bottomMargin;

    // Calcul des coordonnées réelles de chaque point
    final List<Offset> points = [];
    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      // Plus la valeur est élevée, plus y est petit (vers le haut)
      final normalized = values[i] / maxVal;
      final y = (size.height - bottomMargin) - (normalized * usableHeight);
      points.add(Offset(x, y));
    }

    // Tracé de la courbe Bézier fluide
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // Remplissage avec dégradé sous la courbe
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withValues(alpha: 0.3),
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

    // Dessin de chaque point réel
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isSel = i == selectedIndex;

      if (isSel) {
        // Halo lumineux pour le point sélectionné
        final haloPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(p, 9, haloPaint);

        // Ligne verticale de repère
        final markerPaint = Paint()
          ..color = AppColors.primary.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
        canvas.drawLine(
            Offset(p.dx, 0), Offset(p.dx, size.height), markerPaint);
      }

      final dotOuter = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final dotPaint = Paint()
        ..color = isSel ? AppColors.secondary : AppColors.primary
        ..style = PaintingStyle.fill;

      canvas.drawCircle(p, isSel ? 5.5 : 4.0, dotOuter);
      canvas.drawCircle(p, isSel ? 4.0 : 2.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealDataCurvePainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.isDark != isDark ||
        oldDelegate.values != values;
  }
}
