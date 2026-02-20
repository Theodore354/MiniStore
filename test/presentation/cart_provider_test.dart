import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/presentation/providers/cart_provider.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/data/models/cart_item_model.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';

class FakeLocalDataSource implements LocalDataSource {
  final Map<String, dynamic> _store = {};

  @override
  Future<void> cacheCategories(List<String> categories) async =>
      throw UnimplementedError();
  @override
  Future<void> cacheProducts(List<ProductModel> products) async =>
      throw UnimplementedError();

  @override
  List<String> getCachedCategories() => throw UnimplementedError();

  @override
  List<ProductModel> getCachedProducts() => throw UnimplementedError();
  @override
  bool hasCachedProducts() => false;
  @override
  bool isCategoriesCacheValid() => false;
  @override
  bool isProductsCacheValid() => false;

  @override
  Future<void> saveCart(List<CartItemModel> items) async {
    _store['cart'] = CartItemModel.encodeList(items);
  }

  @override
  List<CartItemModel> getCart() {
    final json = _store['cart'] as String?;
    if (json == null) return [];
    return CartItemModel.decodeList(json);
  }

  // The LocalDataSource has other methods; we implement only what's used by CartProvider.
  @override
  Future<void> clearAll() => throw UnimplementedError();
}

Product makeProduct(int id) => Product(
  id: id,
  title: 'Product $id',
  price: id.toDouble(),
  description: 'desc',
  category: 'cat',
  image: '',
  rating: const Rating(rate: 4.0, count: 1),
);

void main() {
  test(
    'CartProvider add/increment/decrement/remove works and persists',
    () async {
      final fakeLocal = FakeLocalDataSource();
      final cart = CartProvider(localDataSource: fakeLocal);

      final p1 = makeProduct(1);

      expect(cart.itemCount, 0);
      cart.addToCart(p1);
      expect(cart.itemCount, 1);
      expect(cart.isInCart(1), true);
      expect(cart.getQuantity(1), 1);

      cart.addToCart(p1);
      expect(cart.getQuantity(1), 2);

      cart.incrementQuantity(1);
      expect(cart.getQuantity(1), 3);

      cart.decrementQuantity(1);
      expect(cart.getQuantity(1), 2);

      cart.updateQuantity(1, 5);
      expect(cart.getQuantity(1), 5);

      cart.decrementQuantity(1);
      cart.decrementQuantity(1);
      cart.decrementQuantity(1);
      cart.decrementQuantity(1);
      cart.decrementQuantity(1);
      // quantity should drop to 0 -> removed
      expect(cart.isInCart(1), false);

      // ensure persistence via fake local (no exceptions)
      expect(fakeLocal.getCart().length, 0);
    },
  );
}
