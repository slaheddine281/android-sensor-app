import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/marketplace_product.dart';
import '../../../state/app_state_provider.dart';
import '../../../widgets/app_app_bar.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_card.dart';
import '../../../widgets/coin_balance.dart';
import '../../../widgets/product_price.dart';
import '../../../widgets/product_rarity_badge.dart';
import '../../../widgets/purchase_dialog.dart';
import 'purchase_success_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final MarketplaceProduct product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _isProcessing = false;

  void _handlePurchase() async {
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    final wallet = context.wallet;
    final inventory = context.inventory;
    final marketplace = context.marketplace;
    final notifs = context.notifications;

    // Check level first
    if (user.level < widget.product.levelRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Atteignez le niveau ${widget.product.levelRequired} pour débloquer cet objet.',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check coins
    if (!wallet.canAfford(widget.product.effectivePrice)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous n'avez pas assez de Coins."),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check ownership
    if (inventory.hasItem(widget.product.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cet objet est déjà dans votre inventaire."),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Show Confirmation Dialog
    final confirmed = await showPurchaseConfirmationDialog(
      context: context,
      product: widget.product,
      currentBalance: wallet.balance,
      onConfirm: () {},
    );

    if (confirmed == true && mounted) {
      setState(() => _isProcessing = true);

      final result = await marketplace.buyProduct(
        product: widget.product,
        user: user,
        wallet: wallet,
        inventory: inventory,
        notificationState: notifs,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (result.isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PurchaseSuccessScreen(product: widget.product),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _handleEquipToggle(bool isEquipped) {
    final user = context.auth.currentUser ?? context.users.allUsers.first;
    if (isEquipped) {
      context.marketplace.unequipProduct(
        product: widget.product,
        inventory: context.inventory,
        notificationState: context.notifications,
        userId: user.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} a été retiré de votre équipement.'),
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      context.marketplace.equipProduct(
        product: widget.product,
        inventory: context.inventory,
        notificationState: context.notifications,
        userId: user.id,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.product.name} est maintenant équipé !'),
          backgroundColor: AppColors.secondary,
          duration: const Duration(seconds: 1),
        ),
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

    final isOwned = inventory.hasItem(widget.product.id);
    final isEquipped = inventory.isEquipped(widget.product.id);
    final isInWishlist = marketplace.isInWishlist(widget.product.id);
    final isLevelLocked = user.level < widget.product.levelRequired;
    final canAfford = wallet.canAfford(widget.product.effectivePrice);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navyDark : AppColors.background,
      appBar: AppAppBar(
        title: 'Détails de l\'objet',
        actions: [
          IconButton(
            icon: Icon(
              isInWishlist ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isInWishlist ? AppColors.error : (isDark ? Colors.white : AppColors.textPrimary),
            ),
            onPressed: () {
              marketplace.toggleWishlist(widget.product.id);
              final isSaved = marketplace.isInWishlist(widget.product.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isSaved
                        ? '${widget.product.name} ajouté à vos favoris.'
                        : '${widget.product.name} retiré des favoris.',
                  ),
                  duration: const Duration(seconds: 1),
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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Illustration Banner with Rarity glow
                    AppCard(
                      padding: EdgeInsets.zero,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              widget.product.rarity.color
                                  .withValues(alpha: isDark ? 0.35 : 0.18),
                              widget.product.rarity.color
                                  .withValues(alpha: isDark ? 0.10 : 0.05),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Hero(
                            tag: 'product-icon-${widget.product.id}',
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.navyCard : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.product.rarity.color
                                      .withValues(alpha: 0.5),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.product.rarity.color
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.product.iconData ??
                                    Icons.inventory_2_outlined,
                                size: 50,
                                color: widget.product.rarity.color,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title, Category & Rarity Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  ProductRarityBadge(rarity: widget.product.rarity),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0xFF1E293B)
                                          : AppColors.background,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF334155)
                                            : AppColors.divider,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.product.category.icon,
                                          size: 13,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          widget.product.category.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? const Color(0xFF94A3B8)
                                                : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Status badge if owned
                        if (isEquipped)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text(
                                  'Équipé',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isOwned)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E3A8A)
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.primaryLight,
                              ),
                            ),
                            child: const Text(
                              'Dans l\'inventaire',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price & Balance Card
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prix d\'achat',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              ProductPrice(product: widget.product, fontSize: 18),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Votre solde',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              CoinBalance(balance: wallet.balance, isCompact: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Level Requirement Card
                    AppCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      backgroundColor: isLevelLocked
                          ? (isDark
                              ? const Color(0xFF7F1D1D).withValues(alpha: 0.2)
                              : AppColors.errorSoft)
                          : null,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isLevelLocked
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : AppColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              isLevelLocked
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              size: 18,
                              color: isLevelLocked
                                  ? AppColors.error
                                  : AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Niveau requis : Niveau ${widget.product.levelRequired}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isLevelLocked
                                        ? AppColors.error
                                        : (isDark ? Colors.white : AppColors.textPrimary),
                                  ),
                                ),
                                Text(
                                  isLevelLocked
                                      ? 'Vous êtes niveau ${user.level}. Marchez pour monter en niveau !'
                                      : 'Débloqué ! Votre niveau actuel (${user.level}) est suffisant.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // RPG Bonus Card if present
                    if (widget.product.bonusValue != null) ...[
                      AppCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bolt_rounded,
                                color: AppColors.secondary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bonus RPG Actif',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${widget.product.bonusType} : ${widget.product.bonusValue}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description Section
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.product.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? const Color(0xFFCBD5E1) : AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.navyCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? const Color(0xFF334155) : AppColors.divider,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    // If Owned: Show Equip / Unequip
                    if (isOwned) ...[
                      Expanded(
                        child: AppButton(
                          label: isEquipped ? 'DÉSÉQUIPER' : 'ÉQUIPER CET OBJET',
                          icon: isEquipped
                              ? Icons.remove_circle_outline_rounded
                              : Icons.checkroom_rounded,
                          variant: isEquipped
                              ? AppButtonVariant.secondary
                              : AppButtonVariant.primary,
                          onPressed: () => _handleEquipToggle(isEquipped),
                        ),
                      ),
                    ]
                    // If Not Owned: Show BUY NOW with validation checks
                    else ...[
                      Expanded(
                        child: AppButton(
                          label: isLevelLocked
                              ? 'NIVEAU ${widget.product.levelRequired} REQUIS'
                              : (!canAfford ? 'COINS INSUFFISANTS' : 'ACHETER MAINTENANT'),
                          icon: isLevelLocked
                              ? Icons.lock_rounded
                              : Icons.shopping_bag_outlined,
                          isLoading: _isProcessing,
                          customBackgroundColor: (isLevelLocked || !canAfford)
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFF94A3B8))
                              : AppColors.primary,
                          onPressed: (isLevelLocked || !canAfford)
                              ? _handlePurchase // Triggers friendly informative snackbars
                              : _handlePurchase,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
