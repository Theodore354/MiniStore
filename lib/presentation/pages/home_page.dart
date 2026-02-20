import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mini_store/presentation/providers/product_provider.dart';
import 'package:mini_store/presentation/providers/cart_provider.dart';
import 'package:mini_store/presentation/providers/connectivity_provider.dart';
import 'package:mini_store/presentation/widgets/product_card.dart';
import 'package:mini_store/presentation/widgets/offline_banner.dart';
import 'package:mini_store/presentation/widgets/error_widget.dart';
import 'package:mini_store/presentation/pages/product_detail_page.dart';
import 'package:mini_store/presentation/pages/cart_page.dart';

/// Main page displaying the paginated product feed with search and category filters.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    // Load data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      productProvider.loadProducts();
      productProvider.loadCategories();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ProductProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'MiniStore',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
        ),
        centerTitle: false,
        actions: [
          // Cart button with badge
          Consumer<CartProvider>(
            builder: (context, cart, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartPage()),
                      );
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Offline banner
          Consumer<ConnectivityProvider>(
            builder: (context, connectivity, _) {
              if (!connectivity.isOnline) {
                return const OfflineBanner();
              }
              return const SizedBox.shrink();
            },
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: (query) {
                context.read<ProductProvider>().setSearchQuery(query);
              },
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          context.read<ProductProvider>().setSearchQuery('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Category chips
          Consumer<ProductProvider>(
            builder: (context, provider, _) {
              if (provider.categories.isEmpty) {
                return const SizedBox.shrink();
              }
              return SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    // "All" chip
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: provider.selectedCategory == null,
                        onSelected: (_) => provider.setCategory(null),
                      ),
                    ),
                    // Category chips
                    ...provider.categories.map((category) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FilterChip(
                          label: Text(_capitalizeCategory(category)),
                          selected: provider.selectedCategory == category,
                          onSelected: (_) {
                            provider.setCategory(
                              provider.selectedCategory == category
                                  ? null
                                  : category,
                            );
                          },
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // Product grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, provider, _) {
                // Loading state
                if (provider.isLoading && provider.products.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Error state
                if (provider.errorMessage != null &&
                    provider.products.isEmpty) {
                  return AppErrorWidget(
                    message: provider.errorMessage!,
                    onRetry: () => provider.loadProducts(forceRefresh: true),
                  );
                }

                // Empty state
                if (!provider.isLoading && provider.products.isEmpty) {
                  return EmptyStateWidget(
                    message: provider.searchQuery.isNotEmpty
                        ? 'No products match "${provider.searchQuery}"'
                        : 'No products available',
                    icon: provider.searchQuery.isNotEmpty
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined,
                  );
                }

                // Product grid with infinite scroll
                return RefreshIndicator(
                  onRefresh: () => provider.refresh(),
                  child: GridView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount:
                        provider.products.length + (provider.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Loading indicator at the bottom
                      if (index >= provider.products.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }

                      final product = provider.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ProductDetailPage(product: product),
                            ),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _capitalizeCategory(String category) {
    return category
        .split(' ')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : word,
        )
        .join(' ');
  }
}
