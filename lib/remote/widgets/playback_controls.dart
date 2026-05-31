import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/song.dart';

class PlaybackControls extends StatefulWidget {
  final Song? currentSong;
  final bool isPlaying;
  final bool isConnected;
  final double position;    // in seconds
  final double duration;    // in seconds
  final int volume;         // 0-100
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onVolumeUp;
  final VoidCallback onVolumeDown;
  final ValueChanged<double> onVolumeChanged;
  final ValueChanged<double>? onSeekTo;

  const PlaybackControls({
    Key? key,
    required this.currentSong,
    required this.isPlaying,
    required this.isConnected,
    required this.position,
    required this.duration,
    required this.volume,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onVolumeUp,
    required this.onVolumeDown,
    required this.onVolumeChanged,
    this.onSeekTo,
  }) : super(key: key);

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  String _formatTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite) return '00:00';
    final int sec = seconds.round();
    final int min = sec ~/ 60;
    final int remainingSec = sec % 60;
    return '${min.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final bool active = widget.isConnected && widget.currentSong != null;
    final double duration = widget.duration;
    
    // Lấy giá trị trượt cục bộ khi kéo thả, nếu không lấy giá trị đồng bộ từ TV
    final double displayPos = _isDragging ? _dragValue : widget.position;
    final double clampedPos = displayPos.clamp(0.0, duration > 0 ? duration : 0.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(20.0, 14.0, 20.0, 24.0),
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
              widget.currentSong?.title ?? 'Chưa phát bài hát nào',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3.0),
            Text(
              widget.currentSong?.channelName ?? 'Đang chờ kết nối Tivi...',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12.0,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12.0),

            // ─── Volume Control Row ───
            Row(
              children: [
                // Volume icon + giá trị
                GestureDetector(
                  onTap: active ? widget.onVolumeDown : null,
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      widget.volume == 0
                          ? Icons.volume_off
                          : widget.volume < 50
                              ? Icons.volume_down
                              : Icons.volume_up,
                      color: active
                          ? AppColors.accent
                          : AppColors.textMuted,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Slider âm lượng
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 14.0),
                      trackHeight: 4.0,
                      activeTrackColor: AppColors.accent,
                      inactiveTrackColor: AppColors.surfaceLight,
                      thumbColor: AppColors.accent,
                      overlayColor: AppColors.accent.withValues(alpha: 0.2),
                    ),
                    child: Slider(
                      value: widget.volume.toDouble().clamp(0.0, 100.0),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      onChanged: active ? widget.onVolumeChanged : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),

                // Nút Volume Up + hiện %
                GestureDetector(
                  onTap: active ? widget.onVolumeUp : null,
                  child: Container(
                    padding: const EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 6.0),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${widget.volume}%',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11.0,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),

            // ─── Progress Bar (Interactive Slider) ───
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                    trackHeight: 4.0,
                    activeTrackColor: AppColors.primary,
                    inactiveTrackColor: AppColors.surfaceLight,
                    thumbColor: AppColors.primaryLight,
                    overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    value: clampedPos,
                    min: 0.0,
                    max: duration > 0 ? duration : 0.0,
                    onChanged: active
                        ? (val) {
                            setState(() {
                              _isDragging = true;
                              _dragValue = val;
                            });
                          }
                        : null,
                    onChangeEnd: active
                        ? (val) {
                            widget.onSeekTo?.call(val);
                            setState(() {
                              _isDragging = false;
                            });
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 2.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(clampedPos),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11.0),
                    ),
                    Text(
                      _formatTime(duration),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11.0),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10.0),

            // ─── Playback Controls ───
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous,
                      size: 28, color: AppColors.textPrimary),
                  onPressed: active ? widget.onPrevious : null,
                  splashRadius: 24,
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10,
                      size: 28, color: AppColors.textPrimary),
                  onPressed: active ? widget.onSeekBackward : null,
                  splashRadius: 24,
                ),

                // Large Play/Pause button
                GestureDetector(
                  onTap: active ? widget.onPlayPause : null,
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.surfaceLight,
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
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.forward_10,
                      size: 28, color: AppColors.textPrimary),
                  onPressed: active ? widget.onSeekForward : null,
                  splashRadius: 24,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next,
                      size: 28, color: AppColors.textPrimary),
                  onPressed: active ? widget.onNext : null,
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
