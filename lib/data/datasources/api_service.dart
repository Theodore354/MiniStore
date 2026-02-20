import 'package:dio/dio.dart';
import 'package:mini_store/core/constants.dart';
import 'package:mini_store/core/exceptions.dart';
import 'package:mini_store/data/models/product_model.dart';

/// Remote data source that communicates with the Fake Store API via Dio.
class ApiService {
  final Dio _dio;

  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConstants.baseUrl,
              connectTimeout: AppConstants.apiTimeout,
              receiveTimeout: AppConstants.apiTimeout,
            ));

  /// Fetches all products from `/products`.
  Future<List<ProductModel>> getProducts() async {
    try {
      final response = await _dio.get('/products');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch products',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Fetches all categories from `/products/categories`.
  Future<List<String>> getCategories() async {
    try {
      final response = await _dio.get('/products/categories');
      final List<dynamic> data = response.data as List<dynamic>;
      return data.map((item) => item.toString()).toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch categories',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  /// Fetches products by category from `/products/category/{category}`.
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final response = await _dio.get('/products/category/$category');
      final List<dynamic> data = response.data as List<dynamic>;
      return data
          .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ServerException(
        message: e.message ?? 'Failed to fetch products for category: $category',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
