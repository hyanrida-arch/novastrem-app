import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../player/presentation/screens/player_screen.dart';
import '../../domain/entities/download_task_entity.dart';
import '../providers/downloads_provider.dart';

/// Lists every offline download — in-progress (with a live progress bar +
/// cancel), completed (tap to play from disk, or delete to free space),
/// and failed (retry or delete).
class DownloadManagerScreen extends ConsumerWidget {
  const DownloadManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsControllerProvider);
    final controller = ref.read(downloadsControllerProvider.notifier);

    final totalBytes = downloads
        .where((t) => t.status == DownloadStatus.completed)
        .fold<int>(0, (sum, t) => sum + t.totalBytes);

    return GlassScaffold(
      title: const Text('Downloads'),
      bottom: downloads.isEmpty
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(28),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${downloads.length} download${downloads.length == 1 ? '' : 's'} · ${_formatBytes(totalBytes)} used',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                ),
              ),
            ),
      // The list sets no `padding`, so GlassScaffold's inset (which already
      // accounts for the `bottom` strip above) applies automatically.
      body: downloads.isEmpty
          ? const EmptyView(
              message: 'No downloads yet. Tap the download icon on a movie or\nepisode to save it for offline viewing.',
              icon: Icons.download_for_offline_outlined,
            )
          : ListView.separated(
              itemCount: downloads.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) => _DownloadTile(task: downloads[index], controller: controller),
            ),
    );
  }
}

class _DownloadTile extends StatelessWidget {
  final DownloadTaskEntity task;
  final DownloadsController controller;

  const _DownloadTile({required this.task, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 48,
          height: 48,
          child: (task.imageUrl == null || task.imageUrl!.isEmpty)
              ? const ColoredBox(
                  color: AppColors.surfaceElevated,
                  child: Icon(Icons.movie_creation_outlined, color: AppColors.textSecondary),
                )
              : CachedNetworkImage(imageUrl: task.imageUrl!, fit: BoxFit.cover),
        ),
      ),
      title: Text(task.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: _buildSubtitle(),
      trailing: _buildTrailing(context),
      onTap: task.status == DownloadStatus.completed
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PlayerScreen(
                    streamUrl: task.localPath!,
                    title: task.title,
                    isLocalFile: true,
                    contentType: task.type,
                    contentId: task.id,
                    imageUrl: task.imageUrl,
                  ),
                ),
              )
          : null,
    );
  }

  Widget? _buildSubtitle() {
    switch (task.status) {
      case DownloadStatus.downloading:
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.totalBytes > 0 ? task.progress : null,
              minHeight: 4,
              backgroundColor: AppColors.surfaceElevated,
              color: AppColors.primary,
            ),
          ),
        );
      case DownloadStatus.completed:
        return Text(_formatBytes(task.totalBytes), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12));
      case DownloadStatus.failed:
        return const Text('Failed — tap retry', style: TextStyle(color: AppColors.error, fontSize: 12));
      case DownloadStatus.canceled:
        return const Text('Canceled', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
      case DownloadStatus.queued:
        return const Text('Queued…', style: TextStyle(color: AppColors.textSecondary, fontSize: 12));
    }
  }

  Widget _buildTrailing(BuildContext context) {
    if (task.status == DownloadStatus.downloading) {
      return IconButton(
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Cancel',
        onPressed: () => controller.cancel(task.key),
      );
    }
    if (task.status == DownloadStatus.failed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Retry',
            onPressed: () => controller.start(
              type: task.type,
              id: task.id,
              title: task.title,
              sourceUrl: task.sourceUrl,
              imageUrl: task.imageUrl,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => controller.delete(task),
          ),
        ],
      );
    }
    return IconButton(
      icon: const Icon(Icons.delete_outline_rounded),
      tooltip: 'Delete',
      onPressed: () => controller.delete(task),
    );
  }
}

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 MB';
  final mb = bytes / (1024 * 1024);
  if (mb < 1024) return '${mb.toStringAsFixed(1)} MB';
  return '${(mb / 1024).toStringAsFixed(2)} GB';
}
