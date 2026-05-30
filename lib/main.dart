import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'core/services/youtube_search_service.dart';
import 'core/services/network_info_service.dart';
import 'tv/services/ws_server_service.dart';
import 'tv/services/tv_player_controller.dart';
import 'tv/services/tv_wakelock_service.dart';
import 'remote/services/ws_client_service.dart';
import 'remote/services/discovery_service.dart';
import 'remote/services/queue_manager.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WsServerService()),
        ChangeNotifierProvider(create: (_) => WsClientService()),
        ChangeNotifierProvider(create: (_) => TvPlayerController()),
        ChangeNotifierProvider(create: (_) => QueueManager()),
        Provider(create: (_) => YouTubeSearchService()),
        Provider(create: (_) => DiscoveryService()),
        Provider(create: (_) => NetworkInfoService()),
        Provider(create: (_) => TvWakelockService()),
      ],
      child: const KaraokeApp(),
    ),
  );
}
