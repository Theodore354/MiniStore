import 'package:mini_store/domain/entities/product.dart';

/// Abstract repository contract for product data operations.
///
/// This interface defines the contract that the data layer must implement,
/// keeping the domain layer independent of data source details.
abstract class ProductRepository {
  /// Fetches all products. Returns cached data first if available,
  /// then refreshes from network if cache is expired.
  Future<List<Product>> getProducts({bool forceRefresh = false});

  /// Fetches all product categories.
  Future<List<String>> getCategories({bool forceRefresh = false});

  /// Fetches products filtered by [category].
  Future<List<Product>> getProductsByCategory(String category);

  /// Returns true if cached product data is available (for offline use).
  Future<bool> hasCachedProducts();
}
