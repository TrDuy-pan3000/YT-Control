import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/models/ws_message.dart';
import '../../core/constants/ws_protocol.dart';

class WsServerService extends ChangeNotifier {
  HttpServer? _server;
  WebSocket? _client;
  bool _isRunning = false;

  bool get isRunning => _isRunning;
  bool get isClientConnected => _client != null && _client!.readyState == WebSocket.open;

  /// Khởi động server trên port 8080 (hoặc port fallback nếu trùng)
  Future<void> startServer({int port = WsProtocol.port}) async {
    if (_isRunning) return;

    int currentPort = port;
    int retries = 0;
    while (retries < 3) {
      try {
        _server = await HttpServer.bind(InternetAddress.anyIPv4, currentPort);
        break;
      } catch (e) {
        currentPort++;
        retries++;
        if (retries >= 3) {
          rethrow; // Ném lỗi nếu hết lượt thử
        }
      }
    }

    _isRunning = true;
    notifyListeners();

    try {
      await for (HttpRequest request in _server!) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          if (_client != null && _client!.readyState == WebSocket.open) {
            // Từ chối kết nối thứ 2 (chỉ cho 1 Remote kết nối)
            request.response
              ..statusCode = HttpStatus.forbidden
              ..write('Only one remote allowed')
              ..close();
            continue;
          }

          final ws = await WebSocketTransformer.upgrade(request);
          _acceptClient(ws);
        } else {
          request.response
            ..statusCode = HttpStatus.notFound
            ..close();
        }
      }
    } catch (e) {
      _isRunning = false;
      notifyListeners();
    }
  }

  void _acceptClient(WebSocket ws) {
    _client = ws;
    notifyListeners();

    // Gửi xác nhận kết nối thành công tới Remote
    sendToClient(const WsMessage(
      type: WsType.event,
      action: WsProtocol.connected,
    ));

    ws.listen(
      (data) {
        try {
          final msg = WsMessage.decode(data as String);
          onCommandReceived?.call(msg);
        } catch (_) {
          // Bỏ qua message không hợp lệ
        }
      },
      onDone: () => _handleDisconnect(),
      onError: (_) => _handleDisconnect(),
      cancelOnError: false,
    );
  }

  void _handleDisconnect() {
    _client = null;
    notifyListeners();
    onClientDisconnected?.call();
  }

  /// Gửi message đến Remote
  void sendToClient(WsMessage msg) {
    if (_client != null && _client!.readyState == WebSocket.open) {
      try {
        _client!.add(msg.encode());
      } catch (_) {
        _handleDisconnect();
      }
    }
  }

  /// Dừng server hoàn toàn
  Future<void> stopServer() async {
    try {
      await _client?.close();
    } catch (_) {}
    _client = null;
    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;
    _isRunning = false;
    notifyListeners();
  }

  // === Callbacks (được set bởi TV Player Screen) ===
  Function(WsMessage)? onCommandReceived;
  VoidCallback? onClientDisconnected;

  @override
  void dispose() {
    stopServer();
    super.dispose();
  }
}
