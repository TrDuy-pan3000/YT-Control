class Song {
  final String videoId;
  final String title;
  final String thumbnailUrl;
  final String duration;       // Định dạng "mm:ss"
  final String channelName;

  const Song({
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.duration,
    required this.channelName,
  });

  Map<String, dynamic> toJson() => {
    'videoId': videoId,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'duration': duration,
    'channelName': channelName,
  };

  factory Song.fromJson(Map<String, dynamic> json) => Song(
    videoId: json['videoId'] as String,
    title: json['title'] as String,
    thumbnailUrl: json['thumbnailUrl'] as String,
    duration: json['duration'] as String,
    channelName: json['channelName'] as String,
  );
}
