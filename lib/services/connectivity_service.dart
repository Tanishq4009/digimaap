import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Singleton that listens to [Connectivity] once and exposes [isOnline]
/// as a [ValueNotifier] so any widget can react without their own streams.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// `true` when device has any non-none connectivity.
  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  bool _initialized = false;

  /// Call once from [main()] before [runApp].
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Check current status immediately
    final results = await Connectivity().checkConnectivity();
    isOnline.value = results.isNotEmpty &&
        !results.contains(ConnectivityResult.none);

    // Listen to future changes
    Connectivity().onConnectivityChanged.listen((results) {
      isOnline.value = results.isNotEmpty &&
          !results.contains(ConnectivityResult.none);
      debugPrint(
        '[ConnectivityService] Status changed → ${isOnline.value ? "ONLINE" : "OFFLINE"}',
      );
    });
  }
}
