import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/features/auth/presentation/screens/login_screen.dart';
import 'package:my_pos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:my_pos/features/products/presentation/screens/product_list_screen.dart';
import 'package:my_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:my_pos/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:my_pos/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_pos/routing/shell_scaffold.dart';

class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    routes: [
      // ─── Login (no shell) ───
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ─── Main Shell ───
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/pos',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PosScreen(),
            ),
          ),
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductListScreen(),
            ),
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionListScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // ─── Standalone routes (outside shell) ───
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Add Product — Coming in Phase 3')),
        ),
      ),
      GoRoute(
        path: '/products/edit/:id',
        builder: (context, state) => Scaffold(
          body: Center(
            child: Text('Edit Product ${state.pathParameters['id']} — Coming in Phase 3'),
          ),
        ),
      ),
    ],
  );
}
