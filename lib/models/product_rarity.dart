import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Item rarity levels in the StepQuest RPG system
enum ProductRarity {
  common(
    label: 'Commun',
    color: Color(0xFF64748B),
    softColor: Color(0xFFF1F5F9),
    icon: Icons.shield_outlined,
  ),
  rare(
    label: 'Rare',
    color: AppColors.primary,
    softColor: AppColors.primarySoft,
    icon: Icons.star_border_rounded,
  ),
  epic(
    label: 'Épique',
    color: Color(0xFF8B5CF6),
    softColor: Color(0xFFF5F3FF),
    icon: Icons.auto_awesome_rounded,
  ),
  legendary(
    label: 'Légendaire',
    color: Color(0xFFF59E0B),
    softColor: Color(0xFFFFFBEB),
    icon: Icons.workspace_premium_rounded,
  );

  final String label;
  final Color color;
  final Color softColor;
  final IconData icon;

  const ProductRarity({
    required this.label,
    required this.color,
    required this.softColor,
    required this.icon,
  });

  static ProductRarity fromString(String val) {
    final lower = val.toLowerCase();
    if (lower.contains('legendary') || lower.contains('légendaire') || lower.contains('legendaire')) {
      return ProductRarity.legendary;
    }
    if (lower.contains('epic') || lower.contains('épique') || lower.contains('epique')) {
      return ProductRarity.epic;
    }
    if (lower.contains('rare')) {
      return ProductRarity.rare;
    }
    return ProductRarity.common;
  }
}
