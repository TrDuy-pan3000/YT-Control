import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/ws_protocol.dart';
import '../../core/models/ws_message.dart';
import '../services/ws_server_service.dart';
import '../services/tv_player_controller.dart';
import '../services/tv_wakelock_service.dart';
import '../widgets/tv_player_widget.dart';
import '../../tv/widgets/tv_now_playing_overlay.dart';
import 'tv_waiting_screen.dart';

class TvPlayerScreen extends StatefulWidget {
  const TvPlayerScreen({Key? key}) : super(key: key);

  @override
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  Timer? _overlayTimer;
  Timer? _disconnectTimer;
  StreamSubscription<bool>? _connectionSub;
  
  bool _showNowPlaying = false;
  String _songTitle = '';
  String _channelName = '';
  int _disconnectCountdown = 15;

  @override
  void initState() {
    super.initState();

    // Bật Wake Lock giữ TV luôn sáng
    final wakelock = Provider.of<TvWakelockService>(context, listen: false);
    wakelock.enable();

    // Nối dây command handlers
    _initializeCommunication();
  }

  void _startDisconnectTimer() {
    _disconnectTimer?.cancel();
    setState(() {
      _disconnectCountdown = 15;
    });

    _disconnectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_disconnectCountdown > 1) {
            _disconnectCountdown--;
          } else {
            _disconnectTimer?.cancel();
            _exitToWaitingScreen();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _cancelDisconnectTimer() {
    _disconnectTimer?.cancel();
    _disconnectTimer = null;
    if (mounted) {
      setState(() {
        _disconnectCountdown = 15;
      });
    }
  }

  void _exitToWaitingScreen() {
    if (!mounted) return;
    // Tạm dừng video trước khi thoát
    final playerController = Provider.of<TvPlayerController>(context, listen: false);
    try {
      playerController.pause();
    } catch (_) {}
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const TvWaitingScreen()),
    );
  }

  void _initializeCommunication() {
    final wsServer = Provider.of<WsServerService>(context, listen: false);
    final playerController = Provider.of<TvPlayerController>(context, listen: false);

    // Lắng nghe sự kiện thay đổi kết nối để kích hoạt/hủy đếm ngược
    _connectionSub = wsServer.onClientConnectionChanged.listen((connected) {
      if (!connected) {
        _startDisconnectTimer();
      } else {
        _cancelDisconnectTimer();
      }
    });

    // Nếu lúc bắt đầu đã bị mất kết nối (rất hiếm), kích hoạt timer luôn
    if (!wsServer.isClientConnected) {
      _startDisconnectTimer();
    }

    // ─── Luồng COMMAND: Remote → TV ───
    wsServer.onCommandReceived = (msg) {
      switch (msg.action) {
        case WsProtocol.playNow:
          final videoId = msg.payload?['videoId'] as String?;
          final title = msg.payload?['title'] as String?;
          final channelName = msg.payload?['channelName'] as String? ?? 'YouTube';
          if (videoId != null && title != null) {
            playerController.loadVideo(videoId, title: title);
            _triggerNowPlayingOverlay(title, channelName);
          }
          break;

        case WsProtocol.pause:
          playerController.pause();
          break;

        case WsProtocol.resume:
          playerController.resume();
          break;

        case WsProtocol.seekForward:
          final sec = msg.payload?['seconds'] as int? ?? 10;
          playerController.seekForward(sec);
          break;

        case WsProtocol.seekBackward:
          final sec = msg.payload?['seconds'] as int? ?? 10;
          playerController.seekBackward(sec);
          break;

        case WsProtocol.next:
          final videoId = msg.payload?['videoId'] as String?;
          final title = msg.payload?['title'] as String?;
          final channelName = msg.payload?['channelName'] as String? ?? 'YouTube';
          if (videoId != null && title != null) {
            playerController.loadVideo(videoId, title: title);
            _triggerNowPlayingOverlay(title, channelName);
          }
          break;

        case WsProtocol.volumeUp:
          playerController.increaseVolume();
          break;

        case WsProtocol.volumeDown:
          playerController.decreaseVolume();
          break;

        case WsProtocol.setVolume:
          final level = msg.payload?['level'] as int?;
          if (level != null) {
            playerController.setVolume(level);
          }
          break;
      }
    };

    // ─── Luồng EVENT: Player → WebSocket → Remote ───
    playerController.onVideoEnded = () {
      wsServer.sendToClient(const WsMessage(
        type: WsType.event,
        action: WsProtocol.videoEnded,
      ));
    };

    playerController.onVideoError = (code) {
      wsServer.sendToClient(WsMessage(
        type: WsType.event,
        action: WsProtocol.videoError,
        payload: {'code': code, 'message': 'Video error occurred on TV'},
      ));
    };

    // ─── Luồng SYNC: Player progress + volume → WebSocket → Remote (mỗi 1s) ───
    playerController.onProgressSync = (position, duration, volume) {
      wsServer.sendToClient(WsMessage(
        type: WsType.sync,
        action: WsProtocol.playerState,
        payload: {
          'state': playerController.state.name,
          'position': position,
          'duration': duration,
          'volume': volume,
        },
      ));
    };

    // Callback dọn dẹp khi remote ngắt kết nối
    wsServer.onClientDisconnected = () {
      // Stream subscription ở trên đã xử lý việc đếm ngược quay lại màn hình chờ.
      // Ở đây ta chỉ log hoặc bổ trợ nếu cần.
    };
  }

  void _triggerNowPlayingOverlay(String title, String channelName) {
    setState(() {
      _songTitle = title;
      _channelName = channelName;
      _showNowPlaying = true;
    });

    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showNowPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _overlayTimer?.cancel();
    _disconnectTimer?.cancel();
    _connectionSub?.cancel();

    // Tắt Wake Lock
    final wakelock = Provider.of<TvWakelockService>(context, listen: false);
    wakelock.disable();

    // Dọn dẹp callbacks
    final wsServer = Provider.of<WsServerService>(context, listen: false);
    wsServer.onCommandReceived = null;
    wsServer.onClientDisconnected = null;

    final playerController = Provider.of<TvPlayerController>(context, listen: false);
    playerController.onVideoEnded = null;
    playerController.onVideoError = null;
    playerController.onProgressSync = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsServer = Provider.of<WsServerService>(context);
    final playerController = Provider.of<TvPlayerController>(context);

    final isConnected = wsServer.isClientConnected;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Trình phát video WebView full màn hình
          Positioned.fill(
            child: TvPlayerWidget(controller: playerController),
          ),

          // Lớp phủ thông tin bài hát đang phát (Auto-hide sau 5s)
          if (_showNowPlaying && _songTitle.isNotEmpty)
            Positioned(
              top: 24.0,
              left: 24.0,
              right: 24.0,
              child: TvNowPlayingOverlay(
                title: _songTitle,
                subtitle: _channelName,
              ),
            ),

          // Lớp phủ Glassmorphic đếm ngược khi mất kết nối (Chuyên nghiệp hơn)
          if (!isConnected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          blurRadius: 40,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.wifi_off_rounded,
                          size: 64,
                          color: AppColors.warning,
                        ),
                        const SizedBox(height: 20.0),
                        const Text(
                          'Mất kết nối với thiết bị điều khiển',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Text(
                          'Đang chờ kết nối lại... Tự động quay lại màn hình chờ sau $_disconnectCountdown giây.',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 28.0),
                        SizedBox(
                          width: 180,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _disconnectCountdown / 15.0,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
