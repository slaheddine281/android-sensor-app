import 'package:flutter/material.dart';
import '../models/marketplace_product.dart';
import '../models/product_category.dart';
import '../models/product_rarity.dart';

/// Pre-populated catalog of StepQuest Marketplace items
final List<MarketplaceProduct> initialMockProducts = [
  // --- SHOES ---
  const MarketplaceProduct(
    id: 'prod-shoes-01',
    name: 'Runner Shoes',
    description:
        'Chaussures légères et dynamiques spécialement conçues pour les sessions de marche intensive et de footing urbain.',
    category: ProductCategory.shoes,
    rarity: ProductRarity.rare,
    price: 500,
    image: 'runner_shoes',
    iconData: Icons.directions_walk_rounded,
    levelRequired: 5,
    bonusType: 'XP de Marche',
    bonusValue: '+5% XP',
    isDailyDeal: true,
    discountPercentage: 10, // 450 Coins in daily deal
  ),
  const MarketplaceProduct(
    id: 'prod-shoes-02',
    name: 'Speed Runner',
    description:
        'Semelle en mousse réactive offrant un retour d\'énergie supérieur sur les parcours quotidiens et les sentiers.',
    category: ProductCategory.shoes,
    rarity: ProductRarity.epic,
    price: 900,
    image: 'speed_runner',
    iconData: Icons.directions_run_rounded,
    levelRequired: 10,
    bonusType: 'XP de Marche',
    bonusValue: '+10% XP',
    isFeatured: true,
  ),
  const MarketplaceProduct(
    id: 'prod-shoes-03',
    name: 'Legendary Runner',
    description:
        'Paire forgée par les maîtres marcheurs de StepQuest. Confère une vélocité sans égale à chaque foulée.',
    category: ProductCategory.shoes,
    rarity: ProductRarity.legendary,
    price: 2000,
    image: 'legendary_runner',
    iconData: Icons.electric_bolt_rounded,
    levelRequired: 20,
    bonusType: 'XP de Marche',
    bonusValue: '+15% XP',
    isLimited: true,
    stock: 25,
  ),

  // --- OUTFITS ---
  const MarketplaceProduct(
    id: 'prod-outfit-01',
    name: 'Energy Outfit',
    description:
        'Tenue respirante haute performance en tissu technique thermorégulateur pour une endurance prolongée.',
    category: ProductCategory.outfits,
    rarity: ProductRarity.rare,
    price: 700,
    image: 'energy_outfit',
    iconData: Icons.checkroom_rounded,
    levelRequired: 5,
    bonusType: 'Endurance',
    bonusValue: '+10% Énergie',
    isDailyDeal: true,
    discountPercentage: 15, // 595 Coins in daily deal
  ),
  const MarketplaceProduct(
    id: 'prod-outfit-02',
    name: 'Explorer Outfit',
    description:
        'Équipement tout-terrain renforcé avec multiples poches et protection contre les intempéries pour explorateurs chevronnés.',
    category: ProductCategory.outfits,
    rarity: ProductRarity.epic,
    price: 1200,
    image: 'explorer_outfit',
    iconData: Icons.hiking_rounded,
    levelRequired: 12,
    bonusType: 'XP Exploration',
    bonusValue: '+12% XP',
    isFeatured: true,
  ),
  const MarketplaceProduct(
    id: 'prod-outfit-03',
    name: 'Cyber Armor Suit',
    description:
        'Armure nanotechnologique légère avec néons bleus pulsés calés sur votre rythme cardiaque.',
    category: ProductCategory.outfits,
    rarity: ProductRarity.legendary,
    price: 2400,
    image: 'cyber_armor',
    iconData: Icons.shield_moon_rounded,
    levelRequired: 18,
    bonusType: 'Protection & XP',
    bonusValue: '+15% XP',
    isLimited: true,
    stock: 50,
  ),

  // --- BACKPACKS ---
  const MarketplaceProduct(
    id: 'prod-backpack-01',
    name: 'Urban Backpack',
    description:
        'Sac à dos ergonomique compact idéal pour les trajets du quotidien, le travail ou les courtes randonnées.',
    category: ProductCategory.backpacks,
    rarity: ProductRarity.common,
    price: 300,
    image: 'urban_backpack',
    iconData: Icons.backpack_outlined,
    levelRequired: 1,
    bonusType: 'Capacité Sac',
    bonusValue: '+5 Slots',
    isDailyDeal: true,
    discountPercentage: 0,
  ),
  const MarketplaceProduct(
    id: 'prod-backpack-02',
    name: 'Explorer Backpack',
    description:
        'Sac d\'expédition compartimenté avec sangles pectorales et poches d\'hydratation haute capacité.',
    category: ProductCategory.backpacks,
    rarity: ProductRarity.epic,
    price: 800,
    image: 'explorer_backpack',
    iconData: Icons.backpack_rounded,
    levelRequired: 10,
    bonusType: 'Récompenses Quêtes',
    bonusValue: '+10% Quest Rewards',
    isFeatured: true,
  ),
  const MarketplaceProduct(
    id: 'prod-backpack-03',
    name: 'Tactical Holster',
    description:
        'Ceinture et sacoche tactique ultra-légère fixée à la hanche pour une liberté de mouvement totale.',
    category: ProductCategory.backpacks,
    rarity: ProductRarity.rare,
    price: 550,
    image: 'tactical_holster',
    iconData: Icons.work_outline_rounded,
    levelRequired: 4,
    bonusType: 'Agilité',
    bonusValue: '+6% Vitesse',
  ),

  // --- ACCESSORIES ---
  const MarketplaceProduct(
    id: 'prod-acc-01',
    name: 'Fitness Band',
    description:
        'Bracelet connecté intelligent analysant chaque foulée, fréquence cardiaque et cadences de marche en temps réel.',
    category: ProductCategory.accessories,
    rarity: ProductRarity.rare,
    price: 600,
    image: 'fitness_band',
    iconData: Icons.watch_outlined,
    levelRequired: 7,
    bonusType: 'Précision Podomètre',
    bonusValue: '+8% Coins',
    isFeatured: true,
  ),
  const MarketplaceProduct(
    id: 'prod-acc-02',
    name: 'Cyber Visor',
    description:
        'Visière HUD holographique affichant vos métriques de marche en surimpression dans votre champ de vision.',
    category: ProductCategory.accessories,
    rarity: ProductRarity.epic,
    price: 750,
    image: 'cyber_visor',
    iconData: Icons.remove_red_eye_outlined,
    levelRequired: 9,
    bonusType: 'Navigation GPS',
    bonusValue: '+10% Vitesse',
    isDailyDeal: true,
    discountPercentage: 20, // 600 Coins in daily deal
  ),

  // --- BOOSTERS ---
  const MarketplaceProduct(
    id: 'prod-booster-01',
    name: 'XP Booster',
    description:
        'Potion énergisante qui double temporairement tous les gains d\'expérience obtenus lors de vos sessions de marche.',
    category: ProductCategory.boosters,
    rarity: ProductRarity.rare,
    price: 250,
    image: 'xp_booster',
    iconData: Icons.bolt_rounded,
    levelRequired: 3,
    bonusType: 'Multiplicateur XP (1h)',
    bonusValue: 'x2 XP',
    isDailyDeal: true,
    discountPercentage: 20, // 200 Coins
  ),
  const MarketplaceProduct(
    id: 'prod-booster-02',
    name: 'Quest Booster',
    description:
        'Amplificateur de succès augmentant de 50% la valeur des récompenses attribuées à l\'accomplissement des quêtes.',
    category: ProductCategory.boosters,
    rarity: ProductRarity.epic,
    price: 400,
    image: 'quest_booster',
    iconData: Icons.rocket_launch_rounded,
    levelRequired: 8,
    bonusType: 'Bonus Quêtes (2h)',
    bonusValue: '+50% Récompenses',
    isFeatured: true,
  ),
  const MarketplaceProduct(
    id: 'prod-booster-03',
    name: 'Coin Booster',
    description:
        'Catalyseur doré augmentant considérablement le nombre de Coins récoltés à chaque palier de 1000 pas.',
    category: ProductCategory.boosters,
    rarity: ProductRarity.rare,
    price: 350,
    image: 'coin_booster',
    iconData: Icons.monetization_on_outlined,
    levelRequired: 5,
    bonusType: 'Multiplicateur Coins (2h)',
    bonusValue: 'x1.5 Coins',
    isDailyDeal: true,
    discountPercentage: 15,
  ),

  // --- REWARDS & BADGES ---
  const MarketplaceProduct(
    id: 'prod-reward-01',
    name: 'First Steps Badge',
    description:
        'Insigne officiel commémorant vos premières foulées et votre adhésion à la communauté des marcheurs StepQuest.',
    category: ProductCategory.rewards,
    rarity: ProductRarity.common,
    price: 100,
    image: 'first_steps_badge',
    iconData: Icons.military_tech_outlined,
    levelRequired: 1,
    bonusType: 'Prestige',
    bonusValue: '+50 XP',
  ),
  const MarketplaceProduct(
    id: 'prod-reward-02',
    name: 'Golden Badge',
    description:
        'Distinction prestigieuse accordée aux marcheurs d\'élite ayant franchi des centaines de kilomètres cumulés.',
    category: ProductCategory.rewards,
    rarity: ProductRarity.legendary,
    price: 1500,
    image: 'golden_badge',
    iconData: Icons.workspace_premium_rounded,
    levelRequired: 15,
    bonusType: 'Prestige Héroïque',
    bonusValue: '+20% Coins',
    isLimited: true,
    stock: 10,
  ),
  const MarketplaceProduct(
    id: 'prod-reward-03',
    name: 'Marathon Badge',
    description:
        'Emblème d\'honneur récompensant la ténacité et la régularité sur les longues distances d\'endurance.',
    category: ProductCategory.rewards,
    rarity: ProductRarity.epic,
    price: 1000,
    image: 'marathon_badge',
    iconData: Icons.emoji_events_rounded,
    levelRequired: 15,
    bonusType: 'Honneur Athlétique',
    bonusValue: '+500 XP',
  ),
  const MarketplaceProduct(
    id: 'prod-reward-04',
    name: 'Legendary Walker Badge',
    description:
        'Le pinacle absolu de StepQuest. Réservé aux légendes vivantes qui ont fait du monde leur terrain de jeu.',
    category: ProductCategory.rewards,
    rarity: ProductRarity.legendary,
    price: 2500,
    image: 'legendary_walker_badge',
    iconData: Icons.military_tech_rounded,
    levelRequired: 25,
    bonusType: 'Titre de Légende',
    bonusValue: '+1000 XP',
    isLimited: true,
    stock: 5,
  ),
];
