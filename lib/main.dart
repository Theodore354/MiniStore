import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:mini_store/core/constants.dart';
import 'package:mini_store/core/network_info.dart';
import 'package:mini_store/data/datasources/api_service.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/data/repositories/product_repository_impl.dart';
import 'package:mini_store/presentation/providers/product_provider.dart';
import 'package:mini_store/presentation/providers/cart_provider.dart';
import 'package:mini_store/presentation/providers/connectivity_provider.dart';
import 'package:mini_store/presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  final metadataBox = await Hive.openBox(AppConstants.metadataBoxName);
  final productsBox = await Hive.openBox(AppConstants.productsBoxName);
  final cartBox = await Hive.openBox(AppConstants.cartBoxName);

  // Wire up dependencies
  final apiService = ApiService();
  final localDataSource = LocalDataSource(
    metadataBox: metadataBox,
    productsBox: productsBox,
    cartBox: cartBox,
  );
  final networkInfo = NetworkInfoImpl(Connectivity());
  final productRepository = ProductRepositoryImpl(
    apiService: apiService,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  );

  runApp(MiniStoreApp(
    productRepository: productRepository,
    localDataSource: localDataSource,
    networkInfo: networkInfo,
  ));
}

class MiniStoreApp extends StatelessWidget {
  final ProductRepositoryImpl productRepository;
  final LocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  const MiniStoreApp({
    super.key,
    required this.productRepository,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProductProvider(repository: productRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => CartProvider(localDataSource: localDataSource),
        ),
        ChangeNotifierProxyProvider<ProductProvider, ConnectivityProvider>(
          create: (context) => ConnectivityProvider(
            networkInfo: networkInfo,
            onConnectivityRestored: () {
              context.read<ProductProvider>().onConnectivityRestored();
            },
          ),
          update: (context, productProvider, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'MiniStore',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const HomePage(),
      ),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
