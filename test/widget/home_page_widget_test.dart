import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mini_store/presentation/pages/home_page.dart';
import 'package:mini_store/presentation/providers/product_provider.dart';
import 'package:mini_store/presentation/providers/cart_provider.dart';
import 'package:mini_store/presentation/providers/connectivity_provider.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/domain/repositories/product_repository.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/data/models/cart_item_model.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/core/network_info.dart';

class FakeProductRepository implements ProductRepository {
  final List<Product> _products;
  FakeProductRepository(this._products);
  @override
  Future<List<Product>> getProducts({bool forceRefresh = false}) async =>
      _products;
  @override
  Future<List<String>> getCategories({bool forceRefresh = false}) async =>
      _products.map((p) => p.category).toSet().toList();
  @override
  Future<List<Product>> getProductsByCategory(String category) async =>
      _products.where((p) => p.category == category).toList();
  @override
  Future<bool> hasCachedProducts() async => _products.isNotEmpty;
}

class FakeLocalDataSourceForCart implements LocalDataSource {
  @override
  Future<void> saveCart(List<CartItemModel> items) async {}
  @override
  List<CartItemModel> getCart() => [];
  // The rest are unused for this test; implement no-op / throw if called
  @override
  Future<void> cacheCategories(List<String> categories) async =>
      throw UnimplementedError();
  @override
  Future<void> cacheProducts(List<ProductModel> products) async =>
      throw UnimplementedError();
  @override
  List<String> getCachedCategories() => throw UnimplementedError();
  @override
  List<ProductModel> getCachedProducts() => throw UnimplementedError();
  @override
  bool hasCachedProducts() => false;
  @override
  bool isCategoriesCacheValid() => false;
  @override
  bool isProductsCacheValid() => false;
  @override
  Future<void> clearAll() => throw UnimplementedError();
}

// Minimal NetworkInfo fake for ConnectivityProvider
class FakeNetworkInfo implements NetworkInfo {
  @override
  Future<bool> get isConnected async => true;
  @override
  Stream<bool> get onConnectivityChanged => Stream<bool>.empty();
}

Product makeProduct(int id) => Product(
  id: id,
  title: 'Product $id',
  price: id.toDouble(),
  description: 'Description $id',
  category: 'cat',
  image: '',
  rating: Rating(rate: 4.0, count: 1),
);

void main() {
  testWidgets('HomePage shows products grid', (WidgetTester tester) async {
    final products = List<Product>.generate(8, (i) => makeProduct(i + 1));
    final repo = FakeProductRepository(products);
    final provider = ProductProvider(repository: repo);

    // Preload provider data so HomePage renders immediately
    await provider.loadProducts();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ProductProvider>.value(value: provider),
          ChangeNotifierProvider<CartProvider>(
            create: (_) =>
                CartProvider(localDataSource: FakeLocalDataSourceForCart()),
          ),
          ChangeNotifierProvider<ConnectivityProvider>(
            create: (_) => ConnectivityProvider(networkInfo: FakeNetworkInfo()),
          ),
        ],
        child: const MaterialApp(home: HomePage()),
      ),
    );

    await tester.pump();
    // Allow a small duration for provider notifications and rebuilds.
    await tester.pump(const Duration(milliseconds: 500));

    // Expect first product visible and grid present
    expect(find.text('Product 1'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);

    // Verify provider has the expected number of products and grid exists.
    expect(provider.products.length, 8);
  });
}
