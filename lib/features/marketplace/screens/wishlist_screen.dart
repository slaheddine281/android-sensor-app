import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import 'product_details_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marketplace = context.marketplace;
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final inventory = context.inventory;

    final wishlistProducts = marketplace.wishlistProducts;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Ma Liste d\'Envies',
      ),
      body: SafeArea(
        child: wishlistProducts.isEmpty
            ? EmptyState(
                icon: Icons.favorite_border_rounded,
                title: 'Votre liste est vide',
                description:
                    'Ajoutez des objets en favoris pour les retrouver facilement et suivre vos objectifs de Coins.',
                action: AppButton(
                  label: 'Explorer la boutique',
                  isFullWidth: false,
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isTabletOrDesktop = constraints.maxWidth >= 600;
                  final crossAxisCount = isTabletOrDesktop ? 3 : 2;

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: wishlistProducts.length,
                    itemBuilder: (context, index) {
                      final product = wishlistProducts[index];
                      final isOwned = inventory.hasItem(product.id);
                      final isEquipped = inventory.isEquipped(product.id);

                      return ProductCard(
                        product: product,
                        userLevel: user.level,
                        isOwned: isOwned,
                        isEquipped: isEquipped,
                        isInWishlist: true,
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
    );
  }
}
