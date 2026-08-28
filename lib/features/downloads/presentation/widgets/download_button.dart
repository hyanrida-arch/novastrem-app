import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/content_type.dart';
import '../../domain/entities/download_task_entity.dart';
import '../providers/downloads_provider.dart';

/// Download/status icon reused on Movie details and Series episode rows.
/// Shows a progress ring while downloading, a checkmark once complete
/// (tap to open in the Download Manager), and a plain download icon
/// otherwise (tap to start).
class DownloadButton extends ConsumerWidget {
  final ContentType type;
  final int id;
  final String title;
  final String sourceUrl;
  final String? imageUrl;
  final String containerExtension;

  const DownloadButton({
    super.key,
    required this.type,
    required this.id,
    required this.title,
    required this.sourceUrl,
    this.imageUrl,
    this.containerExtension = 'mp4',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(downloadsControllerProvider); // rebuild as progress updates
    final controller = ref.read(downloadsControllerProvider.notifier);
    final task = controller.taskFor(type, id);

    if (task != null && task.status == DownloadStatus.downloading) {
      return IconButton(
        tooltip: 'Downloading… (${(task.progress * 100).toStringAsFixed(0)}%) — tap to cancel',
        icon: SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: task.totalBytes > 0 ? task.progress : null,
                strokeWidth: 2,
                color: AppColors.primary,
              ),
              const Icon(Icons.close_rounded, size: 12),
            ],
          ),
        ),
        onPressed: () => controller.cancel(task.key),
      );
    }

    if (task != null && task.status == DownloadStatus.completed) {
      return const IconButton(
        icon: Icon(Icons.download_done_rounded, color: AppColors.success),
        tooltip: 'Downloaded',
        onPressed: null, // already saved offline; manage/delete from Downloads screen
      );
    }

    return IconButton(
      icon: Icon(
        task?.status == DownloadStatus.failed ? Icons.error_outline_rounded : Icons.download_rounded,
        color: task?.status == DownloadStatus.failed ? AppColors.error : Colors.white,
      ),
      tooltip: task?.status == DownloadStatus.failed ? 'Download failed — tap to retry' : 'Download for offline',
      onPressed: () => controller.start(
        type: type,
        id: id,
        title: title,
        sourceUrl: sourceUrl,
        imageUrl: imageUrl,
        ext: containerExtension,
      ),
    );
  }
}
