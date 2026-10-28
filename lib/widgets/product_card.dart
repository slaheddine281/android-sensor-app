import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/marketplace_product.dart';
import 'app_card.dart';
import 'product_price.dart';
import 'product_rarity_badge.dart';

class ProductCard extends StatelessWidget {
  final MarketplaceProduct product;
  final VoidCallback onTap;
  final bool isOwned;
  final bool isEquipped;
  final bool isInWishlist;
  final VoidCallback? onWishlistToggle;
  final int userLevel;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isOwned = false,
    this.isEquipped = false,
    this.isInWishlist = false,
    this.onWishlistToggle,
    this.userLevel = 1,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLevelLocked = userLevel < product.levelRequired;

    return AppCard(
      width: width,
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual Area with Rarity Gradient
          Stack(
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      product.rarity.color.withValues(alpha: isDark ? 0.35 : 0.15),
                      product.rarity.color.withValues(alpha: isDark ? 0.10 : 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Hero(
                    tag: 'product-icon-${product.id}',
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.navyCard
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: product.rarity.color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: product.rarity.color.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        product.iconData ?? Icons.inventory_2_outlined,
                        size: 30,
                        color: product.rarity.color,
                      ),
                    ),
                  ),
                ),
              ),

              // Rarity Badge top-left
              Positioned(
                top: 8,
                left: 8,
                child: ProductRarityBadge(rarity: product.rarity, fontSize: 10),
              ),

              // Wishlist button top-right
              if (onWishlistToggle != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    iconSize: 20,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isInWishlist
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isInWishlist ? AppColors.error : AppColors.textMuted,
                    ),
                    onPressed: onWishlistToggle,
                  ),
                ),

              // Status badges bottom-left (Owned / Equipped / Locked)
              Positioned(
                bottom: 8,
                left: 8,
                child: Row(
                  children: [
                    if (isEquipped)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Équipé',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (isOwned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A8A) : AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Text(
                          'Possédé',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      ),
                    if (isLevelLocked && !isOwned)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              'Niv. ${product.levelRequired}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Content Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),

                // Bonus pill if present
                if (product.bonusValue != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF064E3B).withValues(alpha: 0.35)
                          : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${product.bonusType ?? "Bonus"}: ${product.bonusValue}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ] else
                  const SizedBox(height: 6),

                // Price Row
                ProductPrice(product: product, fontSize: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
