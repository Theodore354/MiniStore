import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/presentation/providers/product_provider.dart';
import 'package:mini_store/domain/repositories/product_repository.dart';

class FakeProductRepository implements ProductRepository {
  final List<Product> _products;

  FakeProductRepository(this._products);

  @override
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    return _products;
  }

  @override
  Future<List<String>> getCategories({bool forceRefresh = false}) async {
    return _products.map((p) => p.category).toSet().toList();
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    return _products.where((p) => p.category == category).toList();
  }

  @override
  Future<bool> hasCachedProducts() async => _products.isNotEmpty;
}

Product makeProduct(int id) => Product(
  id: id,
  title: 'Product $id',
  price: id.toDouble(),
  description: 'Description $id',
  category: (id % 2 == 0) ? 'even' : 'odd',
  image: 'https://example.com/$id.png',
  rating: Rating(rate: 4.0, count: 1),
);

void main() {
  test('ProductProvider paginates and loads more correctly', () async {
    final products = List<Product>.generate(25, (i) => makeProduct(i + 1));
    final repo = FakeProductRepository(products);
    final provider = ProductProvider(repository: repo);

    // initial load
    await provider.loadProducts();
    expect(provider.products.length, 10);
    expect(provider.hasMore, true);

    // load next page
    await provider.loadMore();
    expect(provider.products.length, 20);
    expect(provider.hasMore, true);

    // load last page
    await provider.loadMore();
    expect(provider.products.length, 25);
    expect(provider.hasMore, false);
  });
}
