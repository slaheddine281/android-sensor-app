import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavItem> items;
  final bool isDarkTheme;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.isDarkTheme = false,
  });

  // Pre-configured for User Space with integrated Marketplace
  static List<BottomNavItem> get userNavItems => const [
        BottomNavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
          label: 'Accueil',
        ),
        BottomNavItem(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront_rounded,
          label: 'Boutique',
        ),
        BottomNavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person_rounded,
          label: 'Profil',
        ),
        BottomNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          label: 'Paramètres',
        ),
      ];

  // Pre-configured for Admin Space
  static List<BottomNavItem> get adminNavItems => const [
        BottomNavItem(
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          label: 'Dashboard',
        ),
        BottomNavItem(
          icon: Icons.people_outline,
          activeIcon: Icons.people_rounded,
          label: 'Utilisateurs',
        ),
        BottomNavItem(
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          label: 'Paramètres',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final isDark =
        isDarkTheme || Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.navyCard : Colors.white;
    final border = isDark ? const Color(0xFF334155) : AppColors.divider;
    final activeColor = AppColors.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(color: border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = currentIndex == index;

              return InkWell(
                onTap: () => onTap(index),
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        size: 24,
                        color: isSelected ? activeColor : inactiveColor,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
