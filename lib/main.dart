import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:my_pos/core/config/flavor_config.dart';
import 'package:my_pos/core/theme/app_theme.dart';
import 'package:my_pos/core/bloc/locale_bloc.dart';
import 'package:my_pos/features/auth/data/repositories/auth_repository.dart';
import 'package:my_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:my_pos/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:my_pos/features/pos/presentation/bloc/cart_bloc.dart';
import 'package:my_pos/features/products/data/repositories/product_repository.dart';
import 'package:my_pos/features/products/presentation/bloc/product_bloc.dart';
import 'package:my_pos/features/inventory/data/repositories/inventory_repository.dart';
import 'package:my_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:my_pos/features/transactions/data/repositories/transaction_repository.dart';
import 'package:my_pos/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:my_pos/l10n/app_localizations.dart';
import 'package:my_pos/routing/app_router.dart';
import 'package:my_pos/services/supabase_service.dart';

Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.initialize(flavor);
  await dotenv.load(fileName: FlavorConfig.envFileName);
  await SupabaseService.initialize();
  runApp(const MyPosApp());
}

class MyPosApp extends StatefulWidget {
  const MyPosApp({super.key});

  @override
  State<MyPosApp> createState() => _MyPosAppState();
}

class _MyPosAppState extends State<MyPosApp> {
  late final AuthRepository _authRepository;
  late final ProductRepository _productRepository;
  late final TransactionRepository _transactionRepository;
  late final InventoryRepository _inventoryRepository;

  AppRouter? _appRouter;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _productRepository = ProductRepository();
    _transactionRepository = TransactionRepository();
    _inventoryRepository = InventoryRepository();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: _authRepository),
        RepositoryProvider.value(value: _productRepository),
        RepositoryProvider.value(value: _transactionRepository),
        RepositoryProvider.value(value: _inventoryRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) => LocaleBloc()..add(LocaleLoadRequested()),
          ),
          BlocProvider(
            create: (_) => AuthBloc(repository: _authRepository)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
              create: (_) => ProductBloc(repository: _productRepository)),
          BlocProvider(create: (_) => CartBloc()),
          BlocProvider(
            create: (_) => TransactionBloc(repository: _transactionRepository),
          ),
          BlocProvider(
            create: (_) => DashboardBloc(repository: _transactionRepository),
          ),
          BlocProvider(
            create: (_) => InventoryBloc(repository: _inventoryRepository),
          ),
        ],
        child: BlocBuilder<LocaleBloc, LocaleState>(
          builder: (context, localeState) {
            return Builder(
              builder: (context) {
                _appRouter ??= AppRouter(context.read<AuthBloc>());

                return MaterialApp.router(
                  title: 'My POS${FlavorConfig.isStaging ? ' (Staging)' : ''}',
                  debugShowCheckedModeBanner: FlavorConfig.isStaging,
                  theme: AppTheme.lightTheme,
                  darkTheme: AppTheme.darkTheme,
                  themeMode: ThemeMode.light,
                  routerConfig: _appRouter!.router,
                  locale: localeState.locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
