import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/marketplace_product.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/product_rarity_badge.dart';
import 'character_customization_screen.dart';

class PurchaseSuccessScreen extends StatelessWidget {
  final MarketplaceProduct product;

  const PurchaseSuccessScreen({
    super.key,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Celebration Checkmark
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.secondary.withValues(alpha: 0.4),
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    color: AppColors.secondary,
                    size: 50,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title: Item Unlocked
              Text(
                'OBJET DÉBLOQUÉ !',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                '${product.name} a été ajouté à votre inventaire.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              // Product Preview Card
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: product.rarity.color
                            .withValues(alpha: isDark ? 0.25 : 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: product.rarity.color.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        product.iconData ?? Icons.inventory_2_outlined,
                        size: 40,
                        color: product.rarity.color,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ProductRarityBadge(rarity: product.rarity),
                    if (product.bonusValue != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${product.bonusType}: ${product.bonusValue}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              AppButton(
                label: 'ÉQUIPER MAINTENANT',
                icon: Icons.checkroom_rounded,
                onPressed: () {
                  final user = context.auth.currentUser ?? context.users.allUsers.first;
                  context.marketplace.equipProduct(
                    product: product,
                    inventory: context.inventory,
                    notificationState: context.notifications,
                    userId: user.id,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} est maintenant équipé !'),
                      backgroundColor: AppColors.secondary,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const CharacterCustomizationScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              AppButton(
                label: 'CONTINUER MES ACHATS',
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
