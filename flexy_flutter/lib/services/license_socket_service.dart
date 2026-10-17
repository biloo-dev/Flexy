import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'license_service.dart';

enum SocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

class LicenseSocketService {
  static final LicenseSocketService instance = LicenseSocketService._internal();

  LicenseSocketService._internal();

  io.Socket? _socket;
  SocketConnectionState _connectionState = SocketConnectionState.disconnected;
  Timer? _keepAliveTimer;
  int _lastPingLatencyMs = 0;

  // Callbacks
  Function(Map<String, dynamic> state)? onStateReceived;
  Function(String error)? onErrorReceived;
  Function(SocketConnectionState state)? onConnectionStateChanged;
  Function(String event, dynamic data)? onServerPushEvent;

  SocketConnectionState get connectionState => _connectionState;
  bool get isConnected => _socket?.connected == true;
  int get lastPingLatencyMs => _lastPingLatencyMs;

  /// Derive socket URL from LicenseService base HTTP URL
  String get _socketUrl {
    final baseUrl = LicenseService.instance.baseUrl;
    final uri = Uri.parse(baseUrl);
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return '${uri.scheme}://${uri.host}';
  }

  /// Initialize and connect to NestJS Socket.IO Gateway
  void connect({
    required String deviceUuid,
    required String deviceFingerprint,
    required List<Map<String, dynamic>> modems,
    String appVersion = '1.0.0',
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('⚡ [SOCKET.IO] Already connected.');
      return;
    }

    _updateState(SocketConnectionState.connecting);

    final url = _socketUrl;
    debugPrint('🔌 [SOCKET.IO] Connecting to Gateway -> $url...');

    try {
      _socket = io.io(
        url,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(10000)
            .setReconnectionAttempts(999999)
            .setTimeout(6000)
            .build(),
      );

      _setupListeners(
        deviceUuid: deviceUuid,
        deviceFingerprint: deviceFingerprint,
        appVersion: appVersion,
        modems: modems,
      );
    } catch (e) {
      debugPrint('❌ [SOCKET.IO] Initialization error: $e');
      _updateState(SocketConnectionState.error);
    }
  }

  void _setupListeners({
    required String deviceUuid,
    required String deviceFingerprint,
    required String appVersion,
    required List<Map<String, dynamic>> modems,
  }) {
    if (_socket == null) return;

    // 1. Connection Event
    _socket!.onConnect((_) {
      debugPrint('🟢 [SOCKET.IO] Connected to License Server Gateway (Socket ID: ${_socket!.id})');
      _updateState(SocketConnectionState.connected);

      // Authenticate / Register Device immediately
      _socket!.emit('device:connect', {
        'deviceUuid': deviceUuid,
        'deviceFingerprint': deviceFingerprint,
        'appVersion': appVersion,
        'modems': modems,
      });

      _startKeepAliveTimer(deviceUuid);
    });

    // 2. State received from Server
    _socket!.on('device:state', (response) {
      debugPrint('📦 [SOCKET.IO] Received "device:state" payload');
      if (response is Map) {
        final map = Map<String, dynamic>.from(response);
        if (map['success'] == true && map['data'] != null) {
          final data = Map<String, dynamic>.from(map['data'] as Map);
          final token = data['signedStateToken'] as String?;
          if (token != null && token.isNotEmpty) {
            LicenseService.instance.saveOfflineToken(token);
          }
          onStateReceived?.call(data);
        }
      }
    });

    // 3. Error Event
    _socket!.on('device:error', (err) {
      debugPrint('⚠️ [SOCKET.IO] Received "device:error": $err');
      if (err is Map) {
        final map = Map<String, dynamic>.from(err);
        final msg = map['error']?['message'] ?? 'Device verification error';
        onErrorReceived?.call(msg.toString());
      }
    });

    // 4. Server-Side Push Events (License modified, SIM updated, Device blocked)
    for (final event in ['license:updated', 'sim:updated', 'device:blocked', 'device:state_changed']) {
      _socket!.on(event, (data) {
        debugPrint('🔔 [SOCKET.IO] Received server push event: $event');
        onServerPushEvent?.call(event, data);
      });
    }

    // 5. Lightweight Pong response
    _socket!.on('device:pong', (data) {
      if (data is Map && data['timestamp'] != null) {
        final sentTime = data['timestamp'] as int;
        _lastPingLatencyMs = DateTime.now().millisecondsSinceEpoch - sentTime;
      }
    });

    // 6. Reconnect & Disconnect handlers
    _socket!.on('reconnecting', (_) {
      debugPrint('🔄 [SOCKET.IO] Reconnecting to server...');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.on('reconnect_attempt', (_) {
      debugPrint('🔄 [SOCKET.IO] Attempting reconnect...');
      _updateState(SocketConnectionState.reconnecting);
    });

    _socket!.onConnectError((err) {
      debugPrint('❌ [SOCKET.IO] Connect Error: $err');
      _updateState(SocketConnectionState.error);
    });

    _socket!.onDisconnect((_) {
      debugPrint('🔴 [SOCKET.IO] Disconnected from server');
      _updateState(SocketConnectionState.disconnected);
      _keepAliveTimer?.cancel();
    });
  }

  /// Lightweight keep-alive ping every 30 seconds (0 database queries)
  void _startKeepAliveTimer(String deviceUuid) {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_socket != null && _socket!.connected) {
        _socket!.emit('device:ping', {
          'deviceUuid': deviceUuid,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  /// Notify server when hardware (SIMs / Modems) change
  void notifyHardwareChange({
    required String deviceUuid,
    required String deviceFingerprint,
    required List<Map<String, dynamic>> modems,
    String appVersion = '1.0.0',
  }) {
    if (_socket != null && _socket!.connected) {
      debugPrint('📡 [SOCKET.IO] Emitting "device:heartbeat" (Modems: ${modems.length})...');
      _socket!.emit('device:heartbeat', {
        'deviceUuid': deviceUuid,
        'deviceFingerprint': deviceFingerprint,
        'appVersion': appVersion,
        'modems': modems,
      });
    }
  }

  void _updateState(SocketConnectionState newState) {
    _connectionState = newState;
    onConnectionStateChanged?.call(newState);
  }

  void disconnect() {
    _keepAliveTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateState(SocketConnectionState.disconnected);
  }
}
