import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:yt_control/app.dart';
import 'package:yt_control/core/services/youtube_search_service.dart';
import 'package:yt_control/core/services/network_info_service.dart';
import 'package:yt_control/tv/services/ws_server_service.dart';
import 'package:yt_control/tv/services/tv_player_controller.dart';
import 'package:yt_control/tv/services/tv_wakelock_service.dart';
import 'package:yt_control/remote/services/ws_client_service.dart';
import 'package:yt_control/remote/services/discovery_service.dart';
import 'package:yt_control/remote/services/queue_manager.dart';

void main() {
  testWidgets('App launches and displays mode selection', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
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

    // Verify that the App title or mode selection text is found.
    expect(find.text('Ứng Dụng Karaoke 2-in-1 (TV & Remote)'), findsOneWidget);
  });
}
