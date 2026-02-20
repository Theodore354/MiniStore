import 'package:mini_store/core/exceptions.dart';
import 'package:mini_store/core/network_info.dart';
import 'package:mini_store/data/datasources/api_service.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/domain/repositories/product_repository.dart';

/// Concrete implementation of [ProductRepository] with offline-first strategy.
///
/// Strategy:
/// 1. Always return cached data immediately if available
/// 2. If online and cache expired → fetch from API, update cache
/// 3. If offline → return cached data (stale is better than nothing)
/// 4. If no cache and offline → throw meaningful error
class ProductRepositoryImpl implements ProductRepository {
  final ApiService _apiService;
  final LocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  ProductRepositoryImpl({
    required ApiService apiService,
    required LocalDataSource localDataSource,
    required NetworkInfo networkInfo,
  })  : _apiService = apiService,
        _localDataSource = localDataSource,
        _networkInfo = networkInfo;

  @override
  Future<List<Product>> getProducts({bool forceRefresh = false}) async {
    // 1. Try to get cached data first
    final cachedProducts = _localDataSource.getCachedProducts();
    final cacheValid = _localDataSource.isProductsCacheValid();

    // 2. If cache is valid and not forced refresh, return cached
    if (cachedProducts.isNotEmpty && cacheValid && !forceRefresh) {
      return cachedProducts;
    }

    // 3. Try to fetch from network
    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteProducts = await _apiService.getProducts();
        await _localDataSource.cacheProducts(remoteProducts);
        return remoteProducts;
      } on ServerException {
        // Server error — return cached if available
        if (cachedProducts.isNotEmpty) {
          return cachedProducts;
        }
        rethrow;
      }
    }

    // 4. Offline — return cache if available
    if (cachedProducts.isNotEmpty) {
      return cachedProducts;
    }

    // 5. No cache, no network — throw error
    throw const NetworkException(
      message: 'No internet connection and no cached data available',
    );
  }

  @override
  Future<List<String>> getCategories({bool forceRefresh = false}) async {
    final cachedCategories = _localDataSource.getCachedCategories();
    final cacheValid = _localDataSource.isCategoriesCacheValid();

    if (cachedCategories.isNotEmpty && cacheValid && !forceRefresh) {
      return cachedCategories;
    }

    final isConnected = await _networkInfo.isConnected;
    if (isConnected) {
      try {
        final remoteCategories = await _apiService.getCategories();
        await _localDataSource.cacheCategories(remoteCategories);
        return remoteCategories;
      } on ServerException {
        if (cachedCategories.isNotEmpty) {
          return cachedCategories;
        }
        rethrow;
      }
    }

    if (cachedCategories.isNotEmpty) {
      return cachedCategories;
    }

    throw const NetworkException(
      message: 'No internet connection and no cached categories available',
    );
  }

  @override
  Future<List<Product>> getProductsByCategory(String category) async {
    // Filter from the full product list (already cached)
    final allProducts = await getProducts();
    return allProducts
        .where((p) => p.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  @override
  Future<bool> hasCachedProducts() async {
    return _localDataSource.hasCachedProducts();
  }
}
