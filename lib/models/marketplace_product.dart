import 'package:flutter/material.dart';
import 'product_category.dart';
import 'product_rarity.dart';

/// Marketplace product representing an in-game cosmetic, gear or booster item
class MarketplaceProduct {
  final String id;
  final String name;
  final String description;
  final ProductCategory category;
  final ProductRarity rarity;
  final int price;
  final String image;
  final IconData? iconData;
  final int levelRequired;
  final String? bonusType;
  final String? bonusValue;
  final bool isFeatured;
  final bool isDailyDeal;
  final bool isLimited;
  final int? stock;
  final int? discountPercentage;

  const MarketplaceProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.price,
    required this.image,
    this.iconData,
    this.levelRequired = 1,
    this.bonusType,
    this.bonusValue,
    this.isFeatured = false,
    this.isDailyDeal = false,
    this.isLimited = false,
    this.stock,
    this.discountPercentage,
  });

  /// Price after applying discount percentage if any
  int get effectivePrice {
    if (discountPercentage != null && discountPercentage! > 0) {
      final discounted = (price * (100 - discountPercentage!) / 100).round();
      return discounted > 0 ? discounted : 0;
    }
    return price;
  }

  bool get hasDiscount =>
      discountPercentage != null && discountPercentage! > 0;

  bool get isAvailable => stock == null || stock! > 0;

  MarketplaceProduct copyWith({
    String? id,
    String? name,
    String? description,
    ProductCategory? category,
    ProductRarity? rarity,
    int? price,
    String? image,
    IconData? iconData,
    int? levelRequired,
    String? bonusType,
    String? bonusValue,
    bool? isFeatured,
    bool? isDailyDeal,
    bool? isLimited,
    int? stock,
    int? discountPercentage,
  }) {
    return MarketplaceProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rarity: rarity ?? this.rarity,
      price: price ?? this.price,
      image: image ?? this.image,
      iconData: iconData ?? this.iconData,
      levelRequired: levelRequired ?? this.levelRequired,
      bonusType: bonusType ?? this.bonusType,
      bonusValue: bonusValue ?? this.bonusValue,
      isFeatured: isFeatured ?? this.isFeatured,
      isDailyDeal: isDailyDeal ?? this.isDailyDeal,
      isLimited: isLimited ?? this.isLimited,
      stock: stock ?? this.stock,
      discountPercentage: discountPercentage ?? this.discountPercentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'rarity': rarity.name,
      'price': price,
      'image': image,
      'levelRequired': levelRequired,
      'bonusType': bonusType,
      'bonusValue': bonusValue,
      'isFeatured': isFeatured,
      'isDailyDeal': isDailyDeal,
      'isLimited': isLimited,
      'stock': stock,
      'discountPercentage': discountPercentage,
    };
  }

  factory MarketplaceProduct.fromMap(Map<String, dynamic> map) {
    return MarketplaceProduct(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      category: ProductCategory.fromString(map['category'] as String? ?? 'outfits'),
      rarity: ProductRarity.fromString(map['rarity'] as String? ?? 'common'),
      price: (map['price'] as num).toInt(),
      image: map['image'] as String? ?? 'default_item',
      levelRequired: (map['levelRequired'] as num?)?.toInt() ?? 1,
      bonusType: map['bonusType'] as String?,
      bonusValue: map['bonusValue'] as String?,
      isFeatured: map['isFeatured'] as bool? ?? false,
      isDailyDeal: map['isDailyDeal'] as bool? ?? false,
      isLimited: map['isLimited'] as bool? ?? false,
      stock: (map['stock'] as num?)?.toInt(),
      discountPercentage: (map['discountPercentage'] as num?)?.toInt(),
    );
  }
}
