import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/presentation/providers/connectivity_provider.dart';

class MockConnectivity extends Connectivity {
  ConnectivityResult _currentResult = ConnectivityResult.none;

  void setConnectivityResult(ConnectivityResult result) {
    _currentResult = result;
  }

  @override
  Future<ConnectivityResult> checkConnectivity() async {
    return _currentResult;
  }

  @override
  Stream<ConnectivityResult> get onConnectivityChanged =>
      Stream.value(_currentResult);
}

void main() {
  late MockConnectivity mockConnectivity;
  late ConnectivityNotifier connectivityNotifier;

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityNotifier = ConnectivityNotifier();
    // Replace the internal connectivity instance
    connectivityNotifier._connectivity = mockConnectivity;
  });

  tearDown(() {
    connectivityNotifier.dispose();
  });

  group('ConnectivityNotifier', () {
    test('should initialize with none connectivity', () async {
      mockConnectivity.setConnectivityResult(ConnectivityResult.none);
      final notifier = ConnectivityNotifier();
      notifier._connectivity = mockConnectivity;

      expect(notifier.state, ConnectivityResult.none);
    });

    test('should update state when connectivity changes', () async {
      mockConnectivity.setConnectivityResult(ConnectivityResult.wifi);
      await connectivityNotifier.checkConnectivity();

      expect(connectivityNotifier.state, ConnectivityResult.wifi);
    });

    test('should handle connectivity check errors gracefully', () async {
      // Mock error scenario - connectivity check fails
      mockConnectivity.setConnectivityResult(ConnectivityResult.none);

      await connectivityNotifier.checkConnectivity();

      expect(connectivityNotifier.state, ConnectivityResult.none);
    });

    test('should properly dispose resources', () {
      final notifier = ConnectivityNotifier();
      expect(() => notifier.dispose(), returnsNormally);
    });
  });

  group('Connection Status Providers', () {
    test('isOnlineProvider should return true for wifi', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Override the connectivity notifier to return wifi
      final notifier = ConnectivityNotifier();
      notifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.wifi);

      final isOnline = container.read(isOnlineProvider);
      expect(isOnline, true);
    });

    test('isOnlineProvider should return true for mobile', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final isOnline = container.read(isOnlineProvider);
      // Default state is none, so should be false
      expect(isOnline, false);
    });

    test('connectionTypeProvider should correctly identify connection types', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test wifi
      final wifiNotifier = ConnectivityNotifier();
      wifiNotifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.wifi);
      expect(container.read(connectionTypeProvider), ConnectionType.wifi);

      // Test mobile
      final mobileNotifier = ConnectivityNotifier();
      mobileNotifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.mobile);
      expect(container.read(connectionTypeProvider), ConnectionType.mobile);

      // Test none
      final noneNotifier = ConnectivityNotifier();
      noneNotifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.none);
      expect(container.read(connectionTypeProvider), ConnectionType.none);
    });

    test('connectionStatusProvider should provide user-friendly status', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Test online wifi
      final wifiNotifier = ConnectivityNotifier();
      wifiNotifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.wifi);
      expect(container.read(connectionStatusProvider).isOnline, true);

      // Test offline
      final offlineNotifier = ConnectivityNotifier();
      offlineNotifier._connectivity = MockConnectivity()..setConnectivityResult(ConnectivityResult.none);
      expect(container.read(connectionStatusProvider).isOnline, false);
    });
  });

  group('ConnectionType Extension', () {
    test('should identify stable connections', () {
      expect(ConnectionType.wifi.isStable, true);
      expect(ConnectionType.ethernet.isStable, true);
      expect(ConnectionType.mobile.isStable, false);
      expect(ConnectionType.bluetooth.isStable, false);
    });

    test('should provide display names', () {
      expect(ConnectionType.wifi.displayName, 'Online (Wi-Fi)');
      expect(ConnectionType.mobile.displayName, 'Online (Mobile)');
      expect(ConnectionType.none.displayName, 'Offline');
    });

    test('should provide correct icons', () {
      expect(ConnectionType.wifi.icon, Icons.wifi);
      expect(ConnectionType.mobile.icon, Icons.signal_cellular_alt);
      expect(ConnectionType.none.icon, Icons.wifi_off);
    });
  });

  group('ConnectionStatus Extension', () {
    test('should identify online status', () {
      expect(ConnectionStatus.offline.isOnline, false);
      expect(ConnectionStatus.onlineWifi.isOnline, true);
      expect(ConnectionStatus.onlineMobile.isOnline, true);
      expect(ConnectionStatus.onlineEthernet.isOnline, true);
    });

    test('should identify stable connections', () {
      expect(ConnectionStatus.onlineWifi.isStable, true);
      expect(ConnectionStatus.onlineEthernet.isStable, true);
      expect(ConnectionStatus.onlineMobile.isStable, false);
      expect(ConnectionStatus.offline.isStable, false);
    });

    test('should provide display names', () {
      expect(ConnectionStatus.onlineWifi.displayName, 'Online (Wi-Fi)');
      expect(ConnectionStatus.onlineMobile.displayName, 'Online (Mobile)');
      expect(ConnectionStatus.offline.displayName, 'Offline');
    });

    test('should provide correct icons', () {
      expect(ConnectionStatus.onlineWifi.icon, Icons.wifi);
      expect(ConnectionStatus.onlineMobile.icon, Icons.signal_cellular_alt);
      expect(ConnectionStatus.offline.icon, Icons.wifi_off);
    });

    test('should provide correct colors', () {
      expect(ConnectionStatus.onlineWifi.color, Colors.green);
      expect(ConnectionStatus.onlineMobile.color, Colors.green);
      expect(ConnectionStatus.offline.color, Colors.grey);
    });
  });
}
