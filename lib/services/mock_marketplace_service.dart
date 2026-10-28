import '../data/mock_products.dart';
import '../models/marketplace_product.dart';
import '../models/product_category.dart';
import '../models/product_rarity.dart';

/// Service providing access to StepQuest Marketplace products
class MockMarketplaceService {
  final List<MarketplaceProduct> _catalog;

  MockMarketplaceService([List<MarketplaceProduct>? initialCatalog])
      : _catalog = List<MarketplaceProduct>.from(initialCatalog ?? initialMockProducts);

  /// Retrieve all available products
  List<MarketplaceProduct> getAllProducts() {
    return List.unmodifiable(_catalog);
  }

  /// Retrieve featured products
  List<MarketplaceProduct> getFeaturedProducts() {
    return _catalog.where((p) => p.isFeatured).toList();
  }

  /// Retrieve daily deals
  List<MarketplaceProduct> getDailyDeals() {
    return _catalog.where((p) => p.isDailyDeal).toList();
  }

  /// Retrieve limited edition products
  List<MarketplaceProduct> getLimitedProducts() {
    return _catalog.where((p) => p.isLimited).toList();
  }

  /// Retrieve products by category
  List<MarketplaceProduct> getProductsByCategory(ProductCategory category) {
    return _catalog.where((p) => p.category == category).toList();
  }

  /// Retrieve a specific product by its ID
  MarketplaceProduct? getProductById(String id) {
    try {
      return _catalog.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Filter and search products
  List<MarketplaceProduct> searchProducts({
    String? query,
    ProductCategory? category,
    ProductRarity? rarity,
    String? sortBy, // 'price_asc', 'price_desc', 'rarity', 'level', 'newest'
  }) {
    var result = List<MarketplaceProduct>.from(_catalog);

    if (category != null) {
      result = result.where((p) => p.category == category).toList();
    }

    if (rarity != null) {
      result = result.where((p) => p.rarity == rarity).toList();
    }

    if (query != null && query.trim().isNotEmpty) {
      final clean = query.trim().toLowerCase();
      result = result.where((p) {
        return p.name.toLowerCase().contains(clean) ||
            p.description.toLowerCase().contains(clean) ||
            (p.bonusType != null && p.bonusType!.toLowerCase().contains(clean));
      }).toList();
    }

    if (sortBy != null) {
      switch (sortBy) {
        case 'price_asc':
          result.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
          break;
        case 'price_desc':
          result.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
          break;
        case 'rarity':
          result.sort((a, b) => b.rarity.index.compareTo(a.rarity.index));
          break;
        case 'level':
          result.sort((a, b) => a.levelRequired.compareTo(b.levelRequired));
          break;
      }
    }

    return result;
  }
}
