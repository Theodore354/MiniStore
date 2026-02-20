/// Application-wide constants.
class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = 'https://fakestoreapi.com';
  static const Duration apiTimeout = Duration(seconds: 10);

  // Pagination
  static const int pageSize = 10;

  // Cache
  static const String productsBoxName = 'products_box';
  static const String categoriesBoxName = 'categories_box';
  static const String cartBoxName = 'cart_box';
  static const String metadataBoxName = 'metadata_box';

  static const String productsCacheKey = 'cached_products';
  static const String categoriesCacheKey = 'cached_categories';
  static const String cartCacheKey = 'cached_cart';
  static const String productsTimestampKey = 'products_timestamp';
  static const String categoriesTimestampKey = 'categories_timestamp';

  /// Cache is valid for 30 minutes.
  static const Duration cacheMaxAge = Duration(minutes: 30);
}
