import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/entities/history_entry_entity.dart';
import '../providers/history_provider.dart';

/// Full Watch History list — tap an entry to resume it, or clear
/// individual entries / the whole list.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyControllerProvider);

    return GlassScaffold(
      title: const Text('Watch History'),
      actions: [
        if (history.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all',
            onPressed: () => _confirmClearAll(context, ref),
          ),
      ],
      // The list below sets no `padding`, so it picks up GlassScaffold's
      // top inset automatically.
      body: history.isEmpty
          ? const EmptyView(message: 'Nothing watched yet.', icon: Icons.history_rounded)
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final entry = history[index];
                return _HistoryTile(
                  entry: entry,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PlayerScreen(
                        streamUrl: entry.streamUrl,
                        title: entry.title,
                        isLive: entry.type == ContentType.live,
                        contentType: entry.type,
                        contentId: entry.id,
                        imageUrl: entry.imageUrl,
                        startPositionMs: entry.isResumable ? entry.positionMs : 0,
                      ),
                    ),
                  ),
                  onRemove: () => ref.read(historyControllerProvider.notifier).remove(entry.type, entry.id),
                );
              },
            ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Watch History'),
        content: const Text('This removes every entry, including saved resume positions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(historyControllerProvider.notifier).clear();
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntryEntity entry;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _HistoryTile({required this.entry, required this.onTap, required this.onRemove});

  IconData get _typeIcon {
    switch (entry.type) {
      case ContentType.live:
        return Icons.live_tv_rounded;
      case ContentType.movie:
        return Icons.movie_rounded;
      case ContentType.series:
        return Icons.video_library_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: (entry.imageUrl == null || entry.imageUrl!.isEmpty)
              ? ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Icon(_typeIcon, color: AppColors.textSecondary),
                )
              : CachedNetworkImage(
                  imageUrl: entry.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) =>
                      ColoredBox(color: AppColors.surfaceElevated, child: Icon(_typeIcon)),
                ),
        ),
      ),
      title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: entry.progress > 0
          ? Padding(
              padding: const EdgeInsets.only(top: 6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: entry.progress,
                  minHeight: 3,
                  backgroundColor: AppColors.surfaceElevated,
                  color: AppColors.primary,
                ),
              ),
            )
          : null,
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
        onPressed: onRemove,
      ),
    );
  }
}
