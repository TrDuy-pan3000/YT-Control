abstract class WsProtocol {
  static const int port = 8080;
  static const String serviceType = '_karaoke-receiver._tcp';
  static const String serviceName = 'YT Karaoke TV';

  // Actions (Remote → TV)
  static const String playNow = 'play_now';
  static const String pause = 'pause';
  static const String resume = 'resume';
  static const String seekForward = 'seek_forward';
  static const String seekBackward = 'seek_backward';
  static const String next = 'next';
  static const String volumeUp = 'volume_up';
  static const String volumeDown = 'volume_down';
  static const String setVolume = 'set_volume';
  static const String seekTo = 'seek_to';

  // Events (TV → Remote)
  static const String videoEnded = 'video_ended';
  static const String videoError = 'video_error';
  static const String connected = 'connected';

  // Sync (TV → Remote)
  static const String playerState = 'player_state';
}
