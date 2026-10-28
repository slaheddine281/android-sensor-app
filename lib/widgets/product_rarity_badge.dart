import 'package:flutter/material.dart';
import '../models/product_rarity.dart';

class ProductRarityBadge extends StatelessWidget {
  final ProductRarity rarity;
  final bool showIcon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const ProductRarityBadge({
    super.key,
    required this.rarity,
    this.showIcon = true,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark
        ? rarity.color.withValues(alpha: 0.18)
        : rarity.softColor;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: rarity.color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              rarity.icon,
              size: fontSize + 2,
              color: rarity.color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            rarity.label,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: rarity.color,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
