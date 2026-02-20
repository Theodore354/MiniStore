import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/core/exceptions.dart';
import 'package:mini_store/core/network_info.dart';
import 'package:mini_store/data/datasources/api_service.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/data/repositories/product_repository_impl.dart';

// ─── Simple test doubles (no mockito codegen needed) ─────────

class FakeApiService extends ApiService {
  List<ProductModel>? productsToReturn;
  List<String>? categoriesToReturn;
  Exception? exceptionToThrow;

  FakeApiService() : super();

  @override
  Future<List<ProductModel>> getProducts() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return productsToReturn ?? [];
  }

  @override
  Future<List<String>> getCategories() async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return categoriesToReturn ?? [];
  }

  @override
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return (productsToReturn ?? [])
        .where((p) => p.category == category)
        .toList();
  }
}

class FakeLocalDataSource implements LocalDataSource {
  List<ProductModel> _cachedProducts = [];
  List<String> _cachedCategories = [];
  bool _productsCacheValid = false;
  bool _categoriesCacheValid = false;

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    _cachedProducts = products;
    _productsCacheValid = true;
  }

  @override
  List<ProductModel> getCachedProducts() => _cachedProducts;

  @override
  bool isProductsCacheValid() => _productsCacheValid;

  @override
  bool hasCachedProducts() => _cachedProducts.isNotEmpty;

  @override
  Future<void> cacheCategories(List<String> categories) async {
    _cachedCategories = categories;
    _categoriesCacheValid = true;
  }

  @override
  List<String> getCachedCategories() => _cachedCategories;

  @override
  bool isCategoriesCacheValid() => _categoriesCacheValid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeNetworkInfo implements NetworkInfo {
  bool isConnectedValue = true;

  @override
  Future<bool> get isConnected async => isConnectedValue;

  @override
  Stream<bool> get onConnectivityChanged => const Stream.empty();
}

// ─── Test data ───────────────────────────────────────────────

final testProducts = [
  const ProductModel(
    id: 1,
    title: 'Test Product 1',
    price: 29.99,
    description: 'Description 1',
    category: 'electronics',
    image: 'https://example.com/img1.jpg',
    rating: RatingModel(rate: 4.5, count: 100),
  ),
  const ProductModel(
    id: 2,
    title: 'Test Product 2',
    price: 49.99,
    description: 'Description 2',
    category: "men's clothing",
    image: 'https://example.com/img2.jpg',
    rating: RatingModel(rate: 3.8, count: 50),
  ),
];

// ─── Tests ───────────────────────────────────────────────────

void main() {
  late FakeApiService fakeApi;
  late FakeLocalDataSource fakeLocal;
  late FakeNetworkInfo fakeNetwork;
  late ProductRepositoryImpl repository;

  setUp(() {
    fakeApi = FakeApiService();
    fakeLocal = FakeLocalDataSource();
    fakeNetwork = FakeNetworkInfo();
    repository = ProductRepositoryImpl(
      apiService: fakeApi,
      localDataSource: fakeLocal,
      networkInfo: fakeNetwork,
    );
  });

  group('ProductRepository.getProducts', () {
    test('returns cached data when cache is valid and not force-refreshing',
        () async {
      // Arrange: cache is valid with products
      await fakeLocal.cacheProducts(testProducts);

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result, equals(testProducts));
      expect(result.length, 2);
    });

    test('fetches from API when cache is expired and online', () async {
      // Arrange: cache is expired, API has data
      fakeNetwork.isConnectedValue = true;
      fakeApi.productsToReturn = testProducts;

      // Act
      final result = await repository.getProducts();

      // Assert
      expect(result, equals(testProducts));
      // Verify data was cached
      expect(fakeLocal.getCachedProducts(), equals(testProducts));
    });

    test(
        'returns cached data when offline even if cache is expired (stale data)',
        () async {
      // Arrange: cache has data but is "expired" (we set valid=false),
      // but since our fake starts with valid=false, we need to manually add products
      fakeLocal._cachedProducts = testProducts;
      fakeLocal._productsCacheValid = false;
      fakeNetwork.isConnectedValue = false;

      // Act
      final result = await repository.getProducts();

      // Assert: should return stale cached data rather than throwing
      expect(result, equals(testProducts));
    });

    test('throws NetworkException when offline with no cached data', () async {
      // Arrange: no cache, no network
      fakeNetwork.isConnectedValue = false;

      // Act & Assert
      expect(
        () => repository.getProducts(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('returns cached data when API throws server error', () async {
      // Arrange: cache has data, API fails
      await fakeLocal.cacheProducts(testProducts);
      fakeLocal._productsCacheValid = false; // Force API call attempt
      fakeNetwork.isConnectedValue = true;
      fakeApi.exceptionToThrow =
          const ServerException(message: 'Internal Server Error', statusCode: 500);

      // Act
      final result = await repository.getProducts();

      // Assert: fallback to cached data
      expect(result, equals(testProducts));
    });
  });
}
