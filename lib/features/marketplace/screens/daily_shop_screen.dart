import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/coin_balance.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/product_card.dart';
import 'product_details_screen.dart';

class DailyShopScreen extends StatefulWidget {
  const DailyShopScreen({super.key});

  @override
  State<DailyShopScreen> createState() => _DailyShopScreenState();
}

class _DailyShopScreenState extends State<DailyShopScreen> {
  Timer? _timer;
  Duration _timeRemaining = const Duration(hours: 8, minutes: 42, seconds: 15);

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = _timeRemaining - const Duration(seconds: 1);
        });
      } else {
        setState(() {
          _timeRemaining = const Duration(hours: 24);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final marketplace = context.marketplace;
    final wallet = context.wallet;
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final inventory = context.inventory;

    final dailyProducts = marketplace.dailyDeals;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Boutique du Jour',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoinBalance(balance: wallet.balance, isCompact: true),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Prominent Countdown Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppCard(
                padding: const EdgeInsets.all(16),
                backgroundColor: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        color: Color(0xFFF59E0B),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Renouvellement quotidien',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                'Expire dans : ',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                _formatDuration(_timeRemaining),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFF59E0B),
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'JUSQU\'À -20%',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid
            Expanded(
              child: dailyProducts.isEmpty
                  ? const EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'Pas d\'offres pour le moment',
                      description: 'Revenez très vite pour de nouvelles remises !',
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isTabletOrDesktop = constraints.maxWidth >= 600;
                        final crossAxisCount = isTabletOrDesktop ? 3 : 2;

                        return GridView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: dailyProducts.length,
                          itemBuilder: (context, index) {
                            final product = dailyProducts[index];
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
}
