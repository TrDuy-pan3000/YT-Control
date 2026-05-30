import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/song.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

class QueueListWidget extends StatelessWidget {
  final List<Song> queue;
  final int currentIndex;
  final Function(int oldIndex, int newIndex) onReorder;
  final Function(int index) onRemove;
  final Function(int index)? onTapSong;

  const QueueListWidget({
    Key? key,
    required this.queue,
    required this.currentIndex,
    required this.onReorder,
    required this.onRemove,
    this.onTapSong,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.queue_music_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
            const SizedBox(height: 16.0),
            const Text(
              AppStrings.queueEmpty,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14.0),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: queue.length,
      onReorder: onReorder,
      itemBuilder: (context, index) {
        final song = queue[index];
        final isCurrent = index == currentIndex;

        return Dismissible(
          key: ValueKey('dismiss_${song.videoId}_$index'),
          direction: DismissDirection.endToStart,
          onDismissed: (direction) => onRemove(index),
          background: Container(
            margin: const EdgeInsets.only(bottom: 12.0),
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            alignment: Alignment.centerRight,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: Container(
            key: ValueKey('song_${song.videoId}_$index'),
            margin: const EdgeInsets.only(bottom: 12.0),
            decoration: BoxDecoration(
              color: isCurrent ? AppColors.surfaceLight : AppColors.surface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: isCurrent ? AppColors.accent : AppColors.surfaceLight.withValues(alpha: 0.3),
                width: isCurrent ? 1.5 : 1.0,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
              onTap: () => onTapSong?.call(index),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reorder handle indicator
                  const Icon(Icons.drag_indicator, color: AppColors.textMuted, size: 20),
                  const SizedBox(width: 8.0),
                  // Numbering or Active Indicator
                  Container(
                    width: 24,
                    alignment: Alignment.center,
                    child: isCurrent
                        ? const Icon(Icons.volume_up, color: AppColors.accent, size: 18)
                        : Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: CachedNetworkImage(
                      imageUrl: song.thumbnailUrl,
                      width: 64,
                      height: 36,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: AppColors.surfaceLight,
                        width: 64,
                        height: 36,
                        child: const Icon(Icons.music_video, color: AppColors.textMuted, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          song.title,
                          style: TextStyle(
                            color: isCurrent ? AppColors.textPrimary : AppColors.textSecondary,
                            fontSize: 14.0,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          song.channelName,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11.0),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.duration,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12.0),
                  ),
                  const SizedBox(width: 4.0),
                  if (isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Text(
                        'ĐANG PHÁT',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 9.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
