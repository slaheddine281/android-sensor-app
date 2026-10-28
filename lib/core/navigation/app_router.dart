import 'package:flutter/material.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/edit_user_admin_screen.dart';
import '../../features/admin/screens/user_details_screen.dart';
import '../../features/admin/screens/users_list_screen.dart';
import '../../features/marketplace/screens/character_customization_screen.dart';
import '../../features/marketplace/screens/daily_shop_screen.dart';
import '../../features/marketplace/screens/inventory_screen.dart';
import '../../features/marketplace/screens/marketplace_category_screen.dart';
import '../../features/marketplace/screens/marketplace_home_screen.dart';
import '../../features/marketplace/screens/product_details_screen.dart';
import '../../features/marketplace/screens/purchase_success_screen.dart';
import '../../features/marketplace/screens/wishlist_screen.dart';
import '../../features/shared/screens/biometric_auth_screen.dart';
import '../../features/shared/screens/notifications_screen.dart';
import '../../features/user/screens/account_settings_screen.dart';
import '../../features/user/screens/biometric_setup_screen.dart';
import '../../features/user/screens/delete_account_screen.dart';
import '../../features/user/screens/edit_profile_screen.dart';
import '../../features/user/screens/forgot_password_screen.dart';
import '../../features/user/screens/login_screen.dart';
import '../../features/user/screens/register_screen.dart';
import '../../features/user/screens/splash_screen.dart';
import '../../features/user/screens/user_home_screen.dart';
import '../../features/user/screens/user_profile_screen.dart';
import '../../models/marketplace_product.dart';
import '../../models/product_category.dart';
import '../../services/mock_biometric_service.dart';
import '../../state/auth_state.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String biometricSetup = '/biometric-setup';
  static const String userHome = '/user-home';
  static const String userProfile = '/user-profile';
  static const String editProfile = '/edit-profile';
  static const String accountSettings = '/account-settings';
  static const String deleteAccount = '/delete-account';

  // Admin routes
  static const String adminLogin = '/admin-login';
  static const String adminDashboard = '/admin-dashboard';
  static const String adminUsers = '/admin-users';
  static const String adminUserDetails = '/admin-user-details';
  static const String adminEditUser = '/admin-edit-user';

  // Shared
  static const String biometricAuth = '/biometric-auth';
  static const String notifications = '/notifications';

  // Marketplace RPG routes
  static const String storeHome = '/store';
  static const String storeCategory = '/store/category';
  static const String storeProductDetails = '/store/product-details';
  static const String storeDailyShop = '/store/daily';
  static const String storeWishlist = '/store/wishlist';
  static const String inventory = '/inventory';
  static const String characterCustomization = '/character-customization';
  static const String storePurchaseSuccess = '/store/purchase-success';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AuthState authState,
  ) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case forgotPassword:
        return MaterialPageRoute(
            builder: (_) => const ForgotPasswordScreen());

      case biometricSetup:
        return MaterialPageRoute(
            builder: (_) => const BiometricSetupScreen());

      case userHome:
        return MaterialPageRoute(builder: (_) => const UserHomeScreen());

      case userProfile:
        return MaterialPageRoute(builder: (_) => const UserProfileScreen());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfileScreen());

      case accountSettings:
        return MaterialPageRoute(
            builder: (_) => const AccountSettingsScreen());

      case deleteAccount:
        return MaterialPageRoute(builder: (_) => const DeleteAccountScreen());

      // Admin Area with simulated Role Guard
      case adminLogin:
        return MaterialPageRoute(builder: (_) => const AdminLoginScreen());

      case adminDashboard:
        if (!authState.isAdmin) {
          return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
        }
        return MaterialPageRoute(
            builder: (_) => const AdminDashboardScreen());

      case adminUsers:
        if (!authState.isAdmin) {
          return MaterialPageRoute(builder: (_) => const AdminLoginScreen());
        }
        return MaterialPageRoute(builder: (_) => const UsersListScreen());

      case adminUserDetails:
        final userId = settings.arguments as String?;
        if (userId == null) {
          return MaterialPageRoute(builder: (_) => const UsersListScreen());
        }
        return MaterialPageRoute(
          builder: (_) => UserDetailsScreen(userId: userId),
        );

      case adminEditUser:
        final userId = settings.arguments as String?;
        if (userId == null) {
          return MaterialPageRoute(builder: (_) => const UsersListScreen());
        }
        return MaterialPageRoute(
          builder: (_) => EditUserAdminScreen(userId: userId),
        );

      case biometricAuth:
        final type = (settings.arguments as BiometricType?) ??
            BiometricType.fingerprint;
        return MaterialPageRoute(
          builder: (_) => BiometricAuthScreen(type: type),
        );

      case notifications:
        return MaterialPageRoute(
            builder: (_) => const NotificationsScreen());

      // Marketplace routes
      case storeHome:
        return MaterialPageRoute(
            builder: (_) => const MarketplaceHomeScreen());

      case storeCategory:
        final cat = (settings.arguments as ProductCategory?) ??
            ProductCategory.outfits;
        return MaterialPageRoute(
          builder: (_) => MarketplaceCategoryScreen(category: cat),
        );

      case storeProductDetails:
        final prod = settings.arguments as MarketplaceProduct?;
        if (prod == null) {
          return MaterialPageRoute(
              builder: (_) => const MarketplaceHomeScreen());
        }
        return MaterialPageRoute(
          builder: (_) => ProductDetailsScreen(product: prod),
        );

      case storeDailyShop:
        return MaterialPageRoute(builder: (_) => const DailyShopScreen());

      case storeWishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());

      case inventory:
        return MaterialPageRoute(builder: (_) => const InventoryScreen());

      case characterCustomization:
        return MaterialPageRoute(
            builder: (_) => const CharacterCustomizationScreen());

      case storePurchaseSuccess:
        final prod = settings.arguments as MarketplaceProduct?;
        if (prod == null) {
          return MaterialPageRoute(
              builder: (_) => const MarketplaceHomeScreen());
        }
        return MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(product: prod),
        );

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
