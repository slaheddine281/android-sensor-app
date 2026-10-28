import 'package:flutter/foundation.dart';
import '../data/mock_inventory.dart';
import '../models/inventory_item.dart';
import '../models/marketplace_product.dart';
import '../models/product_category.dart';

/// Manages owned items, equipment status, and character gear
class InventoryState extends ChangeNotifier {
  final List<InventoryItem> _items;

  InventoryState([List<InventoryItem>? initialItems])
      : _items = List<InventoryItem>.from(initialItems ?? initialMockInventory);

  List<InventoryItem> get items => List.unmodifiable(_items);

  /// Checks if a product is owned in the inventory
  bool hasItem(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Checks if a product is currently equipped
  bool isEquipped(String productId) {
    final index = _items.indexWhere((item) => item.productId == productId);
    return index != -1 && _items[index].isEquipped;
  }

  /// Retrieves an inventory item by product ID
  InventoryItem? getItemByProduct(String productId) {
    try {
      return _items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  /// Adds a newly purchased item to inventory
  void addItem(InventoryItem item) {
    final existingIndex =
        _items.indexWhere((i) => i.productId == item.productId);
    if (existingIndex != -1) {
      // Increase quantity if already in inventory
      final existing = _items[existingIndex];
      _items[existingIndex] =
          existing.copyWith(quantity: existing.quantity + item.quantity);
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  /// Removes an item from inventory
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  /// Equips an item. Ensures only 1 item per equipment slot is equipped at a time.
  /// Only owned items can be equipped.
  bool equipItem(String productId, List<MarketplaceProduct> catalog) {
    final itemIndex = _items.indexWhere((i) => i.productId == productId);
    if (itemIndex == -1) return false;

    // Find product to determine its category
    final product = catalog.where((p) => p.id == productId).firstOrNull;
    if (product != null) {
      // Un-equip any other item in the same category slot
      for (int i = 0; i < _items.length; i++) {
        if (i == itemIndex) continue;
        final otherProduct =
            catalog.where((p) => p.id == _items[i].productId).firstOrNull;
        if (otherProduct != null && otherProduct.category == product.category) {
          _items[i] = _items[i].copyWith(isEquipped: false);
        }
      }
    }

    _items[itemIndex] = _items[itemIndex].copyWith(isEquipped: true);
    notifyListeners();
    return true;
  }

  /// Unequips a specific item
  void unequipItem(String productId) {
    final itemIndex = _items.indexWhere((i) => i.productId == productId);
    if (itemIndex != -1 && _items[itemIndex].isEquipped) {
      _items[itemIndex] = _items[itemIndex].copyWith(isEquipped: false);
      notifyListeners();
    }
  }

  /// Returns the equipped item for a specific category if any
  InventoryItem? getEquippedItemForCategory(
    ProductCategory category,
    List<MarketplaceProduct> catalog,
  ) {
    for (final item in _items) {
      if (!item.isEquipped) continue;
      final product = catalog.where((p) => p.id == item.productId).firstOrNull;
      if (product != null && product.category == category) {
        return item;
      }
    }
    return null;
  }
}
