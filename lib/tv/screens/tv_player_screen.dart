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

class TvPlayerScreen extends StatefulWidget {
  const TvPlayerScreen({Key? key}) : super(key: key);

  @override
  State<TvPlayerScreen> createState() => _TvPlayerScreenState();
}

class _TvPlayerScreenState extends State<TvPlayerScreen> {
  Timer? _overlayTimer;
  bool _showNowPlaying = false;
  String _songTitle = '';
  String _channelName = '';

  @override
  void initState() {
    super.initState();
    
    // Bật Wake Lock giữ TV luôn sáng
    final wakelock = Provider.of<TvWakelockService>(context, listen: false);
    wakelock.enable();

    // Nối dây logic giữa WebSocket Server và Player Controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCommunication();
    });
  }

  void _initializeCommunication() {
    final wsServer = Provider.of<WsServerService>(context, listen: false);
    final playerController = Provider.of<TvPlayerController>(context, listen: false);

    // luồng COMMAND: Remote -> TV
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
      }
    };

    // luồng EVENT: Player -> WebSocket -> Remote
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

    // luồng SYNC: Player progress -> WebSocket -> Remote
    playerController.onProgressSync = (position, duration) {
      wsServer.sendToClient(WsMessage(
        type: WsType.sync,
        action: WsProtocol.playerState,
        payload: {
          'state': playerController.state.name,
          'position': position,
          'duration': duration,
        },
      ));
    };

    // Luồng disconnect của Remote
    wsServer.onClientDisconnected = () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết bị điều khiển đã ngắt kết nối. Video vẫn tiếp tục phát!'),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }
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

          // Lớp phủ cảnh báo Remote ngắt kết nối (Nếu có)
          if (!wsServer.isClientConnected)
            Positioned(
              bottom: 24.0,
              right: 24.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off, color: AppColors.warning, size: 16),
                    SizedBox(width: 8.0),
                    Text(
                      'Đang chờ thiết bị điều khiển kết nối lại...',
                      style: TextStyle(color: Colors.white, fontSize: 12.0),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
