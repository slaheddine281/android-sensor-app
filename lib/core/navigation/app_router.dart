import 'package:flutter/material.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_login_screen.dart';
import '../../features/admin/screens/edit_user_admin_screen.dart';
import '../../features/admin/screens/user_details_screen.dart';
import '../../features/admin/screens/users_list_screen.dart';
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

      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

