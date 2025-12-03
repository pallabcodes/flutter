import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:finwise/core/security/secure_storage.dart';
import 'package:finwise/core/auth/firebase_auth_service.dart';

/// Real-time WebSocket service for live data synchronization
class WebSocketService {
  WebSocketChannel? _channel;
  final StreamController<RealTimeEvent> _eventController =
      StreamController<RealTimeEvent>.broadcast();

  final StreamController<ConnectionStatus> _connectionController =
      StreamController<ConnectionStatus>.broadcast();

  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _heartbeatInterval = Duration(seconds: 30);

  String? _userId;
  String? _authToken;
  bool _isConnecting = false;

  // Connection status stream
  Stream<ConnectionStatus> get connectionStatus => _connectionController.stream;

  // Real-time events stream
  Stream<RealTimeEvent> get events => _eventController.stream;

  /// Initialize WebSocket service
  Future<void> initialize() async {
    // Monitor connectivity changes
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _onConnectivityChanged(connectivityResult);
  }

  /// Connect to WebSocket server
  Future<void> connect(String userId) async {
    if (_isConnecting || _channel != null) return;

    _isConnecting = true;
    _userId = userId;

    try {
      // Get authentication token
      _authToken = await _getAuthToken();

      if (_authToken == null) {
        throw Exception('No authentication token available');
      }

      _connectionController.add(ConnectionStatus.connecting);

      // Create WebSocket connection with authentication
      final uri = Uri.parse('wss://api.finwise.com/realtime')
          .replace(queryParameters: {
            'userId': userId,
            'token': _authToken,
          });

      _channel = WebSocketChannel.connect(uri);

      // Set up message handling
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnect,
      );

      // Wait for connection confirmation
      await _waitForConnection();

      // Start heartbeat
      _startHeartbeat();

      _connectionController.add(ConnectionStatus.connected);
      _reconnectAttempts = 0;

    } catch (e) {
      _connectionController.add(ConnectionStatus.error(e.toString()));
      _scheduleReconnect();
    } finally {
      _isConnecting = false;
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _stopHeartbeat();
    _cancelReconnect();

    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }

    _connectionController.add(ConnectionStatus.disconnected);
  }

  /// Subscribe to real-time events
  Future<void> subscribe(List<String> topics) async {
    if (_channel == null) return;

    _sendMessage({
      'type': 'subscribe',
      'topics': topics,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Unsubscribe from real-time events
  Future<void> unsubscribe(List<String> topics) async {
    if (_channel == null) return;

    _sendMessage({
      'type': 'unsubscribe',
      'topics': topics,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Send custom message
  void sendMessage(Map<String, dynamic> message) {
    _sendMessage(message);
  }

  // Private methods
  void _sendMessage(Map<String, dynamic> message) {
    if (_channel == null) return;

    try {
      final messageWithAuth = {
        ...message,
        'userId': _userId,
        'authToken': _authToken,
      };

      _channel!.sink.add(jsonEncode(messageWithAuth));
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message.toString());
      final event = RealTimeEvent.fromJson(data);

      // Handle special events
      switch (event.type) {
        case 'connection_ack':
          _onConnectionAcknowledged();
          break;
        case 'heartbeat_ack':
          // Heartbeat acknowledged - connection is healthy
          break;
        default:
          _eventController.add(event);
      }
    } catch (e) {
      _handleError(e);
    }
  }

  void _handleError(dynamic error) {
    _connectionController.add(ConnectionStatus.error(error.toString()));
    _scheduleReconnect();
  }

  void _handleDisconnect() {
    _stopHeartbeat();
    _channel = null;

    if (!_isConnecting) {
      _connectionController.add(ConnectionStatus.disconnected);
      _scheduleReconnect();
    }
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    final isOnline = result != ConnectivityResult.none;

    if (!isOnline && _channel != null) {
      // Network lost - disconnect
      disconnect();
    } else if (isOnline && _channel == null && _userId != null) {
      // Network restored - reconnect
      connect(_userId!);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
      _sendMessage({
        'type': 'heartbeat',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;

    _cancelReconnect();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      if (_userId != null) {
        connect(_userId!);
      }
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  Future<void> _waitForConnection() async {
    // Wait for connection acknowledgment or timeout
    final completer = Completer<void>();

    late StreamSubscription subscription;
    subscription = _eventController.stream.listen((event) {
      if (event.type == 'connection_ack') {
        subscription.cancel();
        completer.complete();
      }
    });

    // Timeout after 10 seconds
    Future.delayed(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        completer.completeError(TimeoutException('Connection timeout'));
      }
    });

    return completer.future;
  }

  void _onConnectionAcknowledged() {
    _reconnectAttempts = 0;
    _connectionController.add(ConnectionStatus.connected);
  }

  Future<String?> _getAuthToken() async {
    // Try to get from Firebase Auth first
    try {
      final user = FirebaseAuthService().currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
    } catch (e) {
      // Fallback to stored token
    }

    // Fallback to stored token
    return await SecureStorage.getAuthToken();
  }

  void dispose() {
    _stopHeartbeat();
    _cancelReconnect();
    disconnect();
    _eventController.close();
    _connectionController.close();
  }
}

/// Real-time event data class
class RealTimeEvent {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? eventId;

  RealTimeEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.eventId,
  }) : timestamp = timestamp ?? DateTime.now();

  factory RealTimeEvent.fromJson(Map<String, dynamic> json) {
    return RealTimeEvent(
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      eventId: json['eventId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'eventId': eventId,
    };
  }
}

/// Connection status enum
enum ConnectionState { disconnected, connecting, connected, error }

class ConnectionStatus {
  final ConnectionState state;
  final String? errorMessage;

  const ConnectionStatus(this.state, [this.errorMessage]);

  const ConnectionStatus.disconnected() : this(ConnectionState.disconnected);
  const ConnectionStatus.connecting() : this(ConnectionState.connecting);
  const ConnectionStatus.connected() : this(ConnectionState.connected);
  const ConnectionStatus.error(String message) : this(ConnectionState.error, message);

  bool get isConnected => state == ConnectionState.connected;
  bool get hasError => state == ConnectionState.error;
}
