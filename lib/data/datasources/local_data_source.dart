import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:mini_store/core/constants.dart';
import 'package:mini_store/core/exceptions.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/data/models/cart_item_model.dart';

/// Local data source backed by Hive for caching products, categories, and cart.
class LocalDataSource {
  final Box _metadataBox;
  final Box _productsBox;
  final Box _cartBox;

  LocalDataSource({
    required Box metadataBox,
    required Box productsBox,
    required Box cartBox,
  })  : _metadataBox = metadataBox,
        _productsBox = productsBox,
        _cartBox = cartBox;

  // ─── Products ──────────────────────────────────────────────

  /// Caches a list of products as a JSON string and stores the timestamp.
  Future<void> cacheProducts(List<ProductModel> products) async {
    try {
      final jsonString = ProductModel.encodeList(products);
      await _productsBox.put(AppConstants.productsCacheKey, jsonString);
      await _metadataBox.put(
        AppConstants.productsTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache products: $e');
    }
  }

  /// Retrieves cached products. Returns empty list if no cache exists.
  List<ProductModel> getCachedProducts() {
    try {
      final jsonString = _productsBox.get(AppConstants.productsCacheKey);
      if (jsonString == null) return [];
      return ProductModel.decodeList(jsonString as String);
    } catch (e) {
      // Corrupted cache — clear it and return empty
      _productsBox.delete(AppConstants.productsCacheKey);
      _metadataBox.delete(AppConstants.productsTimestampKey);
      return [];
    }
  }

  /// Returns true if products cache exists and has not expired.
  bool isProductsCacheValid() {
    try {
      final timestampStr =
          _metadataBox.get(AppConstants.productsTimestampKey) as String?;
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      return age < AppConstants.cacheMaxAge;
    } catch (e) {
      return false;
    }
  }

  /// Returns true if any cached products exist (regardless of expiry).
  bool hasCachedProducts() {
    return _productsBox.containsKey(AppConstants.productsCacheKey);
  }

  // ─── Categories ────────────────────────────────────────────

  /// Caches a list of category strings.
  Future<void> cacheCategories(List<String> categories) async {
    try {
      final jsonString = jsonEncode(categories);
      await _productsBox.put(AppConstants.categoriesCacheKey, jsonString);
      await _metadataBox.put(
        AppConstants.categoriesTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      throw CacheException(message: 'Failed to cache categories: $e');
    }
  }

  /// Retrieves cached categories. Returns empty list if none cached.
  List<String> getCachedCategories() {
    try {
      final jsonString = _productsBox.get(AppConstants.categoriesCacheKey);
      if (jsonString == null) return [];
      final List<dynamic> decoded = jsonDecode(jsonString as String) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      _productsBox.delete(AppConstants.categoriesCacheKey);
      return [];
    }
  }

  /// Returns true if categories cache exists and has not expired.
  bool isCategoriesCacheValid() {
    try {
      final timestampStr =
          _metadataBox.get(AppConstants.categoriesTimestampKey) as String?;
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      return age < AppConstants.cacheMaxAge;
    } catch (e) {
      return false;
    }
  }

  // ─── Cart ──────────────────────────────────────────────────

  /// Persists the cart items to Hive.
  Future<void> saveCart(List<CartItemModel> items) async {
    try {
      final jsonString = CartItemModel.encodeList(items);
      await _cartBox.put(AppConstants.cartCacheKey, jsonString);
    } catch (e) {
      throw CacheException(message: 'Failed to save cart: $e');
    }
  }

  /// Retrieves persisted cart items. Returns empty list if none saved.
  List<CartItemModel> getCart() {
    try {
      final jsonString = _cartBox.get(AppConstants.cartCacheKey);
      if (jsonString == null) return [];
      return CartItemModel.decodeList(jsonString as String);
    } catch (e) {
      // Corrupted cart cache — clear it
      _cartBox.delete(AppConstants.cartCacheKey);
      return [];
    }
  }

  // ─── Cleanup ───────────────────────────────────────────────

  /// Clears all cached data. Used when cache is detected as corrupted.
  Future<void> clearAll() async {
    await _productsBox.clear();
    await _cartBox.clear();
    await _metadataBox.clear();
  }
}
