import 'package:flutter_test/flutter_test.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/data/models/cart_item_model.dart';
import 'package:mini_store/data/models/product_model.dart';
import 'package:mini_store/presentation/providers/cart_provider.dart';

// ─── Fake local data source for cart tests ───────────────────

class FakeCartLocalDataSource implements LocalDataSource {
  List<CartItemModel> _savedCart = [];

  @override
  Future<void> saveCart(List<CartItemModel> items) async {
    _savedCart = items;
  }

  @override
  List<CartItemModel> getCart() => _savedCart;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Test data ───────────────────────────────────────────────

const testProduct1 = ProductModel(
  id: 1,
  title: 'Test Shirt',
  price: 25.00,
  description: 'A test shirt',
  category: "men's clothing",
  image: 'https://example.com/shirt.jpg',
  rating: RatingModel(rate: 4.0, count: 100),
);

const testProduct2 = ProductModel(
  id: 2,
  title: 'Test Pants',
  price: 50.00,
  description: 'Test pants',
  category: "men's clothing",
  image: 'https://example.com/pants.jpg',
  rating: RatingModel(rate: 3.5, count: 80),
);

// ─── Tests ───────────────────────────────────────────────────

void main() {
  late FakeCartLocalDataSource fakeLocal;
  late CartProvider cartProvider;

  setUp(() {
    fakeLocal = FakeCartLocalDataSource();
    cartProvider = CartProvider(localDataSource: fakeLocal);
  });

  group('CartProvider', () {
    test('starts with empty cart', () {
      expect(cartProvider.isEmpty, isTrue);
      expect(cartProvider.itemCount, 0);
      expect(cartProvider.totalPrice, 0.0);
    });

    test('addToCart adds product with quantity 1', () {
      cartProvider.addToCart(testProduct1);

      expect(cartProvider.isEmpty, isFalse);
      expect(cartProvider.itemCount, 1);
      expect(cartProvider.items.first.product.id, testProduct1.id);
      expect(cartProvider.items.first.quantity, 1);
      expect(cartProvider.totalPrice, 25.00);
    });

    test('addToCart increments quantity for duplicate product (no duplicates)',
        () {
      cartProvider.addToCart(testProduct1);
      cartProvider.addToCart(testProduct1);

      expect(cartProvider.items.length, 1); // Still only 1 line item
      expect(cartProvider.items.first.quantity, 2);
      expect(cartProvider.totalPrice, 50.00); // 25 * 2
    });

    test('multiple products calculate correct total', () {
      cartProvider.addToCart(testProduct1); // $25
      cartProvider.addToCart(testProduct2); // $50
      cartProvider.addToCart(testProduct1); // $25 again → qty 2

      expect(cartProvider.items.length, 2);
      expect(cartProvider.itemCount, 3); // 2 + 1
      expect(cartProvider.totalPrice, 100.00); // 25*2 + 50*1
    });

    test('removeFromCart removes the product', () {
      cartProvider.addToCart(testProduct1);
      cartProvider.addToCart(testProduct2);
      cartProvider.removeFromCart(testProduct1.id);

      expect(cartProvider.items.length, 1);
      expect(cartProvider.items.first.product.id, testProduct2.id);
    });

    test('incrementQuantity increases quantity by 1', () {
      cartProvider.addToCart(testProduct1);
      cartProvider.incrementQuantity(testProduct1.id);

      expect(cartProvider.items.first.quantity, 2);
    });

    test('decrementQuantity removes item when quantity reaches 0', () {
      cartProvider.addToCart(testProduct1); // qty = 1
      cartProvider.decrementQuantity(testProduct1.id); // qty → 0 → remove

      expect(cartProvider.isEmpty, isTrue);
    });

    test('decrementQuantity decreases quantity by 1 when above 1', () {
      cartProvider.addToCart(testProduct1);
      cartProvider.incrementQuantity(testProduct1.id); // qty = 2
      cartProvider.decrementQuantity(testProduct1.id); // qty = 1

      expect(cartProvider.items.first.quantity, 1);
    });

    test('clearCart removes all items', () {
      cartProvider.addToCart(testProduct1);
      cartProvider.addToCart(testProduct2);
      cartProvider.clearCart();

      expect(cartProvider.isEmpty, isTrue);
      expect(cartProvider.itemCount, 0);
    });

    test('isInCart returns correct status', () {
      expect(cartProvider.isInCart(testProduct1.id), isFalse);
      cartProvider.addToCart(testProduct1);
      expect(cartProvider.isInCart(testProduct1.id), isTrue);
    });

    test('getQuantity returns correct quantity for product', () {
      expect(cartProvider.getQuantity(testProduct1.id), 0);
      cartProvider.addToCart(testProduct1);
      expect(cartProvider.getQuantity(testProduct1.id), 1);
      cartProvider.incrementQuantity(testProduct1.id);
      expect(cartProvider.getQuantity(testProduct1.id), 2);
    });

    test('persists cart to local data source on add', () {
      cartProvider.addToCart(testProduct1);

      // Verify the cart was saved
      final savedCart = fakeLocal._savedCart;
      expect(savedCart.length, 1);
      expect(savedCart.first.product.id, testProduct1.id);
    });
  });
}
