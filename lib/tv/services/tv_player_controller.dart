import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

enum TvPlayerState { idle, loading, playing, paused, ended, error }

class TvPlayerController extends ChangeNotifier {
  InAppWebViewController? _webController;
  TvPlayerState state = TvPlayerState.idle;
  String? currentVideoId;
  String? currentTitle;
  double position = 0;    // Giây hiện tại
  double duration = 0;    // Tổng thời lượng
  int volume = 100;       // Âm lượng (0-100)

  /// HTML template chứa YouTube IFrame Player API + Progress Sync + Volume Control
  static String get playerHtml => '''
  <!DOCTYPE html>
  <html>
  <head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
      #player { width: 100%; height: 100%; }
    </style>
  </head>
  <body>
    <div id="player"></div>
    <script src="https://www.youtube.com/iframe_api"></script>
    <script>
      var player;
      var syncInterval;

      function onYouTubeIframeAPIReady() {
        player = new YT.Player("player", {
          width: "100%",
          height: "100%",
          playerVars: {
            autoplay: 1,
            controls: 0,
            disablekb: 1,
            fs: 0,
            modestbranding: 1,
            rel: 0,
            iv_load_policy: 3,
            cc_load_policy: 0,
            playsinline: 1,
            origin: "https://www.youtube.com"
          },
          events: {
            onReady: onPlayerReady,
            onStateChange: onPlayerStateChange,
            onError: onPlayerError
          }
        });
      }

      function onPlayerReady(event) {
        window.flutter_inappwebview.callHandler("onPlayerReady");
        startProgressSync();
      }

      function onPlayerStateChange(event) {
        var stateMap = {
          "-1": "unstarted", "0": "ended", "1": "playing",
          "2": "paused", "3": "buffering", "5": "cued"
        };
        var stateName = stateMap[String(event.data)] || "unknown";
        window.flutter_inappwebview.callHandler("onStateChange", stateName);

        if (event.data === 0) {
          window.flutter_inappwebview.callHandler("onVideoEnded");
        }
      }

      function onPlayerError(event) {
        window.flutter_inappwebview.callHandler("onVideoError", event.data);
      }

      // PROGRESS SYNC — Mỗi 1 giây bắn position + duration + volume về Dart
      function startProgressSync() {
        if (syncInterval) clearInterval(syncInterval);
        syncInterval = setInterval(function() {
          if (player && player.getCurrentTime && player.getDuration) {
            var pos = player.getCurrentTime() || 0;
            var dur = player.getDuration() || 0;
            var vol = (player.getVolume) ? player.getVolume() : 100;
            window.flutter_inappwebview.callHandler("onProgressSync", pos, dur, vol);
          }
        }, 1000);
      }

      // ─── Hàm được gọi từ Flutter (Dart → JS) ───
      function loadVideo(videoId) {
        if (player && player.loadVideoById) {
          player.loadVideoById(videoId);
        }
      }
      function pauseVideo()   { if (player && player.pauseVideo) player.pauseVideo(); }
      function playVideo()    { if (player && player.playVideo) player.playVideo(); }
      function seekForward(s)  {
        if (player && player.getCurrentTime && player.seekTo)
          player.seekTo(player.getCurrentTime() + s, true);
      }
      function seekBackward(s) {
        if (player && player.getCurrentTime && player.seekTo)
          player.seekTo(Math.max(0, player.getCurrentTime() - s), true);
      }
      function setVolumeLevel(v) {
        if (player && player.setVolume) {
          player.setVolume(Math.max(0, Math.min(100, v)));
        }
      }
      function volumeUpStep() {
        if (player && player.getVolume && player.setVolume) {
          var current = player.getVolume();
          player.setVolume(Math.min(100, current + 10));
        }
      }
      function volumeDownStep() {
        if (player && player.getVolume && player.setVolume) {
          var current = player.getVolume();
          player.setVolume(Math.max(0, current - 10));
        }
      }
    </script>
  </body>
  </html>
  ''';

  /// Gắn WebView Controller khi widget được build
  void attachWebView(InAppWebViewController controller) {
    _webController = controller;

    controller.addJavaScriptHandler(
      handlerName: 'onPlayerReady',
      callback: (_) {
        if (currentVideoId != null) {
          loadVideo(currentVideoId!, title: currentTitle);
        }
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onVideoEnded',
      callback: (_) {
        state = TvPlayerState.ended;
        notifyListeners();
        onVideoEnded?.call();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onStateChange',
      callback: (args) {
        final stateName = args[0] as String;
        state = _mapState(stateName);
        notifyListeners();
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onProgressSync',
      callback: (args) {
        position = (args[0] as num).toDouble();
        duration = (args[1] as num).toDouble();
        if (args.length >= 3) {
          volume = (args[2] as num).toInt();
        }
        onProgressSync?.call(position, duration, volume);
      },
    );

    controller.addJavaScriptHandler(
      handlerName: 'onVideoError',
      callback: (args) {
        state = TvPlayerState.error;
        notifyListeners();
        onVideoError?.call(args[0].toString());
      },
    );
  }

  /// Phát video mới
  Future<void> loadVideo(String videoId, {String? title}) async {
    currentVideoId = videoId;
    currentTitle = title;
    state = TvPlayerState.loading;
    notifyListeners();

    await _webController?.evaluateJavascript(source: "loadVideo('$videoId')");
  }

  Future<void> pause() async {
    await _webController?.evaluateJavascript(source: "pauseVideo()");
  }

  Future<void> resume() async {
    await _webController?.evaluateJavascript(source: "playVideo()");
  }

  Future<void> seekForward([int seconds = 10]) async {
    await _webController?.evaluateJavascript(source: "seekForward($seconds)");
  }

  Future<void> seekBackward([int seconds = 10]) async {
    await _webController?.evaluateJavascript(source: "seekBackward($seconds)");
  }

  Future<void> increaseVolume() async {
    await _webController?.evaluateJavascript(source: "volumeUpStep()");
  }

  Future<void> decreaseVolume() async {
    await _webController?.evaluateJavascript(source: "volumeDownStep()");
  }

  Future<void> setVolume(int level) async {
    await _webController?.evaluateJavascript(
        source: "setVolumeLevel($level)");
  }

  TvPlayerState _mapState(String name) {
    switch (name) {
      case 'playing':   return TvPlayerState.playing;
      case 'paused':    return TvPlayerState.paused;
      case 'ended':     return TvPlayerState.ended;
      case 'buffering': return TvPlayerState.loading;
      default:          return TvPlayerState.idle;
    }
  }

  // === Callbacks ===
  VoidCallback? onVideoEnded;
  /// Callback trả về (position, duration, volume)
  Function(double position, double duration, int volume)? onProgressSync;
  Function(String errorCode)? onVideoError;
}
