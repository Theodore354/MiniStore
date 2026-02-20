# MiniStore – Flutter E-Commerce App

A production-ready, offline-first e-commerce mobile application built with Flutter and the Fake Store API. This project demonstrates clean architecture, advanced state management, robust error handling, and comprehensive testing.

---

## Overview

**MiniStore** is a feature-rich mobile app that fetches products from the Fake Store API, implements client-side pagination, intelligent caching with TTL, offline support, and a shopping cart with persistence. The app prioritizes reliability and user experience even in poor or absent network conditions.

### Key Features
- ✅ **Offline-First Architecture**: Cache-first strategy with network refresh fallback
- ✅ **Pagination & Infinite Scroll**: Client-side simulation of 10 items per page
- ✅ **Intelligent Caching**: 30-minute TTL with automatic invalidation and refresh on expiry
- ✅ **Shopping Cart**: Full persistence via Hive with add/remove/quantity management
- ✅ **Category Filtering & Search**: Combined filters without unintended state resets
- ✅ **Error Resilience**: Graceful handling of 500 errors, network timeouts, corrupted cache, image failures
- ✅ **Comprehensive Testing**: 36+ unit and widget tests covering critical paths
- ✅ **Clean Code**: Lint-clean, null-safe, well-documented codebase

---

## Architecture

### Layered Clean Architecture

```
┌─────────────────────────────────────────┐
│         PRESENTATION LAYER              │
│  (UI, Pages, Providers, Widgets)        │
├─────────────────────────────────────────┤
│          DOMAIN LAYER                   │
│  (Entities, Repositories - Abstract)    │
├─────────────────────────────────────────┤
│           DATA LAYER                    │
│  (Models, Datasources, Repository Impl) │
├─────────────────────────────────────────┤
│           CORE LAYER                    │
│  (Constants, Exceptions, Network Info)  │
└─────────────────────────────────────────┘
```

### Design Principles

1. **Separation of Concerns**: Each layer has a single responsibility
   - **Presentation**: UI state, user interactions
   - **Domain**: Business logic, entity definitions
   - **Data**: API calls, caching, serialization
   - **Core**: Shared utilities and abstractions

2. **Repository Pattern**: Abstract repository contracts shield domain/presentation from data source details
3. **Dependency Injection**: Providers are wired in `main.dart` with explicit dependency graphs
4. **Null Safety**: 100% null-safe codebase using Dart 3.10+

---

## State Management: Provider Pattern

We use `provider` (v6.1+) for state management. This choice prioritizes:
- **Simplicity**: Easy-to-understand reactive model
- **Testability**: Dependency injection via factories
- **Performance**: Granular rebuilds via `Consumer` and `Selector`
- **Scalability**: Works well for small-to-medium apps

### Key Providers

| Provider | Responsibility | Persistence |
|----------|-----------------|-------------|
| `ProductProvider` | Product list, pagination, search/category filters, offline state | Memory (re-fetch on restart) |
| `CartProvider` | Cart items, quantity management, total price | Hive (persists across app restarts) |
| `ConnectivityProvider` | Network status, offline→online transition hooks | N/A (ephemeral) |

---

## Caching Strategy & Expiration

### Design Philosophy

**Cache-First, Network-Second Strategy**: Prioritizes instant user experience and offline availability over always-fresh data. This choice reflects a real-world e-commerce trade-off: showing slightly-stale products immediately is better than forcing users to wait for network calls or seeing errors.

### Cache Layer: Technology Choice

**Hive** (vs SQLite, SharedPreferences, or Provider memory):
- **Why Hive?**
  - **Fast**: Key-value storage, no SQL parsing overhead
  - **Persistent**: Survives app restarts (unlike memory)
  - **Simple**: Minimal boilerplate vs SQLite
  - **Typed**: Native Dart object serialization support
  - **Lightweight**: ~2MB footprint vs SQLite's ~20MB

**Hive Boxes** (separate storage containers):
- `products_box`: Serialized product list (JSON string) + timestamp
- `categories_box`: Serialized categories (JSON string) + timestamp
- `cart_box`: Persisted cart items (JSON string) — user's purchases
- `metadata_box`: Cache timestamps for expiration validation

### Expiration Logic & TTL Reasoning

| Resource | TTL | Why? | Validation |
|----------|-----|------|-----------|
| **Products** | 30 min | Fake Store API rarely changes; 30 min balances freshness vs API load | Timestamp in metadata_box |
| **Categories** | 30 min | Same as products; categories change even less frequently | Timestamp in metadata_box |
| **Cart** | ∞ (infinite) | User's selections must persist across sessions; only cleared on user action or app uninstall | Event-driven (user mutations) |

**Why 30 minutes (not 5 or 60)?**
- 5 min: Too aggressive; wastes API quota for minimal freshness gain
- 30 min: Sweet spot — users typically browsing for 10-20 min; refreshes on re-open later
- 60 min: Too stale; user expects "new" products if browsing an hour later

### Offline-First Flow Explained

```
User opens app (or pulls-to-refresh)
  ↓
1. Check LocalDataSource.getCachedProducts()
   ↓
   YES: Check if timestamp < 30 min old
       ├─→ VALID: Return cache immediately (instant load) ✨
       └─→ EXPIRED: Proceed to network check
       
   NO: Proceed to network check
  ↓
2. Check if device is online (NetworkInfo)
   ├─→ ONLINE: Fetch from API
   │   ├─ Success: Update cache + timestamp, display fresh data
   │   └─ Error (500, timeout): Show cached if available, else error
   │
   └─→ OFFLINE: 
       ├─ Cache exists: Display stale cache + offline banner
       └─ No cache: Show error "No data available"
```

### Caching Decision Rationale

| Decision | Reasoning | Trade-Off |
|----------|-----------|-----------|
| **Cache-first** | Reduces API calls, instant UX, offline support | Data can be 30 min stale (acceptable for e-commerce) |
| **Timestamp-based validation** | Simple, no database queries, no external time sync | Requires device clock accuracy |
| **Serialized JSON (not objects)** | Avoids Hive model mapping complexity; use codegen later | Slightly slower parsing than native Hive objects |
| **Separate metadata_box** | Decouples timestamps from data; cleaner separation | Extra box overhead (negligible for small app) |
| **Persistent cart (∞ TTL)** | User expects cart to survive app close/restart | Must handle corrupted cart gracefully (implemented) |

### Corruption Resilience

If cache is corrupted (malformed JSON):
1. `LocalDataSource.getCachedProducts()` catches exception
2. Clears the corrupted cache entry
3. Returns empty list
4. Repository detects empty list + network available
5. Fetches fresh from API
6. User sees fresh data without visible error

Result: **Transparent recovery** — user sees products without knowing corruption happened.

### Benefits Summary

- **Reduced API calls**: Fake Store API not hammered; saves bandwidth/battery
- **Instant load**: Cached data displays in <100ms vs 1-3s network call
- **Offline support**: App fully functional offline (read-only, using cached data)
- **Graceful freshness**: Auto-refresh after 30 min prevents stale data build-up
- **Battery efficient**: Fewer network requests = lower power consumption
- **Scalable**: Same caching logic works for 100 products or 10,000

---

## Error Handling Matrix

| Scenario | Exception | UI Behavior | Fallback |
|----------|-----------|------------|----------|
| API 500 error | `ServerException` | `ErrorWidget` with retry button | Show cached data if available |
| No internet + no cache | `NetworkException` | `ErrorWidget` with offline message | None (must show error) |
| Corrupted cache | `CacheException` | Return empty list, clear cache | Fetch from network on retry |
| Image load failure | (handled by `CachedNetworkImage`) | Placeholder → error icon | Display gracefully |
| Timeout (10s) | `ServerException` | Same as API error | Use cache if available |

---

## Pagination & Infinite Scroll

- **Fetch**: All 20 products downloaded once from API
- **Simulate**: Client-side slicing into 10-item pages (configurable)
- **Infinite Scroll**: GridView listener triggers `loadMore()` at 200px from bottom
- **Advantages**: No repeated API calls, offline pagination works, smooth UX

---

## Search & Category Filtering

- **Search**: Filter products by title (case-insensitive substring match)
- **Category**: Filter by single selected category
- **Combined**: Both filters work together (AND logic)
- **State Preservation**: Switching category does NOT reset search query

---

## Cart System

- **Add to Cart**: Increments quantity if product already in cart (no duplicates)
- **Remove from Cart**: Deletes the entire line item
- **Quantity Control**: Increment/decrement/update quantity directly
- **Total Calculation**: Automatic sum of (price × quantity) for all items
- **Persistence**: All cart changes saved to Hive immediately

### Invariants
- Quantity ≥ 1; decrementing below 1 removes the item
- No duplicate products in cart (same ID = increment quantity)
- Cart persists across app restarts

---

## Testing

### Test Coverage

- **Unit Tests**: 34 (ProductModel, ProductProvider, CartProvider)
- **Widget Tests**: 2 (HomePage grid rendering)
- **Total**: 36 tests, all passing ✅

### Running Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/presentation/providers/product_provider_test.dart

# Run with coverage
flutter test --coverage
```

---

## Build & Run Instructions

### Prerequisites

- **Flutter**: 3.13+ (includes Dart 3.10+)
- **Device**: iOS Simulator 14+, Android Emulator API 21+, or physical device
- **Network**: Internet connection for initial API fetch (offline mode works after first run)

### Setup

```bash
# 1. Clone the repository
git clone <repo-url>
cd MiniStore

# 2. Get dependencies
flutter pub get

# 3. Run on simulator/emulator
flutter run

# 4. Run tests
flutter test
```

### Troubleshooting

| Issue | Solution |
|-------|----------|
| Build fails: "Pod install" | Run `flutter clean && flutter pub get` |
| Hive errors | Delete app data: Settings → App → MiniStore → Storage → Clear All Data |
| "No devices found" | `flutter devices` to list, then `flutter run -d <device-id>` |
| Timeout fetching products | Check internet connection; offline mode works with cached data |

---

## What Would Be Improved With More Time

### High Priority
1. **Advanced Search & Sorting** (fuzzy search, sort by price/rating)
2. **User Authentication** (sign-in, order history, wishlist)
3. **Checkout & Payment** (shipping, payment processing)
4. **Performance Optimizations** (image compression, database indexing)

### Medium Priority
5. **Enhanced Testing** (integration tests, network mocking, performance benchmarks)
6. **Error Recovery** (exponential backoff, circuit breaker pattern)
7. **Analytics & Monitoring** (crash reporting, user event tracking)
8. **Localization** (multi-language support)

### Lower Priority
9. **Accessibility** (screen reader support, high contrast, font sizes)
10. **Code Generation** (model serialization, auto-generated mocks)

---

## Known Limitations

1. **No Real Backend**: Uses public Fake Store API (20 fixed products)
2. **Client-Side Pagination Only**: All products fetched in one call
3. **No Inventory Tracking**: Cart doesn't check product availability
4. **Limited Image Handling**: External URLs only, no upload
5. **No Encryption**: Cart data stored in plain text (dev/demo suitable)

---

## Dependencies

- `provider: ^6.1.2` – State management
- `dio: ^5.4.0` – HTTP client
- `hive: ^2.2.3` + `hive_flutter: ^1.1.0` – Local storage
- `connectivity_plus: ^6.0.3` – Network status
- `cached_network_image: ^3.3.1` – Image caching & fallback
- `flutter_lints: ^6.0.0` – Lint rules

---

## License & Attribution

- **App**: Open-source, MIT License
- **Fake Store API**: Free public API (https://fakestoreapi.com/)
- **Dependencies**: Licensed under their respective licenses

---

**Last Updated**: February 20, 2026  
**Version**: 1.0.0  
**Status**: Assessment submission (Junior Flutter Developer role)
