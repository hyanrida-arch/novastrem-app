import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/utils/stream_url_resolver.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../downloads/presentation/widgets/download_button.dart';
import '../../../favorites/presentation/widgets/favorite_button.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/entities/episode_entity.dart';
import '../providers/series_provider.dart';

/// Series details page: cover/backdrop, title, rating, description, and a
/// per-season expandable list of playable episodes.
class SeriesDetailsScreen extends ConsumerWidget {
  final int seriesId;
  final String fallbackTitle;

  const SeriesDetailsScreen({super.key, required this.seriesId, required this.fallbackTitle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(seriesDetailsProvider(seriesId));

    return Scaffold(
      body: detailsAsync.when(
        loading: () => const LoadingView(),
        error: (err, _) => ErrorView(
          message: describeError(err),
          onRetry: () => ref.invalidate(seriesDetailsProvider(seriesId)),
        ),
        data: (series) {
          // Watch the list so episode rows relabel with "Resume" as soon as
          // playback progress is saved (e.g. after popping back from the
          // player).
          ref.watch(historyControllerProvider);
          final historyController = ref.read(historyControllerProvider.notifier);
          final seasons = series.episodesBySeason.keys.toList()..sort();

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 220,
                actions: [
                  FavoriteButton(
                    type: ContentType.series,
                    id: series.seriesId,
                    title: series.name.isEmpty ? fallbackTitle : series.name,
                    imageUrl: series.coverUrl,
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: (series.backdropUrl ?? series.coverUrl) == null
                      ? const ColoredBox(color: AppColors.surface)
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: (series.backdropUrl ?? series.coverUrl)!,
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
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.name.isEmpty ? fallbackTitle : series.name,
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 14,
                        runSpacing: 6,
                        children: [
                          if (series.rating > 0)
                            _MetaChip(icon: Icons.star_rounded, label: series.rating.toStringAsFixed(1)),
                          if (series.releaseDate.isNotEmpty)
                            _MetaChip(icon: Icons.calendar_today_rounded, label: series.releaseDate),
                          if (series.genre.isNotEmpty)
                            _MetaChip(icon: Icons.local_offer_rounded, label: series.genre),
                        ],
                      ),
                      if (series.description.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(
                          series.description,
                          style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                      if (series.cast.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Cast: ${series.cast}', style: const TextStyle(color: AppColors.textSecondary)),
                      ],
                      const SizedBox(height: 16),
                      const Text('Episodes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              if (seasons.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyView(message: 'No episodes available yet.', icon: Icons.playlist_remove_rounded),
                )
              else
                SliverList.list(
                  children: [
                    for (final season in seasons)
                      _SeasonExpansionTile(
                        season: season,
                        seriesName: series.name.isEmpty ? fallbackTitle : series.name,
                        coverUrl: series.coverUrl,
                        episodes: series.episodesBySeason[season]!,
                        resumePositionFor: (episodeId) =>
                            historyController.startPositionFor(ContentType.series, episodeId),
                        urlFor: (episode) =>
                            StreamUrlResolver.seriesEpisode(ref, episode.episodeId, ext: episode.containerExtension),
                        onPlay: (episode) {
                          final url = StreamUrlResolver.seriesEpisode(
                            ref,
                            episode.episodeId,
                            ext: episode.containerExtension,
                          );
                          if (url == null) return;

                          final resumeMs =
                              historyController.startPositionFor(ContentType.series, episode.episodeId);

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => PlayerScreen(
                                streamUrl: url,
                                title: '${series.name} · S${season}E${episode.episodeNum}',
                                contentType: ContentType.series,
                                contentId: episode.episodeId,
                                imageUrl: series.coverUrl,
                                startPositionMs: resumeMs,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _SeasonExpansionTile extends StatelessWidget {
  final int season;
  final String seriesName;
  final String? coverUrl;
  final List<EpisodeEntity> episodes;
  final ValueChanged<EpisodeEntity> onPlay;
  final int Function(int episodeId) resumePositionFor;
  final String? Function(EpisodeEntity episode) urlFor;

  const _SeasonExpansionTile({
    required this.season,
    required this.seriesName,
    required this.coverUrl,
    required this.episodes,
    required this.onPlay,
    required this.resumePositionFor,
    required this.urlFor,
  });

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text('Season $season', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${episodes.length} episodes'),
        children: [
          for (final episode in episodes)
            Builder(builder: (context) {
              final resumeMs = resumePositionFor(episode.episodeId);
              final url = urlFor(episode);
              return ListTile(
                leading: Icon(
                  resumeMs > 0 ? Icons.play_circle_fill_rounded : Icons.play_circle_outline_rounded,
                  color: AppColors.primary,
                ),
                title: Text('${episode.episodeNum}. ${episode.title}'),
                subtitle: resumeMs > 0
                    ? Text('Resume from ${_formatMs(resumeMs)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
                    : null,
                trailing: url == null
                    ? null
                    : DownloadButton(
                        type: ContentType.series,
                        id: episode.episodeId,
                        title: '$seriesName · S${season}E${episode.episodeNum}',
                        sourceUrl: url,
                        imageUrl: coverUrl,
                        containerExtension: episode.containerExtension,
                      ),
                onTap: () => onPlay(episode),
              );
            }),
        ],
      ),
    );
  }
}

String _formatMs(int ms) {
  final d = Duration(milliseconds: ms);
  final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$minutes:$seconds' : '$minutes:$seconds';
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
