import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import '../services/tv_player_controller.dart';
import '../services/ws_server_service.dart';

class TvPlayerWidget extends StatefulWidget {
  final TvPlayerController controller;
  const TvPlayerWidget({Key? key, required this.controller}) : super(key: key);

  @override
  State<TvPlayerWidget> createState() => _TvPlayerWidgetState();
}

class _TvPlayerWidgetState extends State<TvPlayerWidget> {
  @override
  Widget build(BuildContext context) {
    final wsServer = Provider.of<WsServerService>(context, listen: false);
    final serverPort = wsServer.serverPort;

    return InAppWebView(
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,  // Tắt chặn autoplay trên Android TV
        javaScriptEnabled: true,
        allowsInlineMediaPlayback: true,
        useWideViewPort: true,
        supportZoom: false,
        domStorageEnabled: true,
        databaseEnabled: true,
        mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
        userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
      ),
      initialUrlRequest: URLRequest(
        url: WebUri('http://127.0.0.1:$serverPort/player'),
      ),
      onWebViewCreated: (controller) {
        widget.controller.attachWebView(controller);
      },
    );
  }
}
