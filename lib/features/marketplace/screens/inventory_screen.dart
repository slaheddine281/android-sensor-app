import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_category.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/inventory_item_card.dart';
import 'character_customization_screen.dart';
import 'product_details_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  ProductCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inventory = context.inventory;
    final marketplace = context.marketplace;
    final user = context.auth.currentUser ?? context.users.allUsers.first;

    final catalog = marketplace.allProducts;
    final allItems = inventory.items;

    // Filter by category if selected
    final filteredItems = allItems.where((item) {
      if (_selectedCategory == null) return true;
      final product = catalog.where((p) => p.id == item.productId).firstOrNull;
      return product != null && product.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Mon Inventaire',
        actions: [
          IconButton(
            icon: const Icon(Icons.accessibility_new_rounded),
            tooltip: 'Personnaliser le personnage',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CharacterCustomizationScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Quick banner to Character Customization
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CharacterCustomizationScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.style_rounded, color: Colors.white, size: 22),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Personnaliser mon héros RPG',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Visualisez et équipez vos tenues actives',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Category Chips Bar
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  CategoryChip(
                    label: 'Tous',
                    isSelected: _selectedCategory == null,
                    count: allItems.length,
                    onTap: () => setState(() => _selectedCategory = null),
                  ),
                  const SizedBox(width: 8),
                  ...ProductCategory.values.map((cat) {
                    final count = allItems.where((item) {
                      final p = catalog.where((prod) => prod.id == item.productId).firstOrNull;
                      return p != null && p.category == cat;
                    }).length;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: CategoryChip(
                        label: cat.label,
                        icon: cat.icon,
                        count: count > 0 ? count : null,
                        isSelected: _selectedCategory == cat,
                        onTap: () => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
            ),

            // Inventory List
            Expanded(
              child: filteredItems.isEmpty
                  ? EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Inventaire vide',
                      description: _selectedCategory == null
                          ? 'Vous n\'avez pas encore d\'objets. Visitez la boutique pour débloquer votre premier équipement !'
                          : 'Aucun objet trouvé dans la catégorie ${_selectedCategory!.label}.',
                      action: AppButton(
                        label: 'Visiter la boutique',
                        isFullWidth: false,
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final product = catalog
                            .where((p) => p.id == item.productId)
                            .firstOrNull;

                        if (product == null) return const SizedBox.shrink();

                        return InventoryItemCard(
                          item: item,
                          product: product,
                          onTapDetails: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailsScreen(product: product),
                              ),
                            );
                          },
                          onEquipToggle: () {
                            if (item.isEquipped) {
                              marketplace.unequipProduct(
                                product: product,
                                inventory: inventory,
                                notificationState: context.notifications,
                                userId: user.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${product.name} a été retiré de l\'équipement.'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            } else {
                              marketplace.equipProduct(
                                product: product,
                                inventory: inventory,
                                notificationState: context.notifications,
                                userId: user.id,
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${product.name} est maintenant équipé !'),
                                  backgroundColor: AppColors.secondary,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
