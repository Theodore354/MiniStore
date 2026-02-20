import 'package:flutter/foundation.dart';
import 'package:mini_store/data/datasources/local_data_source.dart';
import 'package:mini_store/data/models/cart_item_model.dart';
import 'package:mini_store/domain/entities/cart_item.dart';
import 'package:mini_store/domain/entities/product.dart';

/// Manages shopping cart state with Hive persistence.
///
/// Invariants:
/// - Adding a product that already exists increments its quantity (no duplicates)
/// - Quantity is always >= 1; decrementing below 1 removes the item
/// - Cart is persisted to Hive on every mutation
class CartProvider extends ChangeNotifier {
  final LocalDataSource _localDataSource;

  CartProvider({required LocalDataSource localDataSource})
      : _localDataSource = localDataSource {
    _loadCartFromCache();
  }

  // ─── State ──────────────────────────────────────────────────

  List<CartItemModel> _items = [];

  // ─── Getters ────────────────────────────────────────────────

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => _items.isEmpty;

  /// Returns the quantity of a specific product in the cart, or 0.
  int getQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    return index >= 0 ? _items[index].quantity : 0;
  }

  /// Returns whether a product is already in the cart.
  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  // ─── Actions ────────────────────────────────────────────────

  /// Adds a product to the cart. If it already exists, increments quantity.
  void addToCart(Product product) {
    final existingIndex =
        _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Product exists — increment quantity
      final existing = _items[existingIndex];
      _items[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      // New product — add with quantity 1
      _items.add(CartItemModel.fromEntity(CartItem(product: product, quantity: 1)));
    }

    _persistCart();
    notifyListeners();
  }

  /// Removes a product entirely from the cart.
  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _persistCart();
    notifyListeners();
  }

  /// Increments the quantity of a product in the cart.
  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    final item = _items[index];
    _items[index] = item.copyWith(quantity: item.quantity + 1);
    _persistCart();
    notifyListeners();
  }

  /// Decrements the quantity. Removes the item if quantity would drop below 1.
  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    final item = _items[index];
    if (item.quantity <= 1) {
      _items.removeAt(index);
    } else {
      _items[index] = item.copyWith(quantity: item.quantity - 1);
    }

    _persistCart();
    notifyListeners();
  }

  /// Updates the quantity of a specific product directly.
  void updateQuantity(int productId, int quantity) {
    if (quantity < 1) {
      removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    _items[index] = _items[index].copyWith(quantity: quantity);
    _persistCart();
    notifyListeners();
  }

  /// Clears all items from the cart.
  void clearCart() {
    _items.clear();
    _persistCart();
    notifyListeners();
  }

  // ─── Persistence ───────────────────────────────────────────

  void _loadCartFromCache() {
    try {
      _items = _localDataSource.getCart();
      notifyListeners();
    } catch (_) {
      // If cart is corrupted, start fresh
      _items = [];
    }
  }

  Future<void> _persistCart() async {
    try {
      await _localDataSource.saveCart(_items);
    } catch (_) {
      // Non-critical: cart will be lost on restart but app continues working
    }
  }
}
