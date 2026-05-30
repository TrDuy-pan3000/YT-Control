import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/models/song.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

enum SearchResultsState { idle, loading, success, empty, error }

class SearchResultsWidget extends StatelessWidget {
  final List<Song> results;
  final SearchResultsState state;
  final Function(Song song) onAddToQueue;

  const SearchResultsWidget({
    Key? key,
    required this.results,
    required this.state,
    required this.onAddToQueue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case SearchResultsState.idle:
        return const Center(
          child: Text(
            'Nhập từ khóa để tìm kiếm bài hát Karaoke',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
      case SearchResultsState.loading:
        return _buildShimmerLoading();
      case SearchResultsState.empty:
        return _buildStatusView(
          icon: Icons.search_off_outlined,
          message: AppStrings.noResults,
        );
      case SearchResultsState.error:
        return _buildStatusView(
          icon: Icons.error_outline_outlined,
          message: AppStrings.retrySearch,
          color: AppColors.error,
        );
      case SearchResultsState.success:
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: results.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12.0),
          itemBuilder: (context, index) {
            final song = results[index];
            return _buildSongItem(context, song);
          },
        );
    }
  }

  Widget _buildSongItem(BuildContext context, Song song) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.surfaceLight.withValues(alpha: 0.5), width: 1.0),
      ),
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: CachedNetworkImage(
              imageUrl: song.thumbnailUrl,
              width: 120,
              height: 68,
              fit: BoxFit.cover,
              placeholder: (context, url) => Shimmer.fromColors(
                baseColor: AppColors.surfaceLight,
                highlightColor: AppColors.surface,
                child: Container(color: Colors.white, width: 120, height: 68),
              ),
              errorWidget: (context, url, error) => Container(
                color: AppColors.surfaceLight,
                width: 120,
                height: 68,
                child: const Icon(Icons.music_video, color: AppColors.textMuted),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          // Metadata
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '${song.channelName} · ${song.duration}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.0,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          // Add Button
          GestureDetector(
            onTap: () => onAddToQueue(song),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.white, size: 16),
                  SizedBox(width: 2.0),
                  Text(
                    'Chọn',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.separated(
      padding: const EdgeInsets.all(16.0),
      itemCount: 5,
      separatorBuilder: (context, index) => const SizedBox(height: 12.0),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surface,
          highlightColor: AppColors.surfaceLight,
          child: Container(
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusView({
    required IconData icon,
    required String message,
    Color color = AppColors.textSecondary,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 16.0),
          Text(
            message,
            style: TextStyle(color: color, fontSize: 14.0),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
