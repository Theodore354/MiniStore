import 'package:flutter/foundation.dart';
import 'package:mini_store/core/exceptions.dart';
import 'package:mini_store/domain/entities/product.dart';
import 'package:mini_store/domain/repositories/product_repository.dart';
import 'package:mini_store/core/constants.dart';

/// Manages product listing state with client-side pagination, search, and category filtering.
///
/// Pagination strategy: Fetches all 20 products once, then slices them into
/// pages of [AppConstants.pageSize] items to simulate infinite scroll.
class ProductProvider extends ChangeNotifier {
  final ProductRepository _repository;

  ProductProvider({required ProductRepository repository})
      : _repository = repository;

  // ─── State ──────────────────────────────────────────────────

  List<Product> _allProducts = [];
  List<Product> _displayedProducts = [];
  List<String> _categories = [];
  String? _selectedCategory;
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;
  bool _isOffline = false;
  int _currentPage = 0;

  // ─── Getters ────────────────────────────────────────────────

  List<Product> get products => _displayedProducts;
  List<String> get categories => _categories;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  // ─── Filtered products (internal) ──────────────────────────

  List<Product> get _filteredProducts {
    var filtered = List<Product>.from(_allProducts);

    // Apply category filter
    if (_selectedCategory != null && _selectedCategory!.isNotEmpty) {
      filtered = filtered
          .where((p) =>
              p.category.toLowerCase() == _selectedCategory!.toLowerCase())
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((p) => p.title.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  // ─── Actions ────────────────────────────────────────────────

  /// Loads the initial page of products and categories.
  Future<void> loadProducts({bool forceRefresh = false}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _allProducts = await _repository.getProducts(forceRefresh: forceRefresh);
      _isOffline = false;
      _resetPagination();
      _loadNextPage();
    } on NetworkException catch (e) {
      _isOffline = true;
      // Try to use cached data even when offline
      if (_allProducts.isEmpty) {
        _errorMessage = e.message;
      } else {
        _resetPagination();
        _loadNextPage();
      }
    } on ServerException catch (e) {
      _errorMessage = e.message;
      // If we already have cached products, keep showing them
      if (_allProducts.isNotEmpty) {
        _errorMessage = null; // Clear error, we have fallback data
      }
    } catch (e) {
      _errorMessage = 'Something went wrong. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads categories from the repository.
  Future<void> loadCategories() async {
    try {
      _categories = await _repository.getCategories();
      notifyListeners();
    } catch (_) {
      // Categories are non-critical; silently fail
    }
  }

  /// Loads the next page of products for infinite scroll.
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    // Simulate a brief delay for realistic pagination feel
    await Future.delayed(const Duration(milliseconds: 300));

    _loadNextPage();
    _isLoadingMore = false;
    notifyListeners();
  }

  /// Sets the category filter. Pass null to show all categories.
  void setCategory(String? category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _resetPagination();
    _loadNextPage();
    notifyListeners();
  }

  /// Sets the search query. Keeps the current category filter.
  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _resetPagination();
    _loadNextPage();
    notifyListeners();
  }

  /// Refreshes data from the network.
  Future<void> refresh() async {
    await loadProducts(forceRefresh: true);
    await loadCategories();
  }

  /// Called when connectivity is restored to attempt a background refresh.
  Future<void> onConnectivityRestored() async {
    if (_isOffline) {
      _isOffline = false;
      notifyListeners();
      await refresh();
    }
  }

  // ─── Pagination internals ─────────────────────────────────

  void _resetPagination() {
    _currentPage = 0;
    _displayedProducts = [];
    _hasMore = true;
  }

  void _loadNextPage() {
    final filtered = _filteredProducts;
    final startIndex = _currentPage * AppConstants.pageSize;

    if (startIndex >= filtered.length) {
      _hasMore = false;
      return;
    }

    final endIndex = (startIndex + AppConstants.pageSize).clamp(0, filtered.length);
    final pageItems = filtered.sublist(startIndex, endIndex);

    _displayedProducts = [..._displayedProducts, ...pageItems];
    _currentPage++;
    _hasMore = endIndex < filtered.length;
  }
}
