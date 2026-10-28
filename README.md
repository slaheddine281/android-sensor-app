# StepQuest — Module « Gestion des Utilisateurs »

Le module complet **Gestion des utilisateurs** de l'application **StepQuest** a été intégralement développé et testé sous **Flutter (Material 3)**, en conformité stricte avec la maquette UI/UX de référence, la charte graphique et la règle absolue d'exécution autonome en mémoire (sans aucune dépendance à une base de données ou API distante pour cette phase initiale).

---

## Sommaire

1. [Synthèse des Écrans Réalisés (18 Écrans Complets)](#1-synthèse-des-écrans-réalisés-18-écrans-complets)
   - [Espace Utilisateur (10 Écrans)](#espace-utilisateur)
   - [Espace Administrateur (6 Écrans)](#espace-administrateur)
   - [Écrans et Composants Partagés (2 Écrans)](#écrans-et-composants-partagés)
2. [Architecture Complète du Projet](#2-architecture-complète-du-projet)
3. [Comptes Fictifs de Démonstration](#3-comptes-fictifs-de-démonstration)
4. [Tests et Vérifications Exécutés](#4-tests-et-vérifications-exécutés)
5. [Commandes pour Lancer le Projet](#5-commandes-pour-lancer-le-projet)
6. [Points Préparés pour la Phase Backend Ultérieure](#6-points-préparés-pour-la-phase-backend-ultérieure)

---

## 1. Synthèse des Écrans Réalisés (18 Écrans Complets)

Chaque écran de la maquette a été fidèlement implémenté, relié à l'état partagé local et doté d'interactions réelles et réactives.

### Espace Utilisateur

* **Écran 01 — Splash Screen (`splash_screen.dart`) :**
  * Fond en dégradé navy profond (`#091829` à `#0F2A47`), emblème lumineux StepQuest animé en pulsation continue et texte *"Atteins tes objectifs"*.
  * Détection simulée de session active avec redirection automatique vers l'espace approprié (Utilisateur ou Administrateur).

* **Écran 02 — Connexion (`login_screen.dart`) :**
  * Logo StepQuest, titre *"Bon retour !"*, saisie e-mail / mot de passe avec masquage/démasquage.
  * Case *"Se souvenir de moi"*, lien *"Mot de passe oublié ?"*.
  * Boutons de connexion rapide biométrique (*"Connexion par empreinte"* et *"Connexion par visage"*).
  * Raccourcis démo en 1 clic pour tester immédiatement les comptes prédéfinis et lien direct vers l'Espace Admin.

* **Écran 03 — Inscription (`register_screen.dart`) :**
  * Formulaire avec validation en temps réel : Nom complet, E-mail, Mot de passe, Confirmation, Acceptation des CGU.
  * Création instantanée dans l'état local `UserState`, notification automatique et passage fluide à la configuration biométrique.

* **Écran 04 — Mot de passe oublié (`forgot_password_screen.dart`) :**
  * Illustration enveloppe stylisée, champ e-mail avec validation.
  * Simulation pédagogique d'envoi de lien de réinitialisation avec écran de confirmation.

* **Écran 05 — Configuration biométrique (`biometric_setup_screen.dart`) :**
  * Cartes dédiées pour *Empreinte digitale* et *Reconnaissance faciale* avec badges *"● Activé"*, interrupteurs interactifs et texte explicatif.
  * Bouton *"Tester la biométrie"* ouvrant l'écran de scan animé.
  * Enregistrement répercuté directement sur le profil utilisateur.

* **Écran 06 — Accueil utilisateur (`user_home_screen.dart`) :**
  * Salutation dynamique (*"Bonjour, Amine 👋"*), cloche de notification avec pastille de non-lus.
  * Carte de niveau (*"Niveau 3 - Membre actif"*), raccourcis rapides Profil et Paramètres.
  * Section Accès rapide (*Mon profil*, *Paramètres de sécurité*, *Supprimer mon compte*).
  * Barre de navigation inférieure (*Accueil*, *Profil*, *Paramètres*).

* **Écran 07 — Profil utilisateur (`user_profile_screen.dart`) :**
  * Bannière arrondie navy, grand avatar flottant avec initiales/couleur dynamique.
  * Indicateurs statistiques en cartes : Niveau 3 (Progression), 170 cm (Taille), 65 kg (Poids).
  * Section *Informations personnelles* détaillée (Nom, E-mail, Date de naissance, Rôle, Statut, Biométrie).
  * Boutons d'action : Modifier mon profil, Paramètres, Déconnexion.

* **Écran 08 — Modifier le profil (`edit_profile_screen.dart`) :**
  * Avatar avec badge caméra, modification du nom complet, de l'email, sélecteur de date de naissance, champs taille et poids.
  * Validation en temps réel et répercussion immédiate dans tout l'état de l'application.

* **Écran 09 — Paramètres du compte (`account_settings_screen.dart`) :**
  * Interrupteur de notifications, sélecteur d'unité de mesure (Métrique / Impérial), bascule instantanée du **Mode sombre**.
  * Raccourcis vers la biométrie et dialogue de changement de mot de passe en mode démo.
  * Boutons Déconnexion et Supprimer mon compte.

* **Écran 10 — Confirmation de suppression du compte (`delete_account_screen.dart`) :**
  * Écran de sécurité rouge : rappel clair des conséquences, case d'engagement, saisie obligatoire du mot `"SUPPRIMER"`.
  * Suppression sécurisée dans l'état local sans prétendre affecter un serveur distant.

---

### Espace Administrateur

* **Écran 11 — Connexion administrateur (`admin_login_screen.dart`) :**
  * Design navy distinctif (`#0B1B2B`), logo lumineux, formulaire dédié avec vérification stricte du rôle administrateur (bloque les utilisateurs standards).
  * Raccourcis pré-remplis pour les administrateurs de test.

* **Écran 12 — Tableau de bord administrateur (`admin_dashboard_screen.dart`) :**
  * Salutation admin et 4 cartes KPI calculées dynamiquement (*Total utilisateurs*, *Actifs*, *Suspendus*, *Admins*).
  * Graphique fluide sur mesure *Évolution des utilisateurs* (courbe de Bézier avec dégradé bleu et repères mensuels Jan à Juin).
  * Accès rapide à la gestion des utilisateurs et cloche de notification.

* **Écran 13 — Liste des utilisateurs (`users_list_screen.dart`) :**
  * Barre de recherche instantanée (par nom ou email).
  * Filtres par statut (*Tous*, *Actifs*, *Suspendus*) et par rôle (*Tous*, *Admins*, *Utilisateurs*).
  * Cartes utilisateur avec avatar, nom, email, badge de rôle et badge de statut avec puce colorée.
  * Menu contextuel (*Consulter*, *Modifier*, *Suspendre / Réactiver*, *Supprimer*).
  * Bouton `+` pour ajouter un utilisateur de démonstration à la volée.
  * Vue vide stylisée (*Empty State*) en cas de filtre sans correspondance.

* **Écran 14 — Détails d'un utilisateur (`user_details_screen.dart`) :**
  * En-tête avec avatar, rôle et statut.
  * Onglets interactifs : *Informations* (identifiant copiable en 1 clic, date d'inscription, dernière connexion, biométrie active), *Activité* et *Appareils*.
  * Actions administratives directes : Modifier, Suspendre / Réactiver, Supprimer.

* **Écran 15 — Modifier un utilisateur (Admin) (`edit_user_admin_screen.dart`) :**
  * Modification du nom, e-mail, menu déroulant du rôle (*Utilisateur* / *Administrateur*) et sélecteur de statut (*Actif* / *Suspendu*).
  * Garde-fou de sécurité : empêche la suppression ou la rétrogradation du dernier administrateur actif.

* **Écran 16 — Confirmation d'action administrative (`confirmation_dialog.dart`) :**
  * Dialogue modal standardisé avec badge d'alerte circulaire (orange pour avertissement / suspension, rouge pour suppression irréversible).

---

### Écrans et Composants Partagés

* **Écran 17 — Authentification biométrique (`biometric_auth_screen.dart`) :**
  * Écran immersif navy avec capteur circulaire lumineux animé en pulsation continue.
  * Support simulation d'empreinte digitale et reconnaissance faciale avec boutons de test (*Tester succès*, *Tester échec*, *Annuler*).

* **Écran 18 — Notifications et statuts (`notifications_screen.dart`) :**
  * Écran répertoriant les événements générés par les actions dans l'application (*Compte créé*, *Compte suspendu*, *Compte réactivé*, *Connexion*, *Rôle modifié*).
  * Filtres par catégorie (*Toutes*, *Non lues*, *Comptes*, *Sécurité*) et action *Tout lire*.

---

## 2. Architecture Complète du Projet

```text
lib/
├── app.dart                                # MaterialApp, AppStateProvider et configuration thèmes
├── main.dart                               # Point d'entrée avec initialisation des services
├── core/
│   ├── constants/
│   │   └── app_constants.dart              # Constantes de l'application
│   ├── navigation/
│   │   └── app_router.dart                 # Système de routage et garde d'accès admin
│   ├── theme/
│   │   ├── app_colors.dart                 # Palette StepQuest (#3B82F6, #0F2A47, #10B981, etc.)
│   │   ├── app_text_styles.dart            # Typographie Inter
│   │   └── app_theme.dart                  # Thèmes Material 3 clair et sombre
│   └── utils/
│       └── date_formatter.dart             # Formatage de dates en français
├── data/
│   ├── mock_notifications.dart             # Jeu initial de notifications
│   └── mock_users.dart                     # Jeu initial d'utilisateurs réalistes
├── models/
│   ├── app_user.dart                       # Modèle centralisé AppUser, UserRole, UserStatus
│   └── user_notification.dart              # Modèle de notification
├── services/
│   └── mock_biometric_service.dart         # Service biométrique simulé (Hardware & Sensors)
├── state/
│   ├── app_settings_state.dart             # Préférences (mode sombre, unités, notifications)
│   ├── app_state_provider.dart             # InheritedWidget et extensions context.*
│   ├── auth_state.dart                     # Gestion des sessions, connexion, inscription
│   ├── notification_state.dart             # Gestion des notifications dynamiques
│   └── user_state.dart                     # CRUD en mémoire et statistiques globales
├── widgets/
│   ├── app_app_bar.dart                    # Barre d'en-tête standardisée
│   ├── app_bottom_navigation.dart          # Barres de navigation utilisateur et admin
│   ├── app_button.dart                     # Boutons primaire, secondaire, destructif, biométrique
│   ├── app_card.dart                       # Cartes stylisées avec bordures discrètes
│   ├── app_text_field.dart                 # Champs de saisie modernes avec icônes et validation
│   ├── confirmation_dialog.dart            # Dialogue modal de confirmation d'action (Écran 16)
│   ├── empty_state.dart                    # Vue état vide
│   ├── loading_view.dart                   # Indicateur de chargement stylisé
│   ├── metric_card.dart                    # Cartes métriques pour le Dashboard Admin
│   ├── role_badge.dart                     # Badge de rôle (Admin / Utilisateur)
│   ├── status_badge.dart                   # Badge de statut (● Actif / ● Suspendu)
│   ├── stepquest_logo.dart                 # Logo et emblème CustomPaint StepQuest
│   ├── user_activity_chart.dart            # Courbe d'activité mensuelle CustomPainter
│   └── user_avatar.dart                    # Avatar stylisé avec initiales et badge caméra
└── features/
    ├── admin/
    │   └── screens/
    │       ├── admin_dashboard_screen.dart # Écran 12
    │       ├── admin_login_screen.dart     # Écran 11
    │       ├── edit_user_admin_screen.dart # Écran 15
    │       ├── user_details_screen.dart    # Écran 14
    │       └── users_list_screen.dart      # Écran 13
    ├── shared/
    │   └── screens/
    │       ├── biometric_auth_screen.dart  # Écran 17
    │       └── notifications_screen.dart   # Écran 18
    └── user/
        └── screens/
            ├── account_settings_screen.dart# Écran 09
            ├── biometric_setup_screen.dart # Écran 05
            ├── delete_account_screen.dart  # Écran 10
            ├── edit_profile_screen.dart    # Écran 08
            ├── forgot_password_screen.dart # Écran 04
            ├── login_screen.dart           # Écran 02
            ├── register_screen.dart        # Écran 03
            ├── splash_screen.dart          # Écran 01
            ├── user_home_screen.dart       # Écran 06
            └── user_profile_screen.dart    # Écran 07
```

---

## 3. Comptes Fictifs de Démonstration

Des raccourcis sont disponibles directement sur les écrans de connexion pour remplir ces comptes en 1 clic :

| Rôle | Nom complet | Identifiant / E-mail | Mot de passe | Statut | Particularités |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Utilisateur** | Amine Ben Ali | `amine@example.com` | `password123` | **Actif** | Niveau 3, 170 cm, 65 kg, Empreinte & Visage activés |
| **Utilisateur** | Sara Meftah | `sara@example.com` | `password123` | **Actif** | Niveau 2, 165 cm, 58 kg |
| **Utilisateur** | Lina Khaled | `lina@example.com` | `password123` | **Suspendu** | Permet de tester le blocage automatique à la connexion |
| **Utilisateur** | Omar Saidi | `omar@example.com` | `password123` | **Actif** | Niveau 4, 175 cm, 72 kg |
| **Admin** | Admin Principal | `admin@stepquest.com` | `admin123` | **Actif** | Super-administrateur avec accès complet au Dashboard |
| **Admin** | Youssef Trabelsi | `youssef@stepquest.com` | `admin123` | **Actif** | Administrateur opérationnel |

---

## 4. Tests et Vérifications Exécutés

### Analyse statique (`flutter analyze`) :
```text
Analyzing stepquest...
No issues found! (ran in 2.4s)
```
> **Résultat :** Zéro erreur, zéro avertissement.

### Tests Unitaires & Tests d'Intégration Widgets (`flutter test`) :
```text
00:03 +11: All tests passed!
```
* Validation du peuplement initial des utilisateurs de test.
* Validation de la recherche et du filtrage par statut et rôle.
* Validation de la création d'un utilisateur (*Create*).
* Validation de la mise à jour des informations de profil (*Update*).
* Validation de la suspension et de la réactivation de compte.
* Validation de la sécurité interdisant de supprimer le dernier administrateur.
* Validation de la connexion utilisateur standard.
* Validation du refus de connexion d'un compte suspendu.
* Validation de la vérification des privilèges administrateur (refus des utilisateurs simples dans l'espace admin).
* Validation du cycle d'inscription et de notification.
* *Smoke test* de lancement et navigation depuis le Splash Screen.

---

## 5. Commandes pour Lancer le Projet

```powershell
# 1. Vérification de l'analyse statique
flutter analyze

# 2. Lancement des tests unitaires et widgets
flutter test

# 3. Exécution de l'application sur le navigateur Edge ou Chrome
flutter run -d edge
# ou
flutter run -d chrome

# 4. Exécution sur l'environnement Windows Desktop
flutter run -d windows
```

---

## 6. Points Préparés pour la Phase Backend Ultérieure

L'architecture a été conçue pour faciliter le passage à un backend (Supabase, Firebase ou API REST) sans modifier les écrans :

* **Méthodes asynchrones :** Les méthodes de `MockAuthService` et `UserState` sont déjà asynchrones (`Future<bool>`), simulant les délais et les contrats d'API distants.
* **Sérialisation prête à l'emploi :** Le modèle `AppUser` dispose déjà des méthodes `toMap()` et `fromMap()` pour la sérialisation JSON / BDD.
* **Séparation stricte UI / Business Logic :** Les interfaces séparent rigoureusement la présentation visuelle de la manipulation de données via les `StateNotifier` et `InheritedWidget`.
