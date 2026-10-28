import '../models/marketplace_product.dart';
import '../models/purchase.dart';

enum PurchaseErrorCode {
  levelInsufficient,
  coinsInsufficient,
  alreadyOwned,
  outOfStock,
}

class PurchaseValidationResult {
  final bool isValid;
  final String? errorMessage;
  final PurchaseErrorCode? errorCode;

  const PurchaseValidationResult.success()
      : isValid = true,
        errorMessage = null,
        errorCode = null;

  const PurchaseValidationResult.failure({
    required this.errorMessage,
    required this.errorCode,
  }) : isValid = false;
}

/// Service that encapsulates validation and purchase business rules
class MockPurchaseService {
  PurchaseValidationResult validatePurchase({
    required MarketplaceProduct product,
    required int userLevel,
    required int userCoins,
    required bool alreadyOwned,
  }) {
    // 1. Check Level requirement
    if (userLevel < product.levelRequired) {
      return PurchaseValidationResult.failure(
        errorMessage:
            'Atteignez le niveau ${product.levelRequired} pour débloquer cet objet.',
        errorCode: PurchaseErrorCode.levelInsufficient,
      );
    }

    // 2. Check Coins sufficiency
    if (userCoins < product.effectivePrice) {
      return const PurchaseValidationResult.failure(
        errorMessage: "Vous n'avez pas assez de Coins.",
        errorCode: PurchaseErrorCode.coinsInsufficient,
      );
    }

    // 3. Check Ownership
    if (alreadyOwned) {
      return const PurchaseValidationResult.failure(
        errorMessage: 'Cet objet est déjà dans votre inventaire.',
        errorCode: PurchaseErrorCode.alreadyOwned,
      );
    }

    // 4. Check Stock if limited
    if (product.stock != null && product.stock! <= 0) {
      return const PurchaseValidationResult.failure(
        errorMessage: 'Cet objet est actuellement en rupture de stock.',
        errorCode: PurchaseErrorCode.outOfStock,
      );
    }

    return const PurchaseValidationResult.success();
  }

  Purchase createPurchase({
    required MarketplaceProduct product,
    required String userId,
  }) {
    return Purchase(
      id: 'purch-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      userId: userId,
      purchaseDate: DateTime.now(),
      pricePaid: product.effectivePrice,
      status: 'completed',
    );
  }
}
