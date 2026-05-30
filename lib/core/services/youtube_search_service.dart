import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../models/song.dart';

class YouTubeSearchService {
  YoutubeExplode? _yt;

  YoutubeExplode get _client {
    _yt ??= YoutubeExplode();
    return _yt!;
  }

  /// Tìm kiếm bài hát.
  /// [karaokeMode] = true → tự động append " karaoke" vào keyword.
  /// Trả về danh sách tối đa 20 kết quả.
  Future<List<Song>> search(String keyword, {bool karaokeMode = true}) async {
    if (keyword.trim().isEmpty) return [];

    final query = karaokeMode ? '${keyword.trim()} karaoke' : keyword.trim();

    try {
      final results = await _client.search.search(query);

      return results
          .where((v) => v.duration != null)  // Loại bỏ livestream
          .take(20)
          .map((video) => Song(
                videoId: video.id.value,
                title: video.title,
                thumbnailUrl: video.thumbnails.highResUrl,
                duration: formatDuration(video.duration!),
                channelName: video.author,
              ))
          .toList();
    } catch (e) {
      // youtube_explode_dart lỗi hoặc mất mạng
      // Không crash app, trả về danh sách rỗng
      return [];
    }
  }

  /// Format Duration thành "mm:ss" hoặc "h:mm:ss"
  String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      final hours = d.inHours;
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  void dispose() {
    _yt?.close();
    _yt = null;
  }
}
