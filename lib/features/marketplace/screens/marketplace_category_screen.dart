import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/product_category.dart';
import '../../../models/product_rarity.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import 'product_details_screen.dart';

class MarketplaceCategoryScreen extends StatefulWidget {
  final ProductCategory category;

  const MarketplaceCategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<MarketplaceCategoryScreen> createState() =>
      _MarketplaceCategoryScreenState();
}

class _MarketplaceCategoryScreenState extends State<MarketplaceCategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  ProductRarity? _selectedRarity;
  String _sortBy = 'featured'; // 'price_asc', 'price_desc', 'rarity', 'level'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marketplace = context.marketplace;
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final inventory = context.inventory;

    final products = marketplace.searchProducts(
      query: _searchController.text,
      category: widget.category,
      rarity: _selectedRarity,
      sortBy: _sortBy,
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: widget.category.label,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.sort_rounded,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            tooltip: 'Trier les objets',
            initialValue: _sortBy,
            onSelected: (val) {
              setState(() => _sortBy = val);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'featured',
                child: Text('Recommandés'),
              ),
              const PopupMenuItem(
                value: 'price_asc',
                child: Text('Prix croissant (Coins)'),
              ),
              const PopupMenuItem(
                value: 'price_desc',
                child: Text('Prix décroissant (Coins)'),
              ),
              const PopupMenuItem(
                value: 'rarity',
                child: Text('Rareté'),
              ),
              const PopupMenuItem(
                value: 'level',
                child: Text('Niveau requis'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.navyCard : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : AppColors.divider,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Rechercher dans ${widget.category.label}...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark ? const Color(0xFF64748B) : AppColors.textMuted,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ),

            // Rarity Filter Pills
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                children: [
                  _buildRarityFilterChip(label: 'Tous', rarity: null, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildRarityFilterChip(
                      label: 'Commun', rarity: ProductRarity.common, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildRarityFilterChip(
                      label: 'Rare', rarity: ProductRarity.rare, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildRarityFilterChip(
                      label: 'Épique', rarity: ProductRarity.epic, isDark: isDark),
                  const SizedBox(width: 8),
                  _buildRarityFilterChip(
                      label: 'Légendaire',
                      rarity: ProductRarity.legendary,
                      isDark: isDark),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? const Color(0xFF1E293B) : AppColors.divider,
            ),

            // Products Responsive Grid
            Expanded(
              child: products.isEmpty
                  ? EmptyState(
                      icon: Icons.filter_alt_off_outlined,
                      title: 'Aucun objet trouvé',
                      description:
                          'Aucun objet de cette catégorie ne correspond à vos filtres actuels.',
                      action: TextButton(
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _selectedRarity = null;
                            _sortBy = 'featured';
                          });
                        },
                        child: const Text('Réinitialiser les filtres'),
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isTabletOrDesktop = constraints.maxWidth >= 600;
                        final crossAxisCount = isTabletOrDesktop ? 3 : 2;

                        return GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: products.length,
                          itemBuilder: (context, index) {
                            final product = products[index];
                            final isOwned = inventory.hasItem(product.id);
                            final isEquipped = inventory.isEquipped(product.id);
                            final isInWishlist =
                                marketplace.isInWishlist(product.id);

                            return ProductCard(
                              product: product,
                              userLevel: user.level,
                              isOwned: isOwned,
                              isEquipped: isEquipped,
                              isInWishlist: isInWishlist,
                              onWishlistToggle: () {
                                marketplace.toggleWishlist(product.id);
                              },
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailsScreen(
                                      product: product,
                                    ),
                                  ),
                                );
                              },
                            );
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

  Widget _buildRarityFilterChip({
    required String label,
    required ProductRarity? rarity,
    required bool isDark,
  }) {
    final isSelected = _selectedRarity == rarity;
    final color = rarity?.color ?? AppColors.primary;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedRarity = rarity);
      },
      selectedColor: color,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? Colors.white
            : (isDark ? Colors.white70 : AppColors.textPrimary),
      ),
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF334155) : AppColors.divider),
        ),
      ),
      showCheckmark: false,
    );
  }
}
