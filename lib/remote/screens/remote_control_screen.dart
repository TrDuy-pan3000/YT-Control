import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/ws_protocol.dart';
import '../../core/models/song.dart';
import '../../core/models/ws_message.dart';
import '../../core/services/youtube_search_service.dart';
import '../services/ws_client_service.dart';
import '../services/queue_manager.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/search_results_widget.dart';
import '../widgets/queue_list_widget.dart';
import '../widgets/playback_controls.dart';

class RemoteControlScreen extends StatefulWidget {
  const RemoteControlScreen({Key? key}) : super(key: key);

  @override
  State<RemoteControlScreen> createState() => _RemoteControlScreenState();
}

class _RemoteControlScreenState extends State<RemoteControlScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Search state
  List<Song> _searchResults = [];
  SearchResultsState _searchState = SearchResultsState.idle;
  
  // Player state synchronized from TV
  double _position = 0;   // in seconds
  double _duration = 0;   // in seconds
  String _playerState = 'idle';
  int _volume = 100;      // 0-100, synced từ TV

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Đăng ký nhận tin nhắn đồng bộ từ TV
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupWebSocketListeners();
    });
  }

  void _setupWebSocketListeners() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    final queueManager = Provider.of<QueueManager>(context, listen: false);

    wsClient.onServerMessage = (msg) {
      if (!mounted) return;

      switch (msg.action) {
        case WsProtocol.videoEnded:
          // Tự động chuyển phát bài hát tiếp theo trong Queue
          final nextSong = queueManager.playNext();
          if (nextSong != null) {
            wsClient.send(WsMessage(
              type: WsType.command,
              action: WsProtocol.playNow,
              payload: nextSong.toJson(),
            ));
          } else {
            // Hết hàng đợi bài hát
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(AppStrings.allSongsPlayed),
                backgroundColor: AppColors.success,
              ),
            );
          }
          break;

        case WsProtocol.playerState:
          // Đồng bộ hóa thanh progress bar, thời gian, và âm lượng realtime
          final posVal = msg.payload?['position'];
          final durVal = msg.payload?['duration'];
          final stateVal = msg.payload?['state'] as String?;
          final volVal = msg.payload?['volume'];

          setState(() {
            _position = (posVal is num) ? posVal.toDouble() : 0.0;
            _duration = (durVal is num) ? durVal.toDouble() : 0.0;
            if (stateVal != null) _playerState = stateVal;
            if (volVal is num) _volume = volVal.toInt();
          });
          break;

        case WsProtocol.videoError:
          // Lỗi phát từ TV → Tự động chuyển bài tiếp theo
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video YouTube bị lỗi phát trên TV! Đang chuyển bài tiếp...'),
              backgroundColor: AppColors.error,
            ),
          );
          final nextSong = queueManager.playNext();
          if (nextSong != null) {
            wsClient.send(WsMessage(
              type: WsType.command,
              action: WsProtocol.playNow,
              payload: nextSong.toJson(),
            ));
          }
          break;
      }
    };
  }

  Future<void> _handleSearch(String keyword, bool karaokeMode) async {
    if (keyword.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _searchState = SearchResultsState.idle;
      });
      return;
    }

    setState(() {
      _searchState = SearchResultsState.loading;
    });

    final searchService = Provider.of<YouTubeSearchService>(context, listen: false);
    try {
      final results = await searchService.search(keyword, karaokeMode: karaokeMode);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _searchState = results.isEmpty ? SearchResultsState.empty : SearchResultsState.success;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _searchState = SearchResultsState.error;
        });
      }
    }
  }

  void _onAddToQueue(Song song) {
    final queueManager = Provider.of<QueueManager>(context, listen: false);
    final wsClient = Provider.of<WsClientService>(context, listen: false);

    final shouldAutoplay = queueManager.addToQueue(song);
    
    // Show SnackBar
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã chọn bài: ${song.title}'),
        action: SnackBarAction(
          label: 'XEM HÀNG ĐỢI',
          textColor: AppColors.accent,
          onPressed: () => _tabController.animateTo(1),
        ),
        duration: const Duration(seconds: 2),
      ),
    );

    if (shouldAutoplay) {
      // Nếu là bài đầu tiên → Phát ngay
      wsClient.send(WsMessage(
        type: WsType.command,
        action: WsProtocol.playNow,
        payload: song.toJson(),
      ));
    }
  }

  void _onPlayPause() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    final isPlaying = _playerState == 'playing';
    
    wsClient.send(WsMessage(
      type: WsType.command,
      action: isPlaying ? WsProtocol.pause : WsProtocol.resume,
    ));
  }

  void _onNext() {
    final queueManager = Provider.of<QueueManager>(context, listen: false);
    final wsClient = Provider.of<WsClientService>(context, listen: false);

    final nextSong = queueManager.playNext();
    if (nextSong != null) {
      wsClient.send(WsMessage(
        type: WsType.command,
        action: WsProtocol.playNow,
        payload: nextSong.toJson(),
      ));
    }
  }

  void _onPrevious() {
    final queueManager = Provider.of<QueueManager>(context, listen: false);
    final wsClient = Provider.of<WsClientService>(context, listen: false);

    final prevSong = queueManager.playPrevious();
    if (prevSong != null) {
      wsClient.send(WsMessage(
        type: WsType.command,
        action: WsProtocol.playNow,
        payload: prevSong.toJson(),
      ));
    }
  }

  void _onSeekForward() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    wsClient.send(const WsMessage(
      type: WsType.command,
      action: WsProtocol.seekForward,
      payload: {'seconds': 10},
    ));
  }

  void _onSeekBackward() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    wsClient.send(const WsMessage(
      type: WsType.command,
      action: WsProtocol.seekBackward,
      payload: {'seconds': 10},
    ));
  }

  void _onVolumeUp() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    wsClient.send(const WsMessage(
      type: WsType.command,
      action: WsProtocol.volumeUp,
    ));
  }

  void _onVolumeDown() {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    wsClient.send(const WsMessage(
      type: WsType.command,
      action: WsProtocol.volumeDown,
    ));
  }

  void _onVolumeChanged(double value) {
    final wsClient = Provider.of<WsClientService>(context, listen: false);
    final level = value.round();
    setState(() => _volume = level);
    wsClient.send(WsMessage(
      type: WsType.command,
      action: WsProtocol.setVolume,
      payload: {'level': level},
    ));
  }

  void _onTapSongInQueue(int index) {
    final queueManager = Provider.of<QueueManager>(context, listen: false);
    final wsClient = Provider.of<WsClientService>(context, listen: false);

    queueManager.playSongAtIndex(index);
    final song = queueManager.currentSong;
    if (song != null) {
      wsClient.send(WsMessage(
        type: WsType.command,
        action: WsProtocol.playNow,
        payload: song.toJson(),
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wsClient = Provider.of<WsClientService>(context);
    final queueManager = Provider.of<QueueManager>(context);

    final isClientConnected = wsClient.isConnected;
    final isPlaying = _playerState == 'playing';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Điều khiển Karaoke',
          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primaryLight,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            const Tab(text: 'Tìm kiếm'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Hàng đợi'),
                  if (queueManager.length > 0) ...[
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${queueManager.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Giao diện chính 3 phần
          Column(
            children: [
              // 1. Ô tìm kiếm
              SearchBarWidget(onSearch: _handleSearch),
              
              // 2. Nội dung hiển thị Tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab Tìm kiếm
                    SearchResultsWidget(
                      results: _searchResults,
                      state: _searchState,
                      onAddToQueue: _onAddToQueue,
                    ),
                    
                    // Tab Hàng đợi
                    QueueListWidget(
                      queue: queueManager.queue,
                      currentIndex: queueManager.currentIndex,
                      onReorder: queueManager.reorder,
                      onRemove: queueManager.removeAt,
                      onTapSong: _onTapSongInQueue,
                    ),
                  ],
                ),
              ),
              
              // 3. Thanh điều khiển nhạc ở dưới cùng
              PlaybackControls(
                currentSong: queueManager.currentSong,
                isPlaying: isPlaying,
                isConnected: isClientConnected,
                position: _position,
                duration: _duration,
                volume: _volume,
                onPlayPause: _onPlayPause,
                onNext: _onNext,
                onPrevious: _onPrevious,
                onSeekForward: _onSeekForward,
                onSeekBackward: _onSeekBackward,
                onVolumeUp: _onVolumeUp,
                onVolumeDown: _onVolumeDown,
                onVolumeChanged: _onVolumeChanged,
              ),
            ],
          ),

          // Lớp phủ khi mất kết nối WebSocket
          if (wsClient.connectionState != WsConnectionState.connected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.wifi_off_outlined, size: 80, color: AppColors.warning),
                        const SizedBox(height: 24.0),
                        const Text(
                          AppStrings.connectionLost,
                          style: TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          wsClient.connectionState == WsConnectionState.connecting
                              ? 'Đang kết nối lại...'
                              : wsClient.connectionState == WsConnectionState.error
                                  ? 'Kết nối thất bại sau ${wsClient.maxRetries} lần thử tự động.'
                                  : 'Đang tự động thử lại kết nối (${wsClient.retryCount}/${wsClient.maxRetries})...',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.0),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                wsClient.disconnect();
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.surfaceLight),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                              ),
                              child: const Text('Màn hình kết nối'),
                            ),
                            if (wsClient.connectionState == WsConnectionState.error && wsClient.lastIp != null) ...[
                              const SizedBox(width: 16.0),
                              ElevatedButton(
                                onPressed: () {
                                  wsClient.connect(wsClient.lastIp!);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
                                ),
                                child: const Text('Thử lại ngay'),
                              ),
                            ],
                          ],
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
