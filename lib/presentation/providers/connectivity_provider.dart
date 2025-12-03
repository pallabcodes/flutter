import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity state management provider
/// Provides real-time network status to the entire app
class ConnectivityNotifier extends StateNotifier<ConnectivityResult> {
  final Connectivity _connectivity;
  StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityNotifier()
      : _connectivity = Connectivity(),
        super(ConnectivityResult.none) {
    _initializeConnectivity();
  }

  Future<void> _initializeConnectivity() async {
    // Get initial connectivity status
    final result = await _connectivity.checkConnectivity();
    state = result;

    // Listen for connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (ConnectivityResult result) {
        state = result;
      },
      onError: (error) {
        // Log error but maintain last known state
        state = ConnectivityResult.none;
      },
    );
  }

  /// Check current connectivity status manually
  Future<void> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      state = result;
    } catch (e) {
      state = ConnectivityResult.none;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Main connectivity provider
final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityResult>((ref) {
  return ConnectivityNotifier();
});

/// Computed provider for online status
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity != ConnectivityResult.none;
});

/// Computed provider for connection type
final connectionTypeProvider = Provider<ConnectionType>((ref) {
  final connectivity = ref.watch(connectivityProvider);

  switch (connectivity) {
    case ConnectivityResult.wifi:
      return ConnectionType.wifi;
    case ConnectivityResult.mobile:
      return ConnectionType.mobile;
    case ConnectivityResult.ethernet:
      return ConnectionType.ethernet;
    case ConnectivityResult.vpn:
      return ConnectionType.vpn;
    case ConnectivityResult.bluetooth:
      return ConnectionType.bluetooth;
    case ConnectivityResult.none:
    default:
      return ConnectionType.none;
  }
});

/// Computed provider for user-friendly connection status
final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  final connectionType = ref.watch(connectionTypeProvider);

  if (!isOnline) {
    return ConnectionStatus.offline;
  }

  switch (connectionType) {
    case ConnectionType.wifi:
      return ConnectionStatus.onlineWifi;
    case ConnectionType.mobile:
      return ConnectionStatus.onlineMobile;
    case ConnectionType.ethernet:
      return ConnectionStatus.onlineEthernet;
    case ConnectionType.vpn:
      return ConnectionStatus.onlineVpn;
    case ConnectionType.bluetooth:
      return ConnectionStatus.onlineBluetooth;
    case ConnectionType.none:
      return ConnectionStatus.offline;
  }
});

/// Connection type enum
enum ConnectionType {
  wifi,
  mobile,
  ethernet,
  vpn,
  bluetooth,
  none,
}

/// User-friendly connection status
enum ConnectionStatus {
  offline,
  onlineWifi,
  onlineMobile,
  onlineEthernet,
  onlineVpn,
  onlineBluetooth,
}

/// Extension methods for connection status
extension ConnectionStatusExtension on ConnectionStatus {
  bool get isOnline => this != ConnectionStatus.offline;

  bool get isStable => this == ConnectionStatus.onlineWifi ||
                      this == ConnectionStatus.onlineEthernet;

  String get displayName {
    switch (this) {
      case ConnectionStatus.offline:
        return 'Offline';
      case ConnectionStatus.onlineWifi:
        return 'Online (Wi-Fi)';
      case ConnectionStatus.onlineMobile:
        return 'Online (Mobile)';
      case ConnectionStatus.onlineEthernet:
        return 'Online (Ethernet)';
      case ConnectionStatus.onlineVpn:
        return 'Online (VPN)';
      case ConnectionStatus.onlineBluetooth:
        return 'Online (Bluetooth)';
    }
  }

  IconData get icon {
    switch (this) {
      case ConnectionStatus.offline:
        return Icons.wifi_off;
      case ConnectionStatus.onlineWifi:
        return Icons.wifi;
      case ConnectionStatus.onlineMobile:
        return Icons.signal_cellular_alt;
      case ConnectionStatus.onlineEthernet:
        return Icons.settings_ethernet;
      case ConnectionStatus.onlineVpn:
        return Icons.vpn_lock;
      case ConnectionStatus.onlineBluetooth:
        return Icons.bluetooth;
    }
  }
}

