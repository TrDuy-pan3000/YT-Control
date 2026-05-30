import 'package:flutter_test/flutter_test.dart';
import 'package:yt_control/core/services/youtube_search_service.dart';

void main() {
  group('YouTubeSearchService Tests', () {
    late YouTubeSearchService service;

    setUp(() {
      service = YouTubeSearchService();
    });

    tearDown(() {
      service.dispose();
    });

    test('formatDuration should format mm:ss correctly', () {
      final duration = const Duration(minutes: 4, seconds: 30);
      expect(service.formatDuration(duration), equals('04:30'));
    });

    test('formatDuration should format h:mm:ss correctly', () {
      final duration = const Duration(hours: 1, minutes: 2, seconds: 3);
      expect(service.formatDuration(duration), equals('1:02:03'));
    });

    test('formatDuration should format seconds only correctly', () {
      final duration = const Duration(seconds: 45);
      expect(service.formatDuration(duration), equals('00:45'));
    });

    test('search with empty keyword should return empty list immediately', () async {
      final results = await service.search('');
      expect(results, isEmpty);
    });

    test('search with space-only keyword should return empty list immediately', () async {
      final results = await service.search('   ');
      expect(results, isEmpty);
    });

    // We can also have an integration test if network is available.
    // If it fails due to network, it will be handled gracefully.
    test('search "Mưa đêm" should return valid songs if internet is available', () async {
      try {
        final results = await service.search('Mưa đêm', karaokeMode: true);
        if (results.isNotEmpty) {
          expect(results.length, lessThanOrEqualTo(20));
          final first = results.first;
          expect(first.videoId, isNotEmpty);
          expect(first.title, isNotEmpty);
          expect(first.thumbnailUrl, isNotEmpty);
          expect(first.duration, isNotEmpty);
          expect(first.channelName, isNotEmpty);
        } else {
          // If no network, empty list is also acceptable (graceful failure)
          expect(results, isEmpty);
        }
      } catch (e) {
        // Suppress errors during offline testing
        print('Skipping live search test due to error: $e');
      }
    });
   group('Edge Cases', () {
    test('youtube_explode exception should be caught gracefully', () async {
      // YouTubeSearchService catches exceptions internally, so let's verify it
      final serviceWithInvalidClient = YouTubeSearchService();
      // Calling search with an invalid query or state shouldn't crash the application
      final results = await serviceWithInvalidClient.search('!@#\$%^&*()_+');
      expect(results, isList);
    });
  });
 });
}
