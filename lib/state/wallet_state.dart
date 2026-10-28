import 'package:flutter/foundation.dart';

/// Manages the user's StepQuest Coin balance and transactions
class WalletState extends ChangeNotifier {
  int _balance;

  WalletState({int initialBalance = 1250}) : _balance = initialBalance;

  int get balance => _balance;

  /// Compatibility getter
  int getBalance() => _balance;

  /// Checks if the wallet has sufficient coins for a specified price
  bool canAfford(int price) {
    if (price <= 0) return true;
    return _balance >= price;
  }

  /// Adds coins to the balance (e.g. earned from walking or quest rewards)
  void addCoins(int amount) {
    if (amount <= 0) return;
    _balance += amount;
    notifyListeners();
  }

  /// Deducts coins. Never allows the balance to become negative.
  /// Returns true if deduction succeeded, false if insufficient balance.
  bool removeCoins(int amount) {
    if (amount <= 0) return true;
    if (_balance < amount) {
      return false;
    }
    _balance -= amount;
    notifyListeners();
    return true;
  }

  /// Resets or sets balance (useful for demo or user switching)
  void setBalance(int amount) {
    _balance = amount < 0 ? 0 : amount;
    notifyListeners();
  }
}
