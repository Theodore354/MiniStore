import 'dart:convert';
import 'package:mini_store/domain/entities/product.dart';

/// Data model for [Product] with JSON serialization and Hive storage support.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.description,
    required super.category,
    required super.image,
    required super.rating,
  });

  /// Creates a [ProductModel] from a JSON map.
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    String parseString(dynamic v) => v?.toString() ?? '';

    final ratingRaw = json['rating'];
    final rating = (ratingRaw is Map<String, dynamic>)
        ? RatingModel.fromJson(ratingRaw)
        : const RatingModel(rate: 0.0, count: 0);

    return ProductModel(
      id: parseId(json['id']),
      title: parseString(json['title']),
      price: parseDouble(json['price']),
      description: parseString(json['description']),
      category: parseString(json['category']),
      image: parseString(json['image']),
      rating: rating,
    );
  }

  /// Converts this model to a JSON map for caching.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': {'rate': rating.rate, 'count': rating.count},
    };
  }

  /// Serializes a list of [ProductModel] to a JSON string for Hive storage.
  static String encodeList(List<ProductModel> products) {
    return jsonEncode(products.map((p) => p.toJson()).toList());
  }

  /// Deserializes a JSON string to a list of [ProductModel].
  static List<ProductModel> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => ProductModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

/// Data model for [Rating] with JSON serialization.
class RatingModel extends Rating {
  const RatingModel({required super.rate, required super.count});

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return RatingModel(
      rate: parseDouble(json['rate']),
      count: parseInt(json['count']),
    );
  }
}
