import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/core/constants.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/presentation/providers/product_provider.dart';
import 'package:mini_store/domain/repositories/product_repository.dart';

// ─── Fake repository ─────────────────────────────────────────

class FakeProductRepository implements ProductRepository {
  List<Product> products = [];
  List<String> categories = [];

  @override
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    return products;
  }

  @override
  Future<List<String>> getCategories({bool forceRefresh = false}) async {
    return categories;
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    return products.where((p) => p.category == category).toList();
  }

  @override
  Future<bool> hasCachedProducts() async => products.isNotEmpty;
}

// ─── Test data ───────────────────────────────────────────────

List<ProductModel> generateProducts(int count) {
  return List.generate(
    count,
    (i) => ProductModel(
      id: i + 1,
      title: 'Product ${i + 1}',
      price: (i + 1) * 10.0,
      description: 'Description ${i + 1}',
      category: i % 2 == 0 ? 'electronics' : "men's clothing",
      image: 'https://example.com/img${i + 1}.jpg',
      rating: const RatingModel(rate: 4.0, count: 100),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────

void main() {
  late FakeProductRepository fakeRepository;
  late ProductProvider provider;

  setUp(() {
    fakeRepository = FakeProductRepository();
    provider = ProductProvider(repository: fakeRepository);
  });

  group('Pagination', () {
    test('first load returns exactly pageSize items', () async {
      // Arrange: 15 products
      fakeRepository.products = generateProducts(15);

      // Act
      await provider.loadProducts();

      // Assert
      expect(provider.products.length, AppConstants.pageSize);
      expect(provider.hasMore, isTrue);
    });

    test('loadMore adds next page of items', () async {
      // Arrange: 15 products, pageSize = 6
      fakeRepository.products = generateProducts(15);

      // Act
      await provider.loadProducts(); // page 0: items 1-6
      await provider.loadMore(); // page 1: items 7-12

      // Assert
      final expected =
          fakeRepository.products.length < AppConstants.pageSize * 2
          ? fakeRepository.products.length
          : AppConstants.pageSize * 2;
      expect(provider.products.length, expected);
      final expectedHasMore =
          fakeRepository.products.length > AppConstants.pageSize * 2;
      expect(provider.hasMore, expectedHasMore);
    });

    test('hasMore is false after all items are loaded', () async {
      // Arrange: exactly pageSize items
      fakeRepository.products = generateProducts(AppConstants.pageSize);

      // Act
      await provider.loadProducts();

      // Assert
      expect(provider.products.length, AppConstants.pageSize);
      expect(provider.hasMore, isFalse);
    });

    test('loading all pages gives all items', () async {
      // Arrange: 15 products
      fakeRepository.products = generateProducts(15);

      // Act: load all pages
      await provider.loadProducts(); // 6
      await provider.loadMore(); // 12
      await provider.loadMore(); // 15

      // Assert
      expect(provider.products.length, 15);
      expect(provider.hasMore, isFalse);
    });

    test('empty product list results in no items and no more pages', () async {
      fakeRepository.products = [];

      await provider.loadProducts();

      expect(provider.products.isEmpty, isTrue);
      expect(provider.hasMore, isFalse);
    });
  });

  group('Search & Category Filtering', () {
    test('setCategory filters products and resets pagination', () async {
      fakeRepository.products = generateProducts(10);
      await provider.loadProducts();

      provider.setCategory('electronics');

      // Should only show electronics (even indexed = 0,2,4,6,8 → ids 1,3,5,7,9)
      expect(
        provider.products.every((p) => p.category == 'electronics'),
        isTrue,
      );
    });

    test('setSearchQuery filters by title', () async {
      fakeRepository.products = generateProducts(10);
      await provider.loadProducts();

      provider.setSearchQuery('Product 1');

      // Should match "Product 1" and "Product 10"
      expect(
        provider.products.every(
          (p) => p.title.toLowerCase().contains('product 1'),
        ),
        isTrue,
      );
    });

    test('search and category work together', () async {
      fakeRepository.products = generateProducts(20);
      await provider.loadProducts();

      provider.setCategory('electronics');
      provider.setSearchQuery('Product 1');

      // Must be electronics AND contain "Product 1"
      for (final p in provider.products) {
        expect(p.category, 'electronics');
        expect(p.title.toLowerCase().contains('product 1'), isTrue);
      }
    });

    test('switching category preserves search query', () async {
      fakeRepository.products = generateProducts(10);
      await provider.loadProducts();

      provider.setSearchQuery('Product');
      provider.setCategory('electronics');

      // Search query should still be active
      expect(provider.searchQuery, 'Product');
    });
  });
}
