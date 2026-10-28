import 'package:flutter/foundation.dart';
import '../models/app_user.dart';
import '../models/inventory_item.dart';
import '../models/marketplace_product.dart';
import '../models/product_category.dart';
import '../models/product_rarity.dart';
import '../models/purchase.dart';
import '../models/user_notification.dart';
import '../services/mock_marketplace_service.dart';
import '../services/mock_purchase_service.dart';
import 'inventory_state.dart';
import 'notification_state.dart';
import 'wallet_state.dart';

/// Result object returned by the purchase execution flow
class PurchaseExecutionResult {
  final bool isSuccess;
  final String message;
  final Purchase? purchase;
  final MarketplaceProduct product;

  const PurchaseExecutionResult.success({
    required this.product,
    required this.purchase,
    this.message = 'Achat réussi !',
  }) : isSuccess = true;

  const PurchaseExecutionResult.failure({
    required this.product,
    required this.message,
  })  : isSuccess = false,
        purchase = null;
}

/// Central state manager for the StepQuest Marketplace
class MarketplaceState extends ChangeNotifier {
  final MockMarketplaceService _marketplaceService;
  final MockPurchaseService _purchaseService;

  final Set<String> _wishlistIds = {};
  final List<Purchase> _purchaseHistory = [];

  MarketplaceState({
    MockMarketplaceService? marketplaceService,
    MockPurchaseService? purchaseService,
  })  : _marketplaceService = marketplaceService ?? MockMarketplaceService(),
        _purchaseService = purchaseService ?? MockPurchaseService();

  List<MarketplaceProduct> get allProducts => _marketplaceService.getAllProducts();

  List<MarketplaceProduct> get featuredProducts =>
      _marketplaceService.getFeaturedProducts();

  List<MarketplaceProduct> get dailyDeals => _marketplaceService.getDailyDeals();

  List<MarketplaceProduct> get limitedProducts =>
      _marketplaceService.getLimitedProducts();

  List<Purchase> get purchaseHistory => List.unmodifiable(_purchaseHistory);

  // --- WISHLIST MANAGEMENT ---

  List<MarketplaceProduct> get wishlistProducts {
    return allProducts.where((p) => _wishlistIds.contains(p.id)).toList();
  }

  bool isInWishlist(String productId) {
    return _wishlistIds.contains(productId);
  }

  void toggleWishlist(String productId) {
    if (_wishlistIds.contains(productId)) {
      _wishlistIds.remove(productId);
    } else {
      _wishlistIds.add(productId);
    }
    notifyListeners();
  }

  // --- CATALOG LOOKUPS & FILTERING ---

  MarketplaceProduct? getProductById(String id) {
    return _marketplaceService.getProductById(id);
  }

  List<MarketplaceProduct> getProductsByCategory(ProductCategory category) {
    return _marketplaceService.getProductsByCategory(category);
  }

  List<MarketplaceProduct> searchProducts({
    String? query,
    ProductCategory? category,
    ProductRarity? rarity,
    String? sortBy,
  }) {
    return _marketplaceService.searchProducts(
      query: query,
      category: category,
      rarity: rarity,
      sortBy: sortBy,
    );
  }

  // --- COMPLETE PURCHASE FLOW ---

  Future<PurchaseExecutionResult> buyProduct({
    required MarketplaceProduct product,
    required AppUser user,
    required WalletState wallet,
    required InventoryState inventory,
    required NotificationState notificationState,
  }) async {
    final alreadyOwned = inventory.hasItem(product.id);

    // 1. Validate through service
    final validation = _purchaseService.validatePurchase(
      product: product,
      userLevel: user.level,
      userCoins: wallet.balance,
      alreadyOwned: alreadyOwned,
    );

    if (!validation.isValid) {
      return PurchaseExecutionResult.failure(
        product: product,
        message: validation.errorMessage ?? "Impossible d'effectuer l'achat.",
      );
    }

    // 2. Deduct Coins safely
    final priceToPay = product.effectivePrice;
    final deducted = wallet.removeCoins(priceToPay);
    if (!deducted) {
      return PurchaseExecutionResult.failure(
        product: product,
        message: "Vous n'avez pas assez de Coins.",
      );
    }

    // 3. Add to Inventory
    final newItem = InventoryItem(
      id: 'inv-${DateTime.now().millisecondsSinceEpoch}',
      productId: product.id,
      userId: user.id,
      purchaseDate: DateTime.now(),
      isEquipped: false,
    );
    inventory.addItem(newItem);

    // 4. Create & Record Purchase
    final purchase = _purchaseService.createPurchase(
      product: product,
      userId: user.id,
    );
    _purchaseHistory.insert(0, purchase);

    // 5. Trigger System Notification
    notificationState.addNotification(
      title: 'Achat confirmé',
      message: '${product.name} a été ajouté à votre inventaire.',
      type: NotificationType.marketplacePurchase,
      relatedUserId: user.id,
    );

    notifyListeners();

    return PurchaseExecutionResult.success(
      product: product,
      purchase: purchase,
      message: '${product.name} débloqué avec succès !',
    );
  }

  // --- EQUIP / UNEQUIP ACTIONS ---

  void equipProduct({
    required MarketplaceProduct product,
    required InventoryState inventory,
    required NotificationState notificationState,
    String? userId,
  }) {
    final success = inventory.equipItem(product.id, allProducts);
    if (success) {
      notificationState.addNotification(
        title: 'Objet équipé',
        message: '${product.name} est maintenant équipé.',
        type: NotificationType.itemEquipped,
        relatedUserId: userId,
      );
      notifyListeners();
    }
  }

  void unequipProduct({
    required MarketplaceProduct product,
    required InventoryState inventory,
    required NotificationState notificationState,
    String? userId,
  }) {
    inventory.unequipItem(product.id);
    notificationState.addNotification(
      title: 'Objet déséquipé',
      message: '${product.name} a été retiré de votre équipement actif.',
      type: NotificationType.itemUnequipped,
      relatedUserId: userId,
    );
    notifyListeners();
  }
}
