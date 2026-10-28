import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/marketplace_product.dart';
import '../../../models/product_category.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_bottom_navigation.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/category_chip.dart';
import '../../../widgets/coin_balance.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import '../../../widgets/user_avatar.dart';
import '../../user/screens/account_settings_screen.dart';
import '../../user/screens/user_home_screen.dart';
import '../../user/screens/user_profile_screen.dart';
import 'character_customization_screen.dart';
import 'daily_shop_screen.dart';
import 'inventory_screen.dart';
import 'marketplace_category_screen.dart';
import 'product_details_screen.dart';
import 'wishlist_screen.dart';

class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});

  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final int _navIndex = 1; // 0: Accueil, 1: Boutique, 2: Profil, 3: Paramètres
  final TextEditingController _searchController = TextEditingController();
  ProductCategory? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTapped(int index) {
    if (index == _navIndex) return;
    if (index == 0) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserHomeScreen()),
      );
    } else if (index == 2) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const UserProfileScreen()),
      );
    } else if (index == 3) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final wallet = context.wallet;
    final inventory = context.inventory;
    final marketplace = context.marketplace;

    final query = _searchController.text.trim();
    final isSearching = query.isNotEmpty || _selectedCategory != null;

    final searchResults = isSearching
        ? marketplace.searchProducts(
            query: query,
            category: _selectedCategory,
          )
        : <MarketplaceProduct>[];

    final featured = marketplace.featuredProducts;
    final daily = marketplace.dailyDeals;
    final limited = marketplace.limitedProducts;
    final allProducts = marketplace.allProducts;
    final wishlistCount = marketplace.wishlistProducts.length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar: Store Title + Wishlist Button + Inventory Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'StepQuest Store',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Dépensez vos Coins & personnalisez votre héros',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Wishlist Shortcut with Badge
                      Stack(
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WishlistScreen(),
                                ),
                              );
                            },
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.navyCard : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : AppColors.divider,
                                ),
                              ),
                              child: const Icon(
                                Icons.favorite_outline_rounded,
                                size: 20,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                          if (wishlistCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$wishlistCount',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gamified RPG Stats Card: Avatar, Level, XP Progress, Coin Balance
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        UserAvatar(user: user, radius: 26),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? const Color(0xFF1E3A8A)
                                                  .withValues(alpha: 0.35)
                                              : AppColors.primarySoft,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Niveau ${user.level}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primaryLight,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  CoinBalance(balance: wallet.balance),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                user.fullName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // XP Progress bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progression XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const Text(
                              '2 450 / 3 000 XP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: 2450 / 3000,
                            minHeight: 6,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : AppColors.divider,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search Input
              Container(
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
                    hintText: 'Rechercher un objet...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : AppColors.textMuted,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : AppColors.textMuted,
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
              const SizedBox(height: 14),

              // Category Selector Chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    CategoryChip(
                      label: 'Tous',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...ProductCategory.values.map((cat) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CategoryChip(
                          label: cat.label,
                          icon: cat.icon,
                          isSelected: _selectedCategory == cat,
                          onTap: () {
                            if (_selectedCategory == cat) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      MarketplaceCategoryScreen(category: cat),
                                ),
                              );
                            } else {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Quick Action Tiles (Daily Shop, Inventory, Customization)
              Row(
                children: [
                  Expanded(
                    child: _buildShortcutTile(
                      icon: Icons.timer_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Boutique du Jour',
                      subtitle: 'Offres limitées',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DailyShopScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShortcutTile(
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.primaryLight,
                      title: 'Mon Inventaire',
                      subtitle: '${inventory.items.length} objets',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const InventoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildShortcutTile(
                      icon: Icons.style_rounded,
                      iconColor: AppColors.secondary,
                      title: 'Personnaliser',
                      subtitle: 'Héros RPG',
                      isDark: isDark,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const CharacterCustomizationScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // IF SEARCHING: Show Search / Filtered Results
              if (isSearching) ...[
                Text(
                  'Résultats (${searchResults.length})',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                if (searchResults.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Aucun objet trouvé',
                    description:
                        'Modifiez votre recherche ou explorez une autre catégorie.',
                  )
                else
                  _buildProductGrid(
                    products: searchResults,
                    userLevel: user.level,
                    inventory: inventory,
                    marketplace: marketplace,
                  ),
              ]
              // ELSE: Show StepQuest RPG Marketplace Sections
              else ...[
                // SECTION 1: Featured Items
                _buildSectionHeader(
                  title: 'Objets en Vedette',
                  subtitle: 'Sélection des meilleurs équipements du moment',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildHorizontalProductList(
                  products: featured,
                  userLevel: user.level,
                  inventory: inventory,
                  marketplace: marketplace,
                ),
                const SizedBox(height: 24),

                // SECTION 2: Daily Deals
                _buildSectionHeader(
                  title: 'Offres du Jour 🔥',
                  subtitle: 'Remises exclusives renouvelées chaque jour',
                  isDark: isDark,
                  actionLabel: 'Voir tout',
                  onAction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DailyShopScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildHorizontalProductList(
                  products: daily,
                  userLevel: user.level,
                  inventory: inventory,
                  marketplace: marketplace,
                ),
                const SizedBox(height: 24),

                // SECTION 3: Limited Editions
                _buildSectionHeader(
                  title: 'Éditions Limitées ⚡',
                  subtitle: 'Raretés légendaires en quantité limitée',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildHorizontalProductList(
                  products: limited,
                  userLevel: user.level,
                  inventory: inventory,
                  marketplace: marketplace,
                ),
                const SizedBox(height: 24),

                // SECTION 4: Full Catalog / New Items
                _buildSectionHeader(
                  title: 'Catalogue Complet',
                  subtitle: 'Tous les objets disponibles pour votre aventure',
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildProductGrid(
                  products: allProducts,
                  userLevel: user.level,
                  inventory: inventory,
                  marketplace: marketplace,
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _navIndex,
        onTap: _onBottomNavTapped,
        items: AppBottomNavigation.userNavItems,
      ),
    );
  }

  Widget _buildShortcutTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    required bool isDark,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
            ),
            child: Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildHorizontalProductList({
    required List<MarketplaceProduct> products,
    required int userLevel,
    required dynamic inventory,
    required dynamic marketplace,
  }) {
    return SizedBox(
      height: 242,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final isOwned = inventory.hasItem(product.id);
          final isEquipped = inventory.isEquipped(product.id);
          final isInWishlist = marketplace.isInWishlist(product.id);

          return ProductCard(
            width: 170,
            product: product,
            userLevel: userLevel,
            isOwned: isOwned,
            isEquipped: isEquipped,
            isInWishlist: isInWishlist,
            onWishlistToggle: () {
              marketplace.toggleWishlist(product.id);
            },
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailsScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid({
    required List<MarketplaceProduct> products,
    required int userLevel,
    required dynamic inventory,
    required dynamic marketplace,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTabletOrDesktop = constraints.maxWidth >= 600;
        final crossAxisCount = isTabletOrDesktop ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
            final isInWishlist = marketplace.isInWishlist(product.id);

            return ProductCard(
              product: product,
              userLevel: userLevel,
              isOwned: isOwned,
              isEquipped: isEquipped,
              isInWishlist: isInWishlist,
              onWishlistToggle: () {
                marketplace.toggleWishlist(product.id);
              },
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProductDetailsScreen(product: product),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
