import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/models/ws_message.dart';
import '../../core/constants/ws_protocol.dart';

enum WsConnectionState { disconnected, connecting, connected, error }

class WsClientService extends ChangeNotifier {
  WebSocketChannel? _channel;
  WsConnectionState connectionState = WsConnectionState.disconnected;
  Timer? _reconnectTimer;
  String? _lastIp;
  int _retryCount = 0;
  static const int _maxRetries = 10;
  static const Duration _retryDelay = Duration(seconds: 3);

  bool get isConnected => connectionState == WsConnectionState.connected;
  int get retryCount => _retryCount;
  int get maxRetries => _maxRetries;

  /// Kết nối đến TV
  Future<bool> connect(String tvIp, {int port = WsProtocol.port}) async {
    _lastIp = tvIp;
    connectionState = WsConnectionState.connecting;
    notifyListeners();

    try {
      final uri = Uri.parse('ws://$tvIp:$port');
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      connectionState = WsConnectionState.connected;
      _retryCount = 0;
      notifyListeners();

      _channel!.stream.listen(
        (data) {
          try {
            final msg = WsMessage.decode(data as String);
            onServerMessage?.call(msg);
          } catch (_) {}
        },
        onDone: () => _handleDisconnect(),
        onError: (_) => _handleDisconnect(),
      );

      // Lưu IP thành công để lần sau tự điền
      await _saveLastIp(tvIp);
      return true;
    } catch (e) {
      connectionState = WsConnectionState.error;
      notifyListeners();
      _scheduleReconnect();
      return false;
    }
  }

  /// Gửi lệnh đến TV
  void send(WsMessage msg) {
    if (isConnected) {
      try {
        _channel?.sink.add(msg.encode());
      } catch (_) {
        _handleDisconnect();
      }
    }
  }

  /// Xử lý mất kết nối → auto-reconnect
  void _handleDisconnect() {
    if (connectionState == WsConnectionState.disconnected) return;
    connectionState = WsConnectionState.disconnected;
    _channel = null;
    notifyListeners();
    _scheduleReconnect();
  }

  /// Lên lịch reconnect mỗi 3 giây, tối đa 10 lần
  void _scheduleReconnect() {
    if (_retryCount >= _maxRetries || _lastIp == null) {
      connectionState = WsConnectionState.error;
      notifyListeners();
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_retryDelay, () async {
      _retryCount++;
      notifyListeners();
      await connect(_lastIp!);
    });
  }

  /// Ngắt kết nối chủ động
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _retryCount = 0;
    _lastIp = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    connectionState = WsConnectionState.disconnected;
    notifyListeners();
  }

  /// Lưu/đọc IP từ SharedPreferences
  Future<void> _saveLastIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_tv_ip', ip);
  }

  Future<String?> getLastIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('last_tv_ip');
  }

  // === Callbacks ===
  Function(WsMessage)? onServerMessage;

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
