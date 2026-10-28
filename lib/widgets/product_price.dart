import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/marketplace_product.dart';

class ProductPrice extends StatelessWidget {
  final MarketplaceProduct product;
  final double fontSize;
  final bool showDiscountTag;

  const ProductPrice({
    super.key,
    required this.product,
    this.fontSize = 15,
    this.showDiscountTag = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasDiscount = product.hasDiscount;

    return Wrap(
      spacing: 4,
      runSpacing: 2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          '🪙',
          style: TextStyle(fontSize: 13),
        ),
        Text(
          '${product.effectivePrice}',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309),
            letterSpacing: -0.2,
          ),
        ),
        Text(
          'Coins',
          style: TextStyle(
            fontSize: fontSize * 0.72,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
        if (hasDiscount) ...[
          const SizedBox(width: 4),
          Text(
            '${product.price}',
            style: TextStyle(
              fontSize: fontSize * 0.75,
              fontWeight: FontWeight.w500,
              decoration: TextDecoration.lineThrough,
              color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
            ),
          ),
          if (showDiscountTag) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '-${product.discountPercentage}%',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}
