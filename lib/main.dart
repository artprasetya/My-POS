import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_pos/core/config/flavor_config.dart';
import 'package:my_pos/core/theme/app_theme.dart';
import 'package:my_pos/features/auth/data/repositories/auth_repository.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/products/data/repositories/product_repository.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:my_pos/routing/app_router.dart';
import 'package:my_pos/services/supabase_service.dart';

/// Shared app bootstrap — called by main_staging.dart and main_production.dart.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set the active flavor
  FlavorConfig.initialize(flavor);

  // Load the correct .env file
  await dotenv.load(fileName: FlavorConfig.envFileName);

  // Initialize Supabase with flavor-specific credentials
  await SupabaseService.initialize();

  runApp(const MyPosApp());
}

class MyPosApp extends StatelessWidget {
  const MyPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final productRepository = ProductRepository();
    final transactionRepository = TransactionRepository();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authRepository),
        RepositoryProvider.value(value: productRepository),
        RepositoryProvider.value(value: transactionRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => AuthBloc(repository: authRepository)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(create: (_) => ProductBloc(repository: productRepository)),
          BlocProvider(create: (_) => CartBloc()),
          BlocProvider(
            create: (_) => TransactionBloc(repository: transactionRepository),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(repository: transactionRepository),
          ),
        ],
        child: MaterialApp.router(
          title: 'My POS${FlavorConfig.isStaging ? ' (Staging)' : ''}',
          debugShowCheckedModeBanner: FlavorConfig.isStaging,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
