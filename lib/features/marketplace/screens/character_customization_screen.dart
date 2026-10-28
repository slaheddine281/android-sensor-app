import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/marketplace_product.dart';
import '../../../models/product_category.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/product_rarity_badge.dart';
import '../../../widgets/user_avatar.dart';
import 'marketplace_category_screen.dart';

class CharacterCustomizationScreen extends StatefulWidget {
  const CharacterCustomizationScreen({super.key});

  @override
  State<CharacterCustomizationScreen> createState() =>
      _CharacterCustomizationScreenState();
}

class _CharacterCustomizationScreenState
    extends State<CharacterCustomizationScreen> {
  void _openSlotSelector(ProductCategory category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventory = context.inventory;
    final marketplace = context.marketplace;
    final catalog = marketplace.allProducts;
    final user = context.auth.currentUser ?? context.users.allUsers.first;

    // Get all owned products in this category
    final ownedItems = inventory.items.where((item) {
      final p = catalog.where((prod) => prod.id == item.productId).firstOrNull;
      return p != null && p.category == category;
    }).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Équiper : ${category.label}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ownedItems.isEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            category.icon,
                            size: 48,
                            color: isDark
                                ? const Color(0xFF64748B)
                                : AppColors.textMuted,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun objet possédé dans cette catégorie',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Acheter dans la boutique',
                            isFullWidth: false,
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => MarketplaceCategoryScreen(
                                      category: category),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: ownedItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = ownedItems[index];
                        final product = catalog
                            .where((p) => p.id == item.productId)
                            .firstOrNull;
                        if (product == null) return const SizedBox.shrink();

                        return AppCard(
                          padding: const EdgeInsets.all(12),
                          borderColor: item.isEquipped ? AppColors.secondary : null,
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: product.rarity.color
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  product.iconData ?? Icons.inventory_2_outlined,
                                  color: product.rarity.color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? Colors.white
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        ProductRarityBadge(
                                            rarity: product.rarity, fontSize: 9),
                                        if (product.bonusValue != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            product.bonusValue!,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.secondary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (item.isEquipped)
                                TextButton(
                                  onPressed: () {
                                    marketplace.unequipProduct(
                                      product: product,
                                      inventory: inventory,
                                      notificationState: context.notifications,
                                      userId: user.id,
                                    );
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Déséquiper'),
                                )
                              else
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                  ),
                                  onPressed: () {
                                    marketplace.equipProduct(
                                      product: product,
                                      inventory: inventory,
                                      notificationState: context.notifications,
                                      userId: user.id,
                                    );
                                    Navigator.of(ctx).pop();
                                  },
                                  child: const Text('Équiper'),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final inventory = context.inventory;
    final marketplace = context.marketplace;
    final catalog = marketplace.allProducts;

    // Equipped products by slot
    final equippedOutfit = _getEquippedProduct(ProductCategory.outfits, catalog, inventory);
    final equippedShoes = _getEquippedProduct(ProductCategory.shoes, catalog, inventory);
    final equippedBackpack = _getEquippedProduct(ProductCategory.backpacks, catalog, inventory);
    final equippedAccessory = _getEquippedProduct(ProductCategory.accessories, catalog, inventory);

    // Active bonuses summary
    final activeBonuses = [
      if (equippedOutfit?.bonusValue != null) '${equippedOutfit!.bonusType}: ${equippedOutfit.bonusValue}',
      if (equippedShoes?.bonusValue != null) '${equippedShoes!.bonusType}: ${equippedShoes.bonusValue}',
      if (equippedBackpack?.bonusValue != null) '${equippedBackpack!.bonusType}: ${equippedBackpack.bonusValue}',
      if (equippedAccessory?.bonusValue != null) '${equippedAccessory!.bonusType}: ${equippedAccessory.bonusValue}',
    ];

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Personnalisation du Héros',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero RPG Avatar & Mannequin Showcase
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow ring
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.35),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        UserAvatar(user: user, radius: 46),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E3A8A)
                                : AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Niveau ${user.level} Marcheur',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active RPG Bonuses pill summary
                    if (activeBonuses.isNotEmpty) ...[
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.flash_on_rounded,
                              size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 6),
                          Text(
                            'Bonus d\'équipement actifs (${activeBonuses.length}) :',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: activeBonuses.map((bonus) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.secondary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              bonus,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.secondary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Equipment Slots Title
              Text(
                'Emplacements d\'équipement RPG',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Slot 1: Outfits
              _buildGearSlotCard(
                category: ProductCategory.outfits,
                equippedProduct: equippedOutfit,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Slot 2: Shoes
              _buildGearSlotCard(
                category: ProductCategory.shoes,
                equippedProduct: equippedShoes,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Slot 3: Backpack
              _buildGearSlotCard(
                category: ProductCategory.backpacks,
                equippedProduct: equippedBackpack,
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              // Slot 4: Accessories
              _buildGearSlotCard(
                category: ProductCategory.accessories,
                equippedProduct: equippedAccessory,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  MarketplaceProduct? _getEquippedProduct(
    ProductCategory category,
    List<MarketplaceProduct> catalog,
    dynamic inventory,
  ) {
    for (final item in inventory.items) {
      if (!item.isEquipped) continue;
      final product = catalog.where((p) => p.id == item.productId).firstOrNull;
      if (product != null && product.category == category) {
        return product;
      }
    }
    return null;
  }

  Widget _buildGearSlotCard({
    required ProductCategory category,
    required MarketplaceProduct? equippedProduct,
    required bool isDark,
  }) {
    final hasItem = equippedProduct != null;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Slot Icon container
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: hasItem
                  ? equippedProduct.rarity.color.withValues(alpha: isDark ? 0.25 : 0.12)
                  : (isDark ? const Color(0xFF1E293B) : AppColors.background),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasItem
                    ? equippedProduct.rarity.color.withValues(alpha: 0.5)
                    : (isDark ? const Color(0xFF334155) : AppColors.divider),
                width: 1.5,
              ),
            ),
            child: Icon(
              hasItem
                  ? (equippedProduct.iconData ?? category.icon)
                  : category.icon,
              color: hasItem
                  ? equippedProduct.rarity.color
                  : (isDark ? const Color(0xFF64748B) : AppColors.textMuted),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),

          // Slot Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasItem ? equippedProduct.name : 'Aucun objet équipé',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: hasItem
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : (isDark ? const Color(0xFF64748B) : AppColors.textMuted),
                  ),
                ),
                if (hasItem && equippedProduct.bonusValue != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      ProductRarityBadge(rarity: equippedProduct.rarity, fontSize: 9),
                      const SizedBox(width: 6),
                      Text(
                        '${equippedProduct.bonusType}: ${equippedProduct.bonusValue}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Change / Equip Button
          AppButton(
            label: hasItem ? 'Changer' : 'Équiper',
            isFullWidth: false,
            height: 36,
            variant: hasItem
                ? AppButtonVariant.secondary
                : AppButtonVariant.primary,
            onPressed: () => _openSlotSelector(category),
          ),
        ],
      ),
    );
  }
}
