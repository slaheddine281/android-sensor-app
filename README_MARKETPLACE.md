# StepQuest — Module « Marketplace »

Documentation d'architecture et de mise en œuvre du module **Marketplace / Boutique RPG Gamifiée** pour l'application Flutter StepQuest.

---

## 1. Objectif

Le module **Marketplace** prolonge directement l'architecture et la charte graphique existantes de l'application StepQuest (module *Gestion des Utilisateurs*).

L'objectif principal est de convertir l'activité physique mesurée par les capteurs (podomètre, GPS, accéléromètre) en valeur d'expérience RPG. L'utilisateur gagne des points d'expérience (**XP**), franchit des **Niveaux** et amasse des pièces virtuelles (**Coins**). La Marketplace lui offre la possibilité de dépenser ses Coins dans des équipements esthétiques, des bonus de statistiques, des tenues, des badges de prestige et des amplificateurs (boosters).

Le module réutilise fidèlement l'ensemble de l'écosystème StepQuest :
- **Design System** : Material 3, typographie Inter, palette (`#3B82F6` Primary, `#0F2A47` Navy Dark, `#10B981` Success Emerald, `#F59E0B` Amber Coins).
- **Architecture d'état** : Inhérence Flutter native via `AppStateProvider` (`InheritedWidget`) et `ChangeNotifier` sans dépendance tierce intrusive.
- **Système de notification** : Extension directe de `NotificationState` et de `NotificationsScreen`.
- **Navigation** : Évolution transparente de `AppBottomNavigation` (4 onglets unifiés : Accueil, Boutique, Profil, Paramètres) et `AppRoutes`.
- **Composants réutilisables** : `AppCard`, `AppButton`, `ConfirmationDialog`, `EmptyState`, `UserAvatar`, `AppAppBar`.

---

## 2. Écrans réalisés

L'ensemble des 9 écrans et flux du cahier des charges a été développé :

| N° | Écran | Fichier | Description |
|---|---|---|---|
| **01** | **Marketplace Home** | `lib/features/marketplace/screens/marketplace_home_screen.dart` | Titre *StepQuest Store*, bandeau joueur (Niveau, XP 2450/3000, Solde 🪙 1 250 Coins), barre de recherche, filtre par catégories, raccourcis et 4 sections d'objets (*En Vedette*, *Offres du Jour*, *Éditions Limitées*, *Catalogue Complet*). |
| **02** | **Category Products** | `lib/features/marketplace/screens/marketplace_category_screen.dart` | Vue dédiée par catégorie avec filtres de rareté (*Tous*, *Commun*, *Rare*, *Épique*, *Légendaire*), tri dynamique (*Prix croissant/décroissant*, *Rareté*, *Niveau*), recherche et grille adaptative. |
| **03** | **Product Details** | `lib/features/marketplace/screens/product_details_screen.dart` | Illustration avec halo de rareté, nom, badge de rareté, catégorie, description immersive, bonus RPG actif, contrôle du niveau requis, solde avant/après et CTA contextuel (*Acheter*, *Équiper*, *Déséquiper*, *Niveau insuffisant*). |
| **04** | **Purchase Confirmation** | `lib/widgets/purchase_dialog.dart` | Boîte de dialogue conforme à `ConfirmationDialog` affichant le prix de l'objet, le solde actuel, le solde restant calculé et les actions *Annuler* / *Acheter maintenant*. |
| **05** | **Purchase Success** | `lib/features/marketplace/screens/purchase_success_screen.dart` | Écran de célébration avec badge animé `✓ OBJET DÉBLOQUÉ !`, résumé de l'objet et boutons *Équiper maintenant* ou *Continuer mes achats*. |
| **06** | **Daily Shop** | `lib/features/marketplace/screens/daily_shop_screen.dart` | Boutique du Jour avec compte à rebours interactif cadencé à la seconde (`Renouvellement dans XX:XX:XX`), réductions exclusives jusqu'à -20% et objets spéciaux. |
| **07** | **Wishlist** | `lib/features/marketplace/screens/wishlist_screen.dart` | Liste de favoris permettant d'enregistrer des équipements convoités, avec badge de compteur en temps réel, ajout/retrait et consultation. |
| **08** | **Inventory** | `lib/features/marketplace/screens/inventory_screen.dart` | Inventaire personnel classé par catégories (*Tenues*, *Chaussures*, *Sacs à dos*, *Accessoires*, *Boosters*, *Récompenses*), statut équipé, actions *Équiper* / *Déséquiper* et accès direct à la personnalisation. |
| **09** | **Character Customization** | `lib/features/marketplace/screens/character_customization_screen.dart` | Mannequin de héros RPG StepQuest affichant l'avatar, les 4 emplacements d'armure active (*Tenue*, *Chaussures*, *Sac à dos*, *Accessoire*), le cumul des bonus RPG et la sélection modale d'équipements possédés. |

---

## 3. Architecture

L'arborescence s'insère naturellement dans la structure existante du projet StepQuest :

```
lib/
├── core/
│   ├── navigation/
│   │   └── app_router.dart                     [MIS À JOUR - Routes /store, /inventory, etc.]
│   └── theme/
│       ├── app_colors.dart                     [Palette StepQuest]
│       └── app_theme.dart                      [Thèmes Light & Dark]
├── data/
│   ├── mock_products.dart                      [NOUVEAU - 18 objets réalistes]
│   ├── mock_inventory.dart                     [NOUVEAU - Inventaire initial]
│   └── mock_purchases.dart                     [NOUVEAU - Historique d'achats]
├── models/
│   ├── marketplace_product.dart                [NOUVEAU - Modèle d'objet]
│   ├── product_category.dart                   [NOUVEAU - Enum catégories]
│   ├── product_rarity.dart                     [NOUVEAU - Enum raretés]
│   ├── inventory_item.dart                     [NOUVEAU - Objet possédé]
│   ├── purchase.dart                           [NOUVEAU - Transaction d'achat]
│   └── user_notification.dart                  [MIS À JOUR - Types Marketplace]
├── services/
│   ├── mock_marketplace_service.dart          [NOUVEAU - Catalogue, recherche, filtres]
│   └── mock_purchase_service.dart             [NOUVEAU - Validation transactionnelle]
├── state/
│   ├── wallet_state.dart                       [NOUVEAU - Solde Coins sans négatif]
│   ├── inventory_state.dart                    [NOUVEAU - Équipement & slots uniques]
│   ├── marketplace_state.dart                  [NOUVEAU - Flux d'achat & Wishlist]
│   └── app_state_provider.dart                 [MIS À JOUR - Extensions contextuelles]
├── widgets/
│   ├── product_card.dart                       [NOUVEAU - Carte objet réutilisant AppCard]
│   ├── product_rarity_badge.dart               [NOUVEAU - Badge visuel de rareté]
│   ├── coin_balance.dart                       [NOUVEAU - Pilule dorée de solde Coins]
│   ├── category_chip.dart                      [NOUVEAU - Puce de filtre de catégorie]
│   ├── product_price.dart                      [NOUVEAU - Affichage tarif & promos sans overflow]
│   ├── inventory_item_card.dart                [NOUVEAU - Carte objet d'inventaire]
│   ├── purchase_dialog.dart                    [NOUVEAU - Confirmation d'achat]
│   ├── app_bottom_navigation.dart              [MIS À JOUR - 4e onglet Boutique]
│   └── app_button.dart                         [MIS À JOUR - Support hauteurs & largeurs flexibles]
└── features/
    ├── marketplace/
    │   └── screens/
    │       ├── marketplace_home_screen.dart    [Écran 01]
    │       ├── marketplace_category_screen.dart[Écran 02]
    │       ├── product_details_screen.dart     [Écran 03]
    │       ├── purchase_success_screen.dart    [Écran 05]
    │       ├── daily_shop_screen.dart          [Écran 06]
    │       ├── wishlist_screen.dart            [Écran 07]
    │       ├── inventory_screen.dart           [Écran 08]
    │       └── character_customization_screen.dart [Écran 09]
    └── user/
        └── screens/
            ├── user_home_screen.dart           [MIS À JOUR - Onglet Boutique & solde]
            ├── user_profile_screen.dart        [MIS À JOUR - Index navigation]
            └── account_settings_screen.dart    [MIS À JOUR - Index navigation]
```

---

## 4. Models

### `MarketplaceProduct`
- `id` (String) : Identifiant unique.
- `name` (String) : Nom de l'équipement.
- `description` (String) : Texte immersif RPG.
- `category` (`ProductCategory`) : Catégorie.
- `rarity` (`ProductRarity`) : Niveau de rareté.
- `price` (int) : Prix de base en Coins.
- `image` (String) & `iconData` (IconData) : Rendu vectoriel net Material 3.
- `levelRequired` (int) : Palier de niveau requis pour l'achat.
- `bonusType` (String?) & `bonusValue` (String?) : Effet RPG (ex. `+5% XP`, `x2 XP`).
- `isFeatured`, `isDailyDeal`, `isLimited` (bool) : Drapeaux de collections.
- `stock` (int?) : Gestion de stock pour les éditions limitées.
- `discountPercentage` (int?) : Pourcentage de remise.
- `effectivePrice` (getter) : Calcul automatique du tarif remisé.
- Méthodes `toMap()` et `fromMap()`.

### `ProductCategory`
Enumération : `outfits` (Tenues), `shoes` (Chaussures), `accessories` (Accessoires), `backpacks` (Sacs à dos), `boosters` (Boosters), `rewards` (Récompenses).

### `ProductRarity`
Enumération stylisée avec couleur et icône :
- `common` : Gris ardoise (`#64748B`), icône bouclier.
- `rare` : Bleu électrique StepQuest (`#3B82F6`), icône étoile.
- `epic` : Violet mystique (`#8B5CF6`), icône étincelles.
- `legendary` : Ambre doré (`#F59E0B`), icône couronne de prestige.

### `InventoryItem`
- `id`, `productId`, `userId`, `purchaseDate`, `isEquipped`, `quantity`.

### `Purchase`
- `id`, `productId`, `userId`, `purchaseDate`, `pricePaid`, `status`.

---

## 5. Mock Data

Le fichier `lib/data/mock_products.dart` contient 18 objets équilibrés selon les règles RPG :
1. **Runner Shoes** (500 Coins, Rare, Niv. 5, `+5% XP`, Promo Daily 450 Coins)
2. **Speed Runner** (900 Coins, Épique, Niv. 10, `+10% XP`, En Vedette)
3. **Legendary Runner** (2000 Coins, Légendaire, Niv. 20, `+15% XP`, Édition Limitée)
4. **Energy Outfit** (700 Coins, Rare, Niv. 5, `+10% Énergie`, Promo Daily 595 Coins)
5. **Explorer Outfit** (1200 Coins, Épique, Niv. 12, `+12% XP`, En Vedette)
6. **Cyber Armor Suit** (2400 Coins, Légendaire, Niv. 18, `+15% XP`, Édition Limitée)
7. **Urban Backpack** (300 Coins, Commun, Niv. 1, `+5 Slots`, Objet clé du scénario démo)
8. **Explorer Backpack** (800 Coins, Épique, Niv. 10, `+10% Quest Rewards`, En Vedette)
9. **Tactical Holster** (550 Coins, Rare, Niv. 4, `+6% Vitesse`)
10. **Fitness Band** (600 Coins, Rare, Niv. 7, `+8% Coins`, En Vedette)
11. **Cyber Visor** (750 Coins, Épique, Niv. 9, `+10% Vitesse`, Promo Daily 600 Coins)
12. **XP Booster** (250 Coins, Rare, Niv. 3, `x2 XP (1h)`, Promo Daily 200 Coins)
13. **Quest Booster** (400 Coins, Épique, Niv. 8, `+50% Récompenses`, En Vedette)
14. **Coin Booster** (350 Coins, Rare, Niv. 5, `x1.5 Coins (2h)`, Promo Daily 297 Coins)
15. **First Steps Badge** (100 Coins, Commun, Niv. 1, `+50 XP`)
16. **Golden Badge** (1500 Coins, Légendaire, Niv. 15, `+20% Coins`, Édition Limitée)
17. **Marathon Badge** (1000 Coins, Épique, Niv. 15, `+500 XP`)
18. **Legendary Walker Badge** (2500 Coins, Légendaire, Niv. 25, `+1000 XP`, Édition Limitée)

---

## 6. Services

- **`MockMarketplaceService`** : Fournit le catalogue, gère le filtrage multicritère (texte, rareté, catégorie), les tris (prix croissant/décroissant, rareté, niveau) et l'extraction des sections spéciales.
- **`MockPurchaseService`** : Encapsule la logique métier stricte. Vérifie l'éligibilité sans modifier l'état directement et instancie les transactions `Purchase`.

---

## 7. State Management

Intégré dans le conteneur principal `AppStateProvider` :
```dart
extension AppStateExtensions on BuildContext {
  AuthState get auth => ...;
  UserState get users => ...;
  NotificationState get notifications => ...;
  AppSettingsState get settings => ...;
  MockBiometricService get biometrics => ...;
  MarketplaceState get marketplace => ...;
  WalletState get wallet => ...;
  InventoryState get inventory => ...;
}
```
L'écouteur `ListenableBuilder` dans `app.dart` fusionne tous les états réactifs, assurant une mise à jour instantanée de l'interface lors de chaque transaction.

---

## 8. Marketplace

Gérée par `MarketplaceState` :
- Synchronisation du catalogue.
- Gestion de la liste d'envies (`wishlistProducts`, `toggleWishlist`).
- Coordination centralisée du cycle d'achat et de l'équipement des objets.

---

## 9. Purchase Flow

Le cycle d'achat complet respecte scrupuleusement la séquence d'intégrité :
1. Sélection d'un objet (`ProductDetailsScreen`).
2. Clic sur **Acheter maintenant**.
3. **Contrôle de niveau** : Si `user.level < product.levelRequired`, blocage avec le message :
   > *"Atteignez le niveau X pour débloquer cet objet."*
4. **Contrôle du solde** : Si `wallet.balance < product.effectivePrice`, blocage avec :
   > *"Vous n'avez pas assez de Coins."*
5. **Contrôle d'unicité** : Si `inventory.hasItem(product.id)`, blocage avec :
   > *"Cet objet est déjà dans votre inventaire."*
6. **Dialogue de confirmation** : Présentation des soldes avant/après achat (`showPurchaseConfirmationDialog`).
7. **Débit sécurisé** : Retrait des Coins via `wallet.removeCoins()`. Aucun Coin n'est prélevé en cas d'erreur.
8. **Enregistrement inventaire** : Ajout du nouvel `InventoryItem`.
9. **Historique** : Création d'une transaction `Purchase`.
10. **Notification** : Ajout automatique d'une alerte système dans `NotificationState` :
    > *« Achat confirmé : [Nom de l'objet] a été ajouté à votre inventaire. »*
11. **Écran de succès** : Navigation vers `PurchaseSuccessScreen` avec possibilité d'équiper l'objet immédiatement.

---

## 10. Wallet

Géré par `WalletState` :
- **Solde de démonstration initial** : `1 250 Coins`.
- Méthodes obligatoires : `addCoins()`, `removeCoins()`, `canAfford()`, `getBalance()`.
- **Règle absolue d'intégrité financière** : Le solde ne peut jamais être négatif. Toute tentative de débit supérieur au solde est refusée et retourne `false`.

---

## 11. Inventory

Géré par `InventoryState` :
- Liste réactive des objets détenus par le marcheur.
- Vérification rapide par `hasItem(productId)` et `isEquipped(productId)`.
- **Règle des emplacements uniques** : L'équipement d'un objet (`equipItem`) déséquipe automatiquement tout autre équipement appartenant au même emplacement (ex: une seule paire de chaussures ou un seul sac à dos à la fois).
- Seuls les objets possédés peuvent être équipés.

---

## 12. Character Customization

L'écran `CharacterCustomizationScreen` offre une expérience de personnalisation RPG professionnelle et épurée :
- Visualisation de l'avatar et du niveau du marcheur.
- Synthèse des **Bonus d'équipement actifs** cumulés.
- 4 cartes d'emplacement :
  1. **Tenue** (`outfits`)
  2. **Chaussures** (`shoes`)
  3. **Sac à dos** (`backpacks`)
  4. **Accessoire** (`accessories`)
- Interaction modale permettant de changer d'équipement parmi les objets possédés ou de basculer directement vers la boutique.

---

## 13. Notifications

Réutilisation intégrale du système existant :
- Extension de l'enum `NotificationType` avec :
  - `marketplacePurchase`
  - `itemEquipped`
  - `itemUnequipped`
  - `marketplaceReward`
- Prise en charge visuelle native dans `NotificationsScreen` avec icônes dorées/émeraude dédiées et filtre `Boutique`.

---

## 14. Tests

Une suite complète de **28 tests unitaires, logiques et d'intégration de widgets** a été rédigée dans `test/marketplace_test.dart` en complément des 11 tests existants de gestion des utilisateurs :

```
00:08 +39: All tests passed!
```

Couverture validée :
- ✓ Chargement des 18 produits mock
- ✓ Sérialisation `toMap` / `fromMap`
- ✓ Calcul des prix remisés
- ✓ Filtrage par catégorie
- ✓ Recherche textuelle (nom, description, bonus)
- ✓ Filtrage par rareté
- ✓ Produits en vedette, offres du jour, éditions limitées
- ✓ Solde initial 1 250 Coins
- ✓ Déduction exacte des Coins (1 250 -> 950 pour l'Urban Backpack à 300 Coins)
- ✓ Prévention des soldes négatifs
- ✓ Échec solde insuffisant (Coins intacts)
- ✓ Échec niveau insuffisant (message exact)
- ✓ Échec objet déjà possédé
- ✓ Ajout à l'inventaire
- ✓ Équipement et déséquipement
- ✓ Règle d'exclusivité d'emplacement (1 seul objet par slot)
- ✓ Sauvegarde et bascule de liste d'envies (Wishlist)
- ✓ Notification d'achat générée
- ✓ Rendu de l'écran d'accueil Marketplace
- ✓ Rendu de l'écran Catégorie
- ✓ Rendu de la Boutique du Jour avec timer
- ✓ Rendu de l'écran Wishlist et de son `EmptyState`
- ✓ Rendu de l'Inventaire
- ✓ Rendu de la Personnalisation du Héros

---

## 15. Commandes

### Vérification de l'analyse statique :
```bash
flutter analyze
```
*Résultat attendu : `No issues found!`*

### Exécution des tests :
```bash
flutter test
```
*Résultat attendu : `All tests passed!` (39 tests réussis)*

### Lancement sur Chrome ou Edge :
```bash
flutter run -d chrome
# ou
flutter run -d edge
```

---

## 16. Préparation Backend

L'architecture actuelle a été conçue pour brancher une API REST ou WebSocket sans restructurer les écrans :
- Les méthodes de `MarketplaceState` et `MockPurchaseService` sont déjà asynchrones (`Future<PurchaseExecutionResult>`).
- Les modèles implémentent `toMap()` et `fromMap()` compatibles JSON.
- Il suffira de créer un `RemoteMarketplaceService implements MarketplaceService` et de l'injecter au démarrage de `StepQuestApp`.

---

## 17. Limitations actuelles

- **Persistance locale en mémoire** : Pour les besoins académiques et de démonstration, le catalogue, le solde et l'inventaire sont conservés en mémoire vive durant la session. Le rechargement à chaud (Hot Reload) préserve l'état.
- **Capteurs réels** : Le module consomme les Coins et l'XP générés par le système de fitness sans interroger directement le capteur GPS ou podomètre en arrière-plan.
- **Paiements réels** : Aucun système bancaire réel n'est connecté ; l'ensemble des transactions s'effectue exclusivement avec les StepQuest Coins virtuels.
