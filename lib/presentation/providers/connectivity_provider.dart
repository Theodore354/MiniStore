import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mini_store/core/network_info.dart';

/// Tracks network connectivity and exposes an [isOnline] flag.
///
/// When connectivity is restored, calls [onConnectivityRestored] callback
/// so providers can trigger a background data refresh.
class ConnectivityProvider extends ChangeNotifier {
  final NetworkInfo _networkInfo;
  final VoidCallback? onConnectivityRestored;

  bool _isOnline = true;
  StreamSubscription<bool>? _subscription;

  ConnectivityProvider({
    required NetworkInfo networkInfo,
    this.onConnectivityRestored,
  }) : _networkInfo = networkInfo {
    _init();
  }

  bool get isOnline => _isOnline;

  Future<void> _init() async {
    // Check initial status
    _isOnline = await _networkInfo.isConnected;
    notifyListeners();

    // Listen for changes
    _subscription = _networkInfo.onConnectivityChanged.listen((isConnected) {
      final wasOffline = !_isOnline;
      _isOnline = isConnected;
      notifyListeners();

      // Trigger background refresh when coming back online
      if (wasOffline && isConnected && onConnectivityRestored != null) {
        onConnectivityRestored!();
      }
    });
  }

  /// Manually check and update connectivity status.
  Future<void> checkConnectivity() async {
    _isOnline = await _networkInfo.isConnected;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
