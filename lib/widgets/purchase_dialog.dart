import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/marketplace_product.dart';
import 'app_button.dart';
import 'product_rarity_badge.dart';

class PurchaseConfirmationDialog extends StatelessWidget {
  final MarketplaceProduct product;
  final int currentBalance;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  const PurchaseConfirmationDialog({
    super.key,
    required this.product,
    required this.currentBalance,
    required this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = product.effectivePrice;
    final balanceAfter = currentBalance - price;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? AppColors.navyCard : Colors.white,
      elevation: 10,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Prominent circular product badge matching StepQuest ConfirmationDialog
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: product.rarity.color.withValues(alpha: isDark ? 0.25 : 0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: product.rarity.color.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  product.iconData ?? Icons.shopping_bag_outlined,
                  color: product.rarity.color,
                  size: 36,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Name
            Text(
              'Acheter ${product.name} ?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Rarity Badge
            ProductRarityBadge(rarity: product.rarity),
            const SizedBox(height: 20),

            // Balance Details Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : AppColors.divider,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildBalanceRow(
                    label: 'Prix de l\'objet',
                    value: '$price Coins',
                    isDark: isDark,
                    highlight: true,
                  ),
                  const Divider(height: 16),
                  _buildBalanceRow(
                    label: 'Votre solde actuel',
                    value: '$currentBalance Coins',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 6),
                  _buildBalanceRow(
                    label: 'Solde après achat',
                    value: '$balanceAfter Coins',
                    isDark: isDark,
                    isSuccess: balanceAfter >= 0,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            AppButton(
              label: 'Acheter maintenant',
              icon: Icons.check_circle_outline_rounded,
              onPressed: () {
                Navigator.of(context).pop(true);
                onConfirm();
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Annuler',
              variant: AppButtonVariant.secondary,
              onPressed: () {
                Navigator.of(context).pop(false);
                if (onCancel != null) onCancel!();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow({
    required String label,
    required String value,
    required bool isDark,
    bool highlight = false,
    bool? isSuccess,
  }) {
    Color valueColor;
    if (highlight) {
      valueColor = const Color(0xFFF59E0B);
    } else if (isSuccess != null) {
      valueColor = isSuccess ? AppColors.secondary : AppColors.error;
    } else {
      valueColor = isDark ? Colors.white : AppColors.textPrimary;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

Future<bool?> showPurchaseConfirmationDialog({
  required BuildContext context,
  required MarketplaceProduct product,
  required int currentBalance,
  required VoidCallback onConfirm,
  VoidCallback? onCancel,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => PurchaseConfirmationDialog(
      product: product,
      currentBalance: currentBalance,
      onConfirm: onConfirm,
      onCancel: onCancel,
    ),
  );
}
