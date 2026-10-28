import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stepquest/core/theme/app_theme.dart';
import 'package:stepquest/data/mock_products.dart';
import 'package:stepquest/data/mock_users.dart';
import 'package:stepquest/features/marketplace/screens/character_customization_screen.dart';
import 'package:stepquest/features/marketplace/screens/daily_shop_screen.dart';
import 'package:stepquest/features/marketplace/screens/inventory_screen.dart';
import 'package:stepquest/features/marketplace/screens/marketplace_category_screen.dart';
import 'package:stepquest/features/marketplace/screens/marketplace_home_screen.dart';
import 'package:stepquest/features/marketplace/screens/wishlist_screen.dart';
import 'package:stepquest/models/app_user.dart';
import 'package:stepquest/models/inventory_item.dart';
import 'package:stepquest/models/marketplace_product.dart';
import 'package:stepquest/models/product_category.dart';
import 'package:stepquest/models/product_rarity.dart';
import 'package:stepquest/models/user_notification.dart';
import 'package:stepquest/services/mock_biometric_service.dart';
import 'package:stepquest/services/mock_marketplace_service.dart';
import 'package:stepquest/state/app_settings_state.dart';
import 'package:stepquest/state/app_state_provider.dart';
import 'package:stepquest/state/auth_state.dart';
import 'package:stepquest/state/inventory_state.dart';
import 'package:stepquest/state/marketplace_state.dart';
import 'package:stepquest/state/notification_state.dart';
import 'package:stepquest/state/user_state.dart';
import 'package:stepquest/state/wallet_state.dart';
import 'package:stepquest/widgets/empty_state.dart';

void main() {
  group('StepQuest Marketplace Models & Data Tests', () {
    test('Product loading: At least 15 mock products are defined', () {
      expect(initialMockProducts.length, greaterThanOrEqualTo(15));
      expect(initialMockProducts.any((p) => p.name == 'Runner Shoes'), true);
      expect(initialMockProducts.any((p) => p.name == 'Urban Backpack'), true);
      expect(initialMockProducts.any((p) => p.name == 'Speed Runner'), true);
      expect(initialMockProducts.any((p) => p.name == 'Legendary Runner'), true);
      expect(initialMockProducts.any((p) => p.name == 'Energy Outfit'), true);
      expect(initialMockProducts.any((p) => p.name == 'Explorer Outfit'), true);
      expect(initialMockProducts.any((p) => p.name == 'Fitness Band'), true);
      expect(initialMockProducts.any((p) => p.name == 'Golden Badge'), true);
      expect(initialMockProducts.any((p) => p.name == 'XP Booster'), true);
    });

    test('MarketplaceProduct serialization toMap and fromMap', () {
      final product = initialMockProducts.first;
      final map = product.toMap();
      final reconstructed = MarketplaceProduct.fromMap(map);

      expect(reconstructed.id, product.id);
      expect(reconstructed.name, product.name);
      expect(reconstructed.price, product.price);
      expect(reconstructed.category, product.category);
      expect(reconstructed.rarity, product.rarity);
    });

    test('Product effective price calculates discount properly', () {
      const discountedProduct = MarketplaceProduct(
        id: 'test-discount',
        name: 'Discounted Item',
        description: 'Test',
        category: ProductCategory.outfits,
        rarity: ProductRarity.rare,
        price: 1000,
        image: 'test',
        discountPercentage: 20,
      );
      expect(discountedProduct.effectivePrice, 800);
      expect(discountedProduct.hasDiscount, true);
    });

    test('InventoryItem serialization toMap and fromMap', () {
      final item = InventoryItem(
        id: 'inv-test-1',
        productId: 'prod-shoes-01',
        userId: 'user-1',
        purchaseDate: DateTime(2026, 1, 1),
        isEquipped: true,
        quantity: 1,
      );
      final map = item.toMap();
      final reconstructed = InventoryItem.fromMap(map);

      expect(reconstructed.id, item.id);
      expect(reconstructed.productId, item.productId);
      expect(reconstructed.isEquipped, true);
    });
  });

  group('StepQuest Marketplace Service & Search Tests', () {
    late MockMarketplaceService service;

    setUp(() {
      service = MockMarketplaceService();
    });

    test('Category filtering returns only products in that category', () {
      final shoes = service.getProductsByCategory(ProductCategory.shoes);
      expect(shoes.isNotEmpty, true);
      expect(shoes.every((p) => p.category == ProductCategory.shoes), true);

      final backpacks =
          service.getProductsByCategory(ProductCategory.backpacks);
      expect(backpacks.isNotEmpty, true);
      expect(
          backpacks.every((p) => p.category == ProductCategory.backpacks),
          true);
    });

    test('Search filters products by name, description and bonus', () {
      final runnerResults = service.searchProducts(query: 'runner');
      expect(runnerResults.isNotEmpty, true);
      expect(
        runnerResults.every((p) =>
            p.name.toLowerCase().contains('runner') ||
            p.description.toLowerCase().contains('runner')),
        true,
      );

      final xpResults = service.searchProducts(query: 'XP');
      expect(xpResults.isNotEmpty, true);
    });

    test('Rarity filtering returns only specified rarity', () {
      final legendaryItems =
          service.searchProducts(rarity: ProductRarity.legendary);
      expect(legendaryItems.isNotEmpty, true);
      expect(
          legendaryItems.every((p) => p.rarity == ProductRarity.legendary),
          true);
    });

    test('Featured products and Daily deals are correctly flagged', () {
      final featured = service.getFeaturedProducts();
      expect(featured.isNotEmpty, true);
      expect(featured.every((p) => p.isFeatured), true);

      final daily = service.getDailyDeals();
      expect(daily.length, greaterThanOrEqualTo(4));
      expect(daily.every((p) => p.isDailyDeal), true);

      final limited = service.getLimitedProducts();
      expect(limited.isNotEmpty, true);
      expect(limited.every((p) => p.isLimited), true);
    });
  });

  group('StepQuest WalletState & Economy Tests', () {
    late WalletState wallet;

    setUp(() {
      wallet = WalletState(initialBalance: 1250);
    });

    test('Initial demo balance is 1250 Coins', () {
      expect(wallet.balance, 1250);
      expect(wallet.getBalance(), 1250);
    });

    test('canAfford accurately checks balance against price', () {
      expect(wallet.canAfford(300), true);
      expect(wallet.canAfford(1250), true);
      expect(wallet.canAfford(1251), false);
    });

    test('removeCoins deducts balance and returns true on success', () {
      final success = wallet.removeCoins(300);
      expect(success, true);
      expect(wallet.balance, 950);
    });

    test('removeCoins rejects transaction and prevents negative Coins', () {
      final success = wallet.removeCoins(2000);
      expect(success, false);
      expect(wallet.balance, 1250); // Remains untouched
    });

    test('addCoins increases balance', () {
      wallet.addCoins(250);
      expect(wallet.balance, 1500);
    });
  });

  group('StepQuest InventoryState & Equipment Tests', () {
    late InventoryState inventory;
    final catalog = initialMockProducts;

    setUp(() {
      inventory = InventoryState([]);
    });

    test('addItem and hasItem operations', () {
      expect(inventory.hasItem('prod-backpack-01'), false);

      final newItem = InventoryItem(
        id: 'inv-1',
        productId: 'prod-backpack-01',
        userId: 'test-user',
        purchaseDate: DateTime.now(),
      );
      inventory.addItem(newItem);

      expect(inventory.hasItem('prod-backpack-01'), true);
      expect(inventory.items.length, 1);
    });

    test('equipItem equips owned item and un-equips other in same category', () {
      // Add two shoes
      inventory.addItem(InventoryItem(
        id: 'inv-s1',
        productId: 'prod-shoes-01',
        userId: 'test-user',
        purchaseDate: DateTime.now(),
      ));
      inventory.addItem(InventoryItem(
        id: 'inv-s2',
        productId: 'prod-shoes-02',
        userId: 'test-user',
        purchaseDate: DateTime.now(),
      ));

      // Equip first pair
      final eq1 = inventory.equipItem('prod-shoes-01', catalog);
      expect(eq1, true);
      expect(inventory.isEquipped('prod-shoes-01'), true);
      expect(inventory.isEquipped('prod-shoes-02'), false);

      // Equip second pair -> first pair is unequipped
      final eq2 = inventory.equipItem('prod-shoes-02', catalog);
      expect(eq2, true);
      expect(inventory.isEquipped('prod-shoes-02'), true);
      expect(inventory.isEquipped('prod-shoes-01'), false);
    });

    test('equipItem cannot equip unowned product', () {
      final success = inventory.equipItem('unowned-prod-id', catalog);
      expect(success, false);
    });

    test('unequipItem unequips product', () {
      inventory.addItem(InventoryItem(
        id: 'inv-b1',
        productId: 'prod-backpack-01',
        userId: 'test-user',
        purchaseDate: DateTime.now(),
        isEquipped: true,
      ));
      expect(inventory.isEquipped('prod-backpack-01'), true);

      inventory.unequipItem('prod-backpack-01');
      expect(inventory.isEquipped('prod-backpack-01'), false);
    });
  });

  group('StepQuest Purchase Business Rules & State Flow Tests', () {
    late MarketplaceState marketplace;
    late WalletState wallet;
    late InventoryState inventory;
    late NotificationState notificationState;
    late AppUser demoUser;

    setUp(() {
      marketplace = MarketplaceState();
      wallet = WalletState(initialBalance: 1250);
      inventory = InventoryState([]);
      notificationState = NotificationState();
      demoUser = initialMockUsers.firstWhere((u) => u.fullName == 'Amine Ben Ali');
    });

    test('Demo scenario: Amine Ben Ali (Level 3, 1250 Coins) buys Urban Backpack (300 Coins, Req Niv 1)',
        () async {
      expect(demoUser.level, 3);
      expect(wallet.balance, 1250);

      final backpack = marketplace.getProductById('prod-backpack-01')!;
      expect(backpack.name, 'Urban Backpack');
      expect(backpack.price, 300);
      expect(backpack.levelRequired, 1);

      // Execute purchase
      final result = await marketplace.buyProduct(
        product: backpack,
        user: demoUser,
        wallet: wallet,
        inventory: inventory,
        notificationState: notificationState,
      );

      // Verify success
      expect(result.isSuccess, true);
      // Coins became 950
      expect(wallet.balance, 950);
      // Inventory now contains Urban Backpack
      expect(inventory.hasItem(backpack.id), true);

      // Equip Urban Backpack
      marketplace.equipProduct(
        product: backpack,
        inventory: inventory,
        notificationState: notificationState,
        userId: demoUser.id,
      );
      expect(inventory.isEquipped(backpack.id), true);

      // Verify notification generated
      expect(
        notificationState.notifications.any((n) =>
            n.type == NotificationType.marketplacePurchase &&
            n.message.contains('Urban Backpack')),
        true,
      );
      expect(
        notificationState.notifications.any((n) =>
            n.type == NotificationType.itemEquipped &&
            n.message.contains('Urban Backpack')),
        true,
      );
    });

    test('Purchase failure: Insufficient Coins prevents deduction and inventory addition',
        () async {
      wallet.setBalance(200); // Only 200 Coins

      final backpack = marketplace.getProductById('prod-backpack-01')!; // 300 Coins
      final result = await marketplace.buyProduct(
        product: backpack,
        user: demoUser,
        wallet: wallet,
        inventory: inventory,
        notificationState: notificationState,
      );

      expect(result.isSuccess, false);
      expect(result.message, "Vous n'avez pas assez de Coins.");
      expect(wallet.balance, 200); // Balance untouched
      expect(inventory.hasItem(backpack.id), false);
    });

    test('Purchase failure: Insufficient Level blocks purchase with exact message',
        () async {
      final lowLevelUser = demoUser.copyWith(level: 2);
      final highLevelShoes = marketplace.getProductById('prod-shoes-01')!; // Req Level 5

      final result = await marketplace.buyProduct(
        product: highLevelShoes,
        user: lowLevelUser,
        wallet: wallet,
        inventory: inventory,
        notificationState: notificationState,
      );

      expect(result.isSuccess, false);
      expect(result.message, 'Atteignez le niveau 5 pour débloquer cet objet.');
      expect(wallet.balance, 1250); // Untouched
      expect(inventory.hasItem(highLevelShoes.id), false);
    });

    test('Purchase failure: Already owned item cannot be purchased again',
        () async {
      final backpack = marketplace.getProductById('prod-backpack-01')!;

      // Add to inventory beforehand
      inventory.addItem(InventoryItem(
        id: 'inv-pre',
        productId: backpack.id,
        userId: demoUser.id,
        purchaseDate: DateTime.now(),
      ));

      final result = await marketplace.buyProduct(
        product: backpack,
        user: demoUser,
        wallet: wallet,
        inventory: inventory,
        notificationState: notificationState,
      );

      expect(result.isSuccess, false);
      expect(result.message, 'Cet objet est déjà dans votre inventaire.');
      expect(wallet.balance, 1250);
    });

    test('Wishlist toggle adds and removes products', () {
      expect(marketplace.isInWishlist('prod-shoes-01'), false);

      marketplace.toggleWishlist('prod-shoes-01');
      expect(marketplace.isInWishlist('prod-shoes-01'), true);
      expect(marketplace.wishlistProducts.length, 1);

      marketplace.toggleWishlist('prod-shoes-01');
      expect(marketplace.isInWishlist('prod-shoes-01'), false);
      expect(marketplace.wishlistProducts.isEmpty, true);
    });
  });

  group('StepQuest Marketplace UI & Widget Integration Tests', () {
    Widget createTestApp(Widget child) {
      final authState = AuthState();
      final userState = UserState();
      final notificationState = NotificationState();
      final settingsState = AppSettingsState();
      final biometricService = MockBiometricService();
      final marketplaceState = MarketplaceState();
      final walletState = WalletState(initialBalance: 1250);
      final inventoryState = InventoryState([]);

      return AppStateProvider(
        authState: authState,
        userState: userState,
        notificationState: notificationState,
        settingsState: settingsState,
        biometricService: biometricService,
        marketplaceState: marketplaceState,
        walletState: walletState,
        inventoryState: inventoryState,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: child,
        ),
      );
    }

    testWidgets('MarketplaceHomeScreen renders Store header, Coins, Categories and Products',
        (tester) async {
      await tester.pumpWidget(createTestApp(const MarketplaceHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('StepQuest Store'), findsOneWidget);
      expect(find.text('1 250'), findsOneWidget);
      expect(find.text('Objets en Vedette'), findsOneWidget);
      expect(find.text('Boutique du Jour'), findsWidgets);
      expect(find.text('Mon Inventaire'), findsWidgets);
    });

    testWidgets('MarketplaceCategoryScreen renders category products and search input',
        (tester) async {
      await tester.pumpWidget(createTestApp(
        const MarketplaceCategoryScreen(category: ProductCategory.shoes),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chaussures'), findsOneWidget);
      expect(find.text('Runner Shoes'), findsOneWidget);
      expect(find.text('Speed Runner'), findsOneWidget);
    });

    testWidgets('DailyShopScreen displays countdown timer and daily deal products',
        (tester) async {
      await tester.pumpWidget(createTestApp(const DailyShopScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Boutique du Jour'), findsOneWidget);
      expect(find.text('Renouvellement quotidien'), findsOneWidget);
      expect(find.textContaining('Expire dans :'), findsOneWidget);
    });

    testWidgets('WishlistScreen shows EmptyState when no item is favorited',
        (tester) async {
      await tester.pumpWidget(createTestApp(const WishlistScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ma Liste d\'Envies'), findsOneWidget);
      expect(find.text('Votre liste est vide'), findsOneWidget);
      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('InventoryScreen shows empty state or owned items and allows customization access',
        (tester) async {
      await tester.pumpWidget(createTestApp(const InventoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mon Inventaire'), findsOneWidget);
      expect(find.text('Personnaliser mon héros RPG'), findsOneWidget);
      expect(find.text('Inventaire vide'), findsOneWidget);
    });

    testWidgets('CharacterCustomizationScreen displays avatar and equipment slots',
        (tester) async {
      await tester.pumpWidget(createTestApp(const CharacterCustomizationScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Personnalisation du Héros'), findsOneWidget);
      expect(find.text('Emplacements d\'équipement RPG'), findsOneWidget);
      expect(find.text('Tenues'), findsOneWidget);
      expect(find.text('Chaussures'), findsOneWidget);
      expect(find.text('Sacs à dos'), findsOneWidget);
      expect(find.text('Accessoires'), findsOneWidget);
    });
  });
}
