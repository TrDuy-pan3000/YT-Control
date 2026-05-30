import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/song.dart';

class PlaybackControls extends StatelessWidget {
  final Song? currentSong;
  final bool isPlaying;
  final bool isConnected;
  final double position;   // in seconds
  final double duration;   // in seconds
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;

  const PlaybackControls({
    Key? key,
    required this.currentSong,
    required this.isPlaying,
    required this.isConnected,
    required this.position,
    required this.duration,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeekForward,
    required this.onSeekBackward,
  }) : super(key: key);

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';
    final int sec = seconds.round();
    final int min = sec ~/ 60;
    final int remainingSec = sec % 60;
    
    final minStr = min.toString().padLeft(2, '0');
    final secStr = remainingSec.toString().padLeft(2, '0');
    return '$minStr:$secStr';
  }

  @override
  Widget build(BuildContext context) {
    final bool active = isConnected && currentSong != null;
    final double progress = (duration > 0) ? (position / duration) : 0.0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 28.0),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10.0,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Opacity(
        opacity: active ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Track Info
            Text(
              currentSong?.title ?? 'Chưa phát bài hát nào',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4.0),
            Text(
              currentSong?.channelName ?? 'Đang chờ kết nối Tivi...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16.0),
            
            // Progress Bar
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(position),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0),
                    ),
                    Text(
                      _formatTime(duration),
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12.0),

            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Skip Previous
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 28, color: AppColors.textPrimary),
                  onPressed: active ? onPrevious : null,
                  splashRadius: 24,
                ),
                
                // Rewind 10s
                IconButton(
                  icon: const Icon(Icons.replay_10, size: 28, color: AppColors.textPrimary),
                  onPressed: active ? onSeekBackward : null,
                  splashRadius: 24,
                ),

                // Large Play/Pause
                GestureDetector(
                  onTap: active ? onPlayPause : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.surfaceLight,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ]
                          : [],
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),

                // Fast Forward 10s
                IconButton(
                  icon: const Icon(Icons.forward_10, size: 28, color: AppColors.textPrimary),
                  onPressed: active ? onSeekForward : null,
                  splashRadius: 24,
                ),

                // Skip Next
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 28, color: AppColors.textPrimary),
                  onPressed: active ? onNext : null,
                  splashRadius: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
