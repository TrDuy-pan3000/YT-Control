import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../core/models/ws_message.dart';
import '../../core/constants/ws_protocol.dart';
import 'tv_player_controller.dart';

class WsServerService extends ChangeNotifier {
  HttpServer? _server;
  WebSocket? _client;
  bool _isRunning = false;

  int get serverPort => _server?.port ?? WsProtocol.port;

  /// Stream riêng biệt để phát sự kiện kết nối/ngắt kết nối đáng tin cậy.
  /// Tách khỏi notifyListeners() để tránh race condition với Navigator lifecycle.
  final StreamController<bool> _connectionStreamController =
      StreamController<bool>.broadcast();

  /// Lắng nghe stream này thay vì addListener() để trigger navigation.
  Stream<bool> get onClientConnectionChanged =>
      _connectionStreamController.stream;

  bool get isRunning => _isRunning;

  /// Kiểm tra đơn giản — chỉ cần _client != null.
  /// Không dùng readyState vì có thể chưa cập nhật ngay trên một số TV.
  bool get isClientConnected => _client != null;

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
          rethrow;
        }
      }
    }

    _isRunning = true;
    notifyListeners();

    try {
      // Dùng handleError để bắt các lỗi kết nối ở cấp độ Stream (như quét mạng TCP ping)
      // tránh làm sập và thoát khỏi vòng lặp lắng nghe của Server.
      final secureStream = _server!.handleError((error) {
        debugPrint('WS Server stream error: $error');
      });

      await for (HttpRequest request in secureStream) {
        try {
          if (WebSocketTransformer.isUpgradeRequest(request)) {
            if (_client != null) {
              debugPrint('A new remote is connecting. Preempting existing connection.');
              try {
                _client!.close();
              } catch (_) {}
              _client = null;
            }

            final ws = await WebSocketTransformer.upgrade(request);
            _acceptClient(ws);
          } else if (request.uri.path == '/player') {
            request.response
              ..headers.contentType = ContentType.html
              ..write(TvPlayerController.playerHtml)
              ..close();
          } else {
            request.response
              ..statusCode = HttpStatus.notFound
              ..close();
          }
        } catch (e) {
          debugPrint('WS Server request error: $e');
          try {
            request.response.close();
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('WS Server fatal error: $e');
      _isRunning = false;
      notifyListeners();
    }
  }

  void _acceptClient(WebSocket ws) {
    _client = ws;
    notifyListeners();

    // Gửi xác nhận kết nối thành công tới Remote trước
    sendToClient(const WsMessage(
      type: WsType.event,
      action: WsProtocol.connected,
    ));

    // Setup listener
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

    // Phát sự kiện kết nối SAU KHI setup listener hoàn toàn xong.
    // Đây là điểm then chốt: stream event đến sau 1 microtask,
    // đảm bảo WsPlayerScreen có đủ thời gian set onCommandReceived.
    Future.microtask(() {
      if (!_connectionStreamController.isClosed) {
        _connectionStreamController.add(true);
      }
    });
  }

  void _handleDisconnect() {
    try {
      _client?.close();
    } catch (_) {}
    _client = null;
    notifyListeners();
    if (!_connectionStreamController.isClosed) {
      _connectionStreamController.add(false);
    }
    onClientDisconnected?.call();
  }

  /// Gửi message đến Remote
  void sendToClient(WsMessage msg) {
    if (_client != null) {
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
    _connectionStreamController.close();
    super.dispose();
  }
}
