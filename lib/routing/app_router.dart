import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pos/features/auth/presentation/screens/login_screen.dart';
import 'package:my_pos/features/auth/presentation/screens/pin_login_screen.dart';
import 'package:my_pos/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:my_pos/features/products/presentation/screens/product_list_screen.dart';
import 'package:my_pos/features/products/presentation/screens/category_management_screen.dart';
import 'package:my_pos/features/products/presentation/screens/add_edit_product_screen.dart';
import 'package:my_pos/features/pos/presentation/screens/pos_screen.dart';
import 'package:my_pos/features/transactions/presentation/screens/transaction_list_screen.dart';
import 'package:my_pos/features/transactions/presentation/screens/transaction_detail_screen.dart';
import 'package:my_pos/features/inventory/presentation/screens/inventory_screen.dart';
import 'package:my_pos/features/settings/presentation/screens/settings_screen.dart';
import 'package:my_pos/routing/shell_scaffold.dart';
import 'package:my_pos/routing/go_router_refresh_stream.dart';

class AppRouter {
  final AuthBloc authBloc;

  AppRouter(this.authBloc);

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggingIn = state.matchedLocation == '/login';

      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (authState is AuthUnauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (authState is AuthAuthenticated) {
        if (isLoggingIn) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      // ─── Login (no shell) ───
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'pin',
            builder: (context, state) => const PinLoginScreen(),
          ),
        ],
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
            routes: [
              GoRoute(
                path: 'categories',
                builder: (context, state) => const CategoryManagementScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/transactions',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TransactionListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => TransactionDetailScreen(
                  transactionId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/inventory',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: InventoryScreen(),
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
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        path: '/products/edit/:id',
        builder: (context, state) => AddEditProductScreen(
          productId: state.pathParameters['id'],
        ),
      ),
    ],
  );
}
