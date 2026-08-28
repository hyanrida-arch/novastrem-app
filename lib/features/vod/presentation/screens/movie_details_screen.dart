import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../downloads/presentation/widgets/download_button.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../providers/vod_provider.dart';

/// Movie details page: poster/backdrop, title, rating, description and a
/// Play button that launches [PlayerScreen].
class MovieDetailsScreen extends ConsumerWidget {
  final int vodId;
  final String fallbackTitle;

  const MovieDetailsScreen({super.key, required this.vodId, required this.fallbackTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(movieDetailsProvider(vodId));

    return Scaffold(
      body: detailsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: describeError(err),
          onRetry: () => ref.invalidate(movieDetailsProvider(vodId)),
        ),
        data: (movie) {
          // Watch the list (not just `.notifier`) so the Play/Resume button
          // relabels as soon as playback progress is saved — e.g. right
          // after popping back from the player.
          ref.watch(historyControllerProvider);
          final resumeMs = ref
              .read(historyControllerProvider.notifier)
              .startPositionFor(ContentType.movie, movie.streamId);
          final playbackUrl = StreamUrlResolver.vod(ref, movie.streamId, ext: movie.containerExtension);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                actions: [
                  if (playbackUrl != null)
                    DownloadButton(
                      type: ContentType.movie,
                      id: movie.streamId,
                      title: movie.name.isEmpty ? fallbackTitle : movie.name,
                      sourceUrl: playbackUrl,
                      imageUrl: movie.posterUrl,
                      containerExtension: movie.containerExtension,
                    ),
                  FavoriteButton(
                    type: ContentType.movie,
                    id: movie.streamId,
                    title: movie.name.isEmpty ? fallbackTitle : movie.name,
                    imageUrl: movie.posterUrl,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: (movie.backdropUrl ?? movie.posterUrl) == null
                      ? const ColoredBox(color: AppColors.surface)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: (movie.backdropUrl ?? movie.posterUrl)!,
                              fit: BoxFit.cover,
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, AppColors.background],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.name.isEmpty ? fallbackTitle : movie.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          if (movie.rating > 0)
                            _MetaChip(icon: Icons.star_rounded, label: movie.rating.toStringAsFixed(1)),
                          if (movie.releaseDate.isNotEmpty)
                            _MetaChip(icon: Icons.calendar_today_rounded, label: movie.releaseDate),
                          if (movie.duration.isNotEmpty)
                            _MetaChip(icon: Icons.schedule_rounded, label: movie.duration),
                          if (movie.genre.isNotEmpty)
                            _MetaChip(icon: Icons.local_offer_rounded, label: movie.genre),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(
                            resumeMs > 0 ? Icons.play_circle_fill_rounded : Icons.play_arrow_rounded,
                          ),
                          label: Text(resumeMs > 0 ? 'Resume' : AppStrings.play),
                          onPressed: () {
                            if (playbackUrl == null) return;

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlayerScreen(
                                  streamUrl: playbackUrl,
                                  title: movie.name.isEmpty ? fallbackTitle : movie.name,
                                  contentType: ContentType.movie,
                                  contentId: movie.streamId,
                                  imageUrl: movie.posterUrl,
                                  startPositionMs: resumeMs,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (movie.description.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text('Overview', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                          movie.description,
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                      if (movie.cast.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text('Cast: ${movie.cast}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      if (movie.director.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text('Director: ${movie.director}',
                            style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}
