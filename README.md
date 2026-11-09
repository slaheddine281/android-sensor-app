# StepQuest — Plateforme Intelligente de Gestion des Utilisateurs & Reconnaissance Faciale IA

Bienvenue dans le dépôt officiel de **StepQuest**, une application moderne et sécurisée sous **Flutter (Material 3)** dédiée au suivi fitness connecté, à la gestion avancée des utilisateurs et à l'authentification biométrique par **Intelligence Artificielle (Face ID 128D)** avec synchronisation Cloud **Supabase**.

---

## 📑 Sommaire

1. [Points Forts & Innovations Clés](#-points-forts--innovations-clés)
2. [Architecture Technique & Stack](#-architecture-technique--stack)
3. [Vue d'Ensemble des Écrans (21 Écrans et Composants)](#-vue-densemble-des-écrans-21-écrans-et-composants)
   - [Espace Utilisateur & Authentification (12 Écrans)](#1-espace-utilisateur--authentification)
   - [Espace Administrateur (6 Écrans)](#2-espace-administrateur)
   - [Modules Partagés, Biométrie IA & Notifications (3 Écrans)](#3-modules-partagés-biométrie-ia--notifications)
4. [Sécurité Biométrique Face ID IA Exclusif](#-sécurité-biométrique-face-id-ia-exclusif)
5. [Contrôles de Saisie Avancés & Expérience Utilisateur (UI/UX)](#-contrôles-de-saisie-avancés--expérience-utilisateur-uiux)
6. [Intégration Backend Supabase](#-intégration-backend-supabase)
7. [Structure Complète du Code Source](#-structure-complète-du-code-source)
8. [Tests & Qualité du Code (12/12 Validés)](#-tests--qualité-du-code-1212-validés)
9. [Installation & Lancement](#-installation--lancement)

---

## 🚀 Points Forts & Innovations Clés

* **📸 Face ID IA en Temps Réel (Web)** : Modèle de deep learning embarqué dans le navigateur via `face-api.min.js` et pont JavaScript (`face_recognition_bridge.js`). Extraction d'un vecteur d'empreinte faciale de 128 dimensions, calcul de distance euclidienne et correspondance instantanée avec niveau de confiance (%).
* **📱 Face ID Natif (Android / iOS)** : invite biométrique officielle du téléphone via `local_auth` (Face ID, Face Unlock, empreinte), liée au compte enrôlé sur l'appareil — aucun scan caméra bloqué, aucun enregistrement d'image.
* **🚫 Zéro Empreinte Digitale** : Abandon complet de l'empreinte digitale mockée au profit exclusif de la reconnaissance faciale Face ID native et moderne.
* **🛡️ Backend Supabase Robuste** : Inscription, connexion, mise à jour de profil et réinitialisation de mot de passe (`type=recovery`) synchronisés en temps réel avec PostgreSQL et politiques RLS (*Row Level Security*).
* **✨ Splash Screen Pro Animé** : Halo lumineux néon pulsant en boucle (`AnimationController`), montée en échelle douce de l'emblème, badges technologiques animés et jauge de progression système.
* **⚡ Contrôles de Saisie Interactifs** :
  * Validation d'e-mail selon le standard RFC regex avec nettoyage des espaces (*trim*).
  * Composant dynamique `PasswordStrengthIndicator` avec barre de progression colorée (Rouge, Ambre, Bleu, Émeraude) et checklist animée des critères de sécurité.
  * Validation dynamique de confirmation du mot de passe en temps réel.
  * Validation du nom sans caractères numériques.
* **📊 Dashboard Administrateur Interactif** : 4 KPIs calculés en direct sur les utilisateurs Supabase, graphique d'activité dynamique basé sur les dates d'inscription réelles (`UserActivityChart`), liste paginée/filtrable, création et édition d'utilisateurs.
* **🌓 Thème Dynamique & Design Sombre** : Palette futuriste marine navy (`#091829`, `#0F2A47`), mode sombre natif, cartes avec bordures néon douces et typographie Material 3 soignée.

---

## 🛠️ Architecture Technique & Stack

* **Framework :** [Flutter](https://flutter.dev) (v3.24+ / Material 3)
* **Langages :** Dart 3, JavaScript (ES6+ Web Bridge)
* **Backend Cloud :** [Supabase](https://supabase.com) (Auth, PostgreSQL, Row Level Security)
* **Vision & IA :** Réseaux neuronaux convolutifs Face-API (détection de points de repère faciaux et descripteur d'embedding 128D)
* **Gestion d'État :** Architecture `ChangeNotifier` découplée (`AuthState`, `UserState`, `NotificationState`, `AppSettingsState`) et injectée via `AppStateProvider` (`InheritedWidget`)

---

## 📱 Vue d'Ensemble des Écrans (21 Écrans et Composants)

### 1. Espace Utilisateur & Authentification

1. **Splash Screen (`splash_screen.dart`)** :
   * Page d'accueil futuriste avec halo néon pulsant.
   * Détection intelligente de session active Supabase ou de lien de récupération de mot de passe (`type=recovery`).
   * Badges technologiques animés (*Face ID IA*, *Sécurité Supabase*, *Suivi Temps Réel*) et jauge de statut.
2. **Connexion (`login_screen.dart`)** :
   * Champs e-mail et mot de passe épurés (aucun identifiant de test pré-rempli).
   * Validation RFC temps réel sur frappe (`AutovalidateMode.onUserInteraction`).
   * Bouton rapide haute précision *"Connexion sécurisée Face ID"*.
   * Lien direct vers l'Espace Administrateur et mot de passe oublié.
3. **Inscription (`register_screen.dart`)** :
   * Contrôle strict du nom, e-mail et mot de passe.
   * Indicateur interactif de force du mot de passe avec critères dynamiques (longueur, majuscule, chiffre, caractère spécial).
   * Vérification de correspondance du mot de passe en direct.
   * Redirection directe vers la configuration biométrique Face ID après création.
4. **Mot de passe oublié (`forgot_password_screen.dart`)** :
   * Champ e-mail avec validation immédiate.
   * Envoi du lien de récupération Supabase Auth et confirmation visuelle animée.
5. **Réinitialisation du mot de passe (`reset_password_screen.dart`)** :
   * Prise en charge automatique de la session depuis l'URL de récupération du mail.
   * Champs de secours E-mail + Token pour saisie manuelle si le lien s'ouvre hors session.
   * Jauge de force et vérification de conformité du nouveau mot de passe.
6. **Enrôlement Face ID (`face_enrollment_screen.dart`)** :
   * **Web** : intégration directe du flux vidéo webcam HTML5 (`HtmlElementView`), visée faciale avec ovale guide, laser scanner animé et capture d'empreinte 128D.
   * **Android / iOS** : activation du Face ID / capteur biométrique natif du téléphone via `local_auth`, sans jamais enregistrer d'image du visage.
   * Sauvegarde de l'embedding 128D (Web) ou d'un marqueur d'appareil (mobile) dans `profiles.face_embedding`.
7. **Configuration biométrique (`biometric_setup_screen.dart`)** :
   * Dédié à 100% à la reconnaissance faciale Face ID.
   * Affichage du statut d'enrôlement du modèle 128D, interrupteur d'activation, boutons pour recalibrer le visage ou tester le scanner.
8. **Accueil utilisateur (`user_home_screen.dart`)** :
   * Salutation personnalisée en direct, niveau fitness, raccourcis Profil, Paramètres et Sécurité Face ID.
   * Cloche de notifications avec compteur dynamique.
9. **Profil utilisateur (`user_profile_screen.dart`)** :
   * Avatar universel (photo de profil ou initiales dynamiques), métriques morphologiques (taille, poids, niveau).
   * Statut du Face ID configuré et accès aux modifications.
10. **Modifier le profil (`edit_profile_screen.dart`)** :
    * Modification des informations personnelles, sélection de date de naissance, mensurations.
    * Synchronisation instantanée avec Supabase.
11. **Paramètres du compte (`account_settings_screen.dart`)** :
    * Bascule instantanée du Mode Sombre, gestion des unités (Métrique / Impérial), notifications, dialogue sécurisé de changement de mot de passe.
12. **Suppression du compte (`delete_account_screen.dart`)** :
    * Zone de danger sécurisée : avertissements explicites, saisie obligatoire de confirmation et fermeture définitive de session.

---

### 2. Espace Administrateur

13. **Connexion administrateur (`admin_login_screen.dart`)** :
    * Formulaire dédié sécurisé vérifiant les privilèges administrateur (bloque les utilisateurs standards).
    * Champs vierges prêts pour saisie.
14. **Tableau de bord administrateur (`admin_dashboard_screen.dart`)** :
    * 4 cartes métriques dynamiques (Total, Actifs, Suspendus, Administrateurs).
    * Courbe d'activité interactive (`UserActivityChart`) calculée selon les inscriptions réelles enregistrées dans Supabase.
15. **Liste des utilisateurs (`users_list_screen.dart`)** :
    * Recherche instantanée par nom ou adresse e-mail.
    * Filtres combinés par statut (*Tous*, *Actifs*, *Suspendus*) et par rôle (*Tous*, *Admins*, *Utilisateurs*).
    * Avatars universels, badges de statut, menu contextuel complet (Détails, Modifier, Suspendre, Supprimer).
16. **Ajouter un utilisateur Admin (`add_user_admin_screen.dart`)** :
    * Création complète d'un nouvel utilisateur directement depuis le panneau d'administration avec attribution du rôle et du statut initial.
17. **Détails de l'utilisateur (`user_details_screen.dart`)** :
    * Fiche complète avec onglets *Informations* (ID copiable, dates, statut Face ID), *Activité récente* et *Appareils associés*.
18. **Modifier un utilisateur (`edit_user_admin_screen.dart`)** :
    * Mise à jour administrative du rôle (Admin / Utilisateur), du statut (Actif / Suspendu) et des informations, avec garde-fou interdisant de dégrader le dernier administrateur.

---

### 3. Modules Partagés, Biométrie IA & Notifications

19. **Authentification biométrique plein écran (`biometric_auth_screen.dart`)** :
    * **Web** : scanner Face ID haute précision avec flux caméra, visée en 4 coins, scan laser animé et comparaison temps réel du visage capturé avec l'embedding 128D stocké.
    * **Android / iOS** : invite biométrique native du système (Face ID, Face Unlock ou empreinte) via `local_auth`, avec délai maximal et arrêt propre de la caméra pour éviter tout scan bloqué ou infini.
20. **Centre de notifications (`notifications_screen.dart`)** :
    * Historique complet des événements du compte (Connexions, Enrôlement Face ID, Mises à jour de profil, Actions administrateurs).
    * Filtres par catégorie et bouton *Tout marquer comme lu*.
21. **Dialogue de confirmation standardisé (`confirmation_dialog.dart`)** :
    * Modale réutilisable pour toutes les actions critiques (Suspension, Suppression, Changement de rôle).

---

## 🔒 Sécurité Biométrique Face ID (Web IA & Natif Mobile)

Dans les versions précédentes, une simulation d'empreinte digitale était présente. **Elle a été complètement retirée de tout le projet** pour se concentrer sur une solution biométrique moderne, unifiée et réellement fonctionnelle sur téléphone :

### Sur le Web — reconnaissance faciale IA 128D
1. **Extraction de descripteur facial 128D** : Lorsque l'utilisateur positionne son visage dans le cadre de la caméra, un réseau de neurones convolutif localise 68 points de repère faciaux et génère un vecteur numérique normalisé de 128 réels.
2. **Stockage sécurisé** : Seul ce vecteur mathématique est stocké (champ JSON `profiles.face_embedding`), aucune photo brute du visage n'est conservée sans consentement.
3. **Reconnaissance à la connexion** : Lors du clic sur *"Connexion sécurisée Face ID"*, la caméra compare en temps réel le visage de l'utilisateur avec l'embedding enregistré via la distance euclidienne. Un score de similarité supérieur au seuil autorise instantanément la connexion.

### Sur Android / iOS — biométrie native du téléphone
1. **Face ID / capteur système** : `local_auth` déclenche l'invite biométrique officielle du téléphone (Face ID, Face Unlock, empreinte). Aucune image ni vidéo du visage ne transite par l'application.
2. **Liaison stricte au compte** : lors de l'enrôlement, l'e-mail du compte est associé localement à l'appareil (`shared_preferences`). La biométrie système prouvant seulement l'identité du propriétaire de l'appareil, cette liaison empêche de saisir l'e-mail d'un autre utilisateur puis de valider son propre doigt.
3. **Aucun scan infini** : chaque ouverture de caméra et chaque scan possède un délai maximal, la caméra est arrêtée explicitement à la fermeture de l'écran, et le prompt natif ne se relance jamais tout seul après un échec.

> ⚙️ **Configuration Android requise** : `MainActivity` hérite de `FlutterFragmentActivity`, les thèmes `LaunchTheme` / `NormalTheme` héritent de `Theme.AppCompat.DayNight.NoActionBar`, et les permissions `USE_BIOMETRIC` / `USE_FINGERPRINT` sont déclarées. Sur iOS, `NSFaceIDUsageDescription` est présent dans `Info.plist`.

---

## ⚡ Contrôles de Saisie Avancés & Expérience Utilisateur (UI/UX)

* **Validation Regex RFC d'adresse e-mail** :
  ```dart
  RegExp(r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$")
  ```
* **Jauge dynamique de robustesse de mot de passe** ([`PasswordStrengthIndicator`](file:///c:/Users/user/Desktop/stepquest/lib/widgets/password_strength_indicator.dart)) :
  * Calcul d'un score de 0 à 4 avec retour visuel progressif.
  * Validation dynamique des 4 règles :
    * Minimum 8 caractères.
    * Combinaison Majuscules & Minuscules.
    * Au moins un chiffre (0-9).
    * Au moins un caractère spécial (`!@#$%^&*...`).
* **Validation instantanée de correspondance** :
  * Le champ de confirmation vérifie en continu l'égalité exacte avec le mot de passe principal.
* **Formatage & Nettoyage** :
  * Découpage automatique des espaces superflus (*trim*).
  * Masquage / affichage interactif du mot de passe avec icône œil réactive.

---

## 🗄️ Intégration Backend Supabase

Le schéma SQL est défini dans [`supabase_schema.sql`](file:///c:/Users/user/Desktop/stepquest/supabase_schema.sql) :

* **Table `public.profiles`** liée directement à `auth.users(id)` :
  * Colonnes : `id`, `full_name`, `email`, `role` (`user` / `admin`), `status` (`active` / `suspended`), `avatar_url`, `face_embedding`, `biometric_face_enabled`, `height_cm`, `weight_kg`, `level`, `birth_date`, `created_at`, `last_login_at`.
* **Sécurité RLS (Row Level Security)** :
  * Les utilisateurs peuvent lire et modifier leur propre profil.
  * Les administrateurs disposent des droits de lecture et d'administration sur tous les profils via la fonction `is_admin()`.
  * Trigger automatique PostgreSQL créant une ligne dans `public.profiles` à chaque nouvel enregistrement dans `auth.users`.

---

## 📂 Structure Complète du Code Source

```text
lib/
├── app.dart                                    # Configuration MaterialApp, thèmes et routes
├── main.dart                                   # Initialisation Supabase et démarrage
├── core/
│   ├── constants/
│   │   ├── app_constants.dart                  # Constantes applicatives
│   │   └── supabase_constants.dart             # Configuration Supabase URL & Anon Key
│   ├── navigation/
│   │   └── app_router.dart                     # Routage nommé et guards administrateurs
│   ├── theme/
│   │   ├── app_colors.dart                     # Palette de couleurs officielles
│   │   ├── app_text_styles.dart                # Typographies Material 3
│   │   └── app_theme.dart                      # Thèmes clair et sombre
│   └── utils/
│       └── date_formatter.dart                 # Formatage des dates en français
├── data/
│   ├── mock_notifications.dart                 # Données de repli
│   └── mock_users.dart                         # Données de démonstration
├── features/
│   ├── admin/screens/
│   │   ├── add_user_admin_screen.dart          # Ajout d'utilisateur
│   │   ├── admin_dashboard_screen.dart         # Dashboard administrateur avec graphe réel
│   │   ├── admin_login_screen.dart             # Connexion administrateur
│   │   ├── edit_user_admin_screen.dart         # Modification administrateur
│   │   ├── user_details_screen.dart            # Fiche détaillée utilisateur
│   │   └── users_list_screen.dart              # Liste avec recherche et filtres
│   ├── shared/screens/
│   │   ├── biometric_auth_screen.dart          # Scanner Face ID plein écran
│   │   └── notifications_screen.dart           # Centre de notifications
│   └── user/screens/
│       ├── account_settings_screen.dart        # Paramètres du compte
│       ├── biometric_setup_screen.dart         # Configuration Face ID
│       ├── delete_account_screen.dart          # Suppression sécurisée
│       ├── edit_profile_screen.dart            # Édition profil
│       ├── face_enrollment_screen.dart         # Enrôlement facial webcam
│       ├── forgot_password_screen.dart         # Récupération de compte
│       ├── login_screen.dart                   # Connexion utilisateur
│       ├── register_screen.dart                # Inscription & jauge mot de passe
│       ├── reset_password_screen.dart          # Nouveau mot de passe
│       ├── splash_screen.dart                  # Splash screen animé
│       ├── user_home_screen.dart               # Accueil utilisateur
│       └── user_profile_screen.dart            # Profil utilisateur
├── models/
│   ├── app_user.dart                           # Modèle utilisateur, rôles et statuts
│   └── user_notification.dart                  # Modèle notification
├── services/
│   ├── face_recognition/                       # Types et adaptateurs Face ID
│   ├── face_recognition_service.dart           # Service de détection et comparaison faciale
│   └── mock_biometric_service.dart             # Service biométrique Face ID
├── state/
│   ├── app_settings_state.dart                 # État des préférences utilisateur
│   ├── app_state_provider.dart                 # Provider racine
│   ├── auth_state.dart                         # Authentification, session & mot de passe
│   ├── notification_state.dart                 # Gestion des notifications
│   └── user_state.dart                         # Gestion CRUD des utilisateurs
└── widgets/
    ├── app_app_bar.dart                        # Barre d'en-tête standard
    ├── app_bottom_navigation.dart              # Barre de navigation inférieure
    ├── app_button.dart                         # Boutons (Primaire, Secondaire, Face ID)
    ├── app_card.dart                           # Cartes avec bordures stylisées
    ├── app_text_field.dart                     # Champs de saisie avancés avec validation
    ├── confirmation_dialog.dart                # Dialogue modal d'action
    ├── empty_state.dart                        # Vue état vide
    ├── metric_card.dart                        # Carte métrique Dashboard
    ├── password_strength_indicator.dart        # Jauge dynamique de mot de passe & critères
    ├── role_badge.dart                         # Badge rôle
    ├── status_badge.dart                       # Badge statut
    ├── stepquest_logo.dart                     # Emblème graphique StepQuest
    ├── user_activity_chart.dart                # Graphique d'activité mensuel dynamique
    └── user_avatar.dart                        # Avatar universel photo / initiales
```

---

## 🧪 Tests & Qualité du Code (12/12 Validés)

Tous les tests unitaires et tests d'intégration de widgets sont validés :

```powershell
flutter test
```

```text
00:00 +0: Initial mock users are properly populated
00:00 +1: Filter users by status and query
00:00 +2: Add new user locally (Create)
00:00 +3: Update user profile locally (Update)
00:00 +4: Suspend and reactivate user locally
00:00 +5: Prevent deleting the last administrator
00:00 +6: Standard user login success
00:00 +7: Suspended user login is blocked
00:00 +8: Admin login role verification
00:00 +9: Registration creates user and updates local state
00:00 +10: Password reset request and recovery update flow
00:02 +11: StepQuest smoke test: App launches, displays splash and navigates
00:04 +12: All tests passed!
```

---

## 💻 Installation & Lancement

### 1. Prérequis
* Flutter SDK (version 3.24 ou supérieure)
* Google Chrome ou Microsoft Edge (avec support de la caméra activé pour Face ID)

### 2. Récupérer le dépôt
```bash
git clone https://github.com/slaheddine281/android-sensor-app.git
cd android-sensor-app
git checkout usermanagement
```

### 3. Installer les dépendances
```bash
flutter pub get
```

### 4. Lancer les tests
```bash
flutter test
```

### 5. Exécuter l'application sur le Web
```bash
flutter run -d chrome
# ou
flutter run -d edge
```

---

*Développé avec passion pour l'écosystème StepQuest — All Rights Reserved.*
