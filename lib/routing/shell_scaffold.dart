import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';

/// The main shell scaffold with bottom navigation bar.
/// This wraps all tabs (Dashboard, POS, Products, Transactions, Settings).
class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard_rounded, path: '/dashboard'),
    _Tab(label: 'POS', icon: Icons.point_of_sale_outlined, activeIcon: Icons.point_of_sale_rounded, path: '/pos'),
    _Tab(label: 'Products', icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2_rounded, path: '/products'),
    _Tab(label: 'Inventory', icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt_rounded, path: '/inventory'),
    _Tab(label: 'History', icon: Icons.receipt_long_outlined, activeIcon: Icons.receipt_long_rounded, path: '/transactions'),
    _Tab(label: 'Settings', icon: Icons.settings_outlined, activeIcon: Icons.settings_rounded, path: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.darkBorder : AppColors.lightGray,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: AppSizes.bottomNavHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _tabs.asMap().entries.map((entry) {
                final i = entry.key;
                final tab = entry.value;
                final isActive = i == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (i != index) context.go(tab.path);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppColors.primary.withValues(alpha: 0.12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusFull),
                          ),
                          child: Icon(
                            isActive ? tab.activeIcon : tab.icon,
                            size: 22,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.mediumGray),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.darkTextSecondary
                                    : AppColors.mediumGray),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;

  const _Tab({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
}
