import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/core/constants/app_colors.dart';
import 'package:my_pos/core/constants/app_sizes.dart';
import 'package:my_pos/l10n/app_localizations.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;

  const ShellScaffold({super.key, required this.child});

  List<_Tab> _getTabs(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      _Tab(
          label: l10n.dashboard,
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          path: '/dashboard'),
      _Tab(
          label: l10n.pos,
          icon: Icons.point_of_sale_outlined,
          activeIcon: Icons.point_of_sale_rounded,
          path: '/pos'),
      _Tab(
          label: l10n.products,
          icon: Icons.inventory_2_outlined,
          activeIcon: Icons.inventory_2_rounded,
          path: '/products'),
      _Tab(
          label: l10n.inventory,
          icon: Icons.list_alt_outlined,
          activeIcon: Icons.list_alt_rounded,
          path: '/inventory'),
      _Tab(
          label: l10n.reports,
          icon: Icons.bar_chart_outlined,
          activeIcon: Icons.bar_chart_rounded,
          path: '/reports'),
      _Tab(
          label: l10n.settings,
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings_rounded,
          path: '/settings'),
    ];
  }

  int _currentIndex(BuildContext context, List<_Tab> tabs) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final tabs = _getTabs(context);
    final index = _currentIndex(context, tabs);
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
              children: tabs.asMap().entries.map((entry) {
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
                            borderRadius:
                                BorderRadius.circular(AppSizes.radiusFull),
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
