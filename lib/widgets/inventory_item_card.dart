import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/inventory_item.dart';
import '../models/marketplace_product.dart';
import 'app_button.dart';
import 'app_card.dart';
import 'product_rarity_badge.dart';

class InventoryItemCard extends StatelessWidget {
  final InventoryItem item;
  final MarketplaceProduct product;
  final VoidCallback onEquipToggle;
  final VoidCallback onTapDetails;

  const InventoryItemCard({
    super.key,
    required this.item,
    required this.product,
    required this.onEquipToggle,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTapDetails,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container with Rarity border
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: product.rarity.color.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: product.rarity.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              product.iconData ?? Icons.inventory_2_outlined,
              size: 28,
              color: product.rarity.color,
            ),
          ),
          const SizedBox(width: 14),

          // Details info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ProductRarityBadge(rarity: product.rarity, fontSize: 10),
                    const SizedBox(width: 6),
                    Text(
                      product.category.label,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (product.bonusValue != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${product.bonusType}: ${product.bonusValue}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Equip / Unequip Button
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item.isEquipped)
                AppButton(
                  label: 'Déséquiper',
                  height: 36,
                  isFullWidth: false,
                  variant: AppButtonVariant.secondary,
                  onPressed: onEquipToggle,
                )
              else
                AppButton(
                  label: 'Équiper',
                  height: 36,
                  isFullWidth: false,
                  variant: AppButtonVariant.primary,
                  onPressed: onEquipToggle,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
