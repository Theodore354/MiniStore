import 'dart:convert';
import 'package:mini_store/domain/entities/cart_item.dart';
import 'package:mini_store/data/models/product_model.dart';

/// Data model for [CartItem] with JSON serialization for Hive persistence.
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.product,
    required super.quantity,
  });

  /// Creates a [CartItemModel] from a JSON map.
  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    return CartItemModel(
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'product': (product as ProductModel).toJson(),
      'quantity': quantity,
    };
  }

  /// Creates a [CartItemModel] from domain entities.
  factory CartItemModel.fromEntity(CartItem item) {
    final productModel = item.product is ProductModel
        ? item.product as ProductModel
        : ProductModel(
            id: item.product.id,
            title: item.product.title,
            price: item.product.price,
            description: item.product.description,
            category: item.product.category,
            image: item.product.image,
            rating: item.product.rating,
          );
    return CartItemModel(product: productModel, quantity: item.quantity);
  }

  @override
  CartItemModel copyWith({int? quantity}) {
    return CartItemModel(
      product: product,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Serializes a list of [CartItemModel] to a JSON string for Hive storage.
  static String encodeList(List<CartItemModel> items) {
    return jsonEncode(items.map((item) => item.toJson()).toList());
  }

  /// Deserializes a JSON string to a list of [CartItemModel].
  static List<CartItemModel> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
    return jsonList
        .map((json) => CartItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
