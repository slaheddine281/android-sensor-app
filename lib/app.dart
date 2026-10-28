import 'package:flutter/material.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/mock_biometric_service.dart';
import 'state/app_settings_state.dart';
import 'state/app_state_provider.dart';
import 'state/auth_state.dart';
import 'state/inventory_state.dart';
import 'state/marketplace_state.dart';
import 'state/notification_state.dart';
import 'state/user_state.dart';
import 'state/wallet_state.dart';

class StepQuestApp extends StatefulWidget {
  const StepQuestApp({super.key});

  @override
  State<StepQuestApp> createState() => _StepQuestAppState();
}

class _StepQuestAppState extends State<StepQuestApp> {
  late final AuthState _authState;
  late final UserState _userState;
  late final NotificationState _notificationState;
  late final AppSettingsState _settingsState;
  late final MockBiometricService _biometricService;
  late final MarketplaceState _marketplaceState;
  late final WalletState _walletState;
  late final InventoryState _inventoryState;

  @override
  void initState() {
    super.initState();
    _authState = AuthState();
    _userState = UserState();
    _notificationState = NotificationState();
    _settingsState = AppSettingsState();
    _biometricService = MockBiometricService();
    _marketplaceState = MarketplaceState();
    _walletState = WalletState(initialBalance: 1250);
    _inventoryState = InventoryState();
  }

  @override
  void dispose() {
    _authState.dispose();
    _userState.dispose();
    _notificationState.dispose();
    _settingsState.dispose();
    _marketplaceState.dispose();
    _walletState.dispose();
    _inventoryState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateProvider(
      authState: _authState,
      userState: _userState,
      notificationState: _notificationState,
      settingsState: _settingsState,
      biometricService: _biometricService,
      marketplaceState: _marketplaceState,
      walletState: _walletState,
      inventoryState: _inventoryState,
      child: ListenableBuilder(
        listenable: Listenable.merge([
          _authState,
          _userState,
          _notificationState,
          _settingsState,
          _marketplaceState,
          _walletState,
          _inventoryState,
        ]),
        builder: (context, _) {
          return MaterialApp(
            title: 'StepQuest',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _settingsState.themeMode,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) =>
                AppRoutes.onGenerateRoute(settings, _authState),
          );
        },
      ),
    );
  }
}
