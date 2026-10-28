import 'package:flutter/material.dart';

/// Product categories available in the StepQuest Marketplace
enum ProductCategory {
  outfits('Tenues', Icons.checkroom_outlined),
  shoes('Chaussures', Icons.directions_walk_rounded),
  accessories('Accessoires', Icons.watch_outlined),
  backpacks('Sacs à dos', Icons.backpack_outlined),
  boosters('Boosters', Icons.bolt_rounded),
  rewards('Récompenses', Icons.military_tech_outlined);

  final String label;
  final IconData icon;

  const ProductCategory(this.label, this.icon);

  static ProductCategory fromString(String val) {
    final lower = val.toLowerCase();
    if (lower.contains('tenue') || lower.contains('outfit')) {
      return ProductCategory.outfits;
    }
    if (lower.contains('chaussure') || lower.contains('shoe')) {
      return ProductCategory.shoes;
    }
    if (lower.contains('accessoire') || lower.contains('accessory')) {
      return ProductCategory.accessories;
    }
    if (lower.contains('sac') || lower.contains('backpack')) {
      return ProductCategory.backpacks;
    }
    if (lower.contains('booster')) {
      return ProductCategory.boosters;
    }
    if (lower.contains('recompense') || lower.contains('reward') || lower.contains('badge')) {
      return ProductCategory.rewards;
    }
    return ProductCategory.outfits;
  }
}
