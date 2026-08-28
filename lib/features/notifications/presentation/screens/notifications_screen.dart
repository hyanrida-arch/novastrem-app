import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/widgets/state_views.dart';
import '../../../downloads/domain/entities/download_task_entity.dart';
import '../../../downloads/presentation/providers/downloads_provider.dart';
import '../../../downloads/presentation/screens/download_manager_screen.dart';
import '../../../history/presentation/providers/history_provider.dart';

/// Notifications inbox behind the header's bell icon.
///
/// Xtream Codes has no push/notification API, so rather than fake a feed,
/// this surfaces genuinely useful local events the app already knows
/// about — finished and failed downloads, and a "keep watching" nudge for
/// the most recent unfinished title. Wire a real push provider (FCM, etc.)
/// in later by prepending its messages to [_buildItems].
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = buildNotificationItems(ref);

    return GlassScaffold(
      title: const Text('Notifications'),
      body: items.isEmpty
          ? const EmptyView(
              message: "You're all caught up.\nDownload or watch something to see updates here.",
              icon: Icons.notifications_none_rounded,
            )
          // Builder so `MediaQuery.paddingOf` sees GlassScaffold's injected
          // top inset — this list sets its own padding, which would
          // otherwise override it and hide the first row under the bar.
          : Builder(
              builder: (context) => ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8)
                  .copyWith(top: MediaQuery.paddingOf(context).top + 8),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 68),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: item.color.withValues(alpha: 0.15),
                    child: Icon(item.icon, color: item.color, size: 20),
                  ),
                  title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                  subtitle: Text(
                    item.subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                  ),
                  onTap: item.onTap == null ? null : () => item.onTap!(context),
                );
                },
              ),
            ),
    );
  }
}

class NotificationItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final void Function(BuildContext context)? onTap;

  const NotificationItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    this.onTap,
  });
}

/// Shared by [NotificationsScreen] and the header bell's unread dot, so
/// "is there anything to show?" is answered by exactly one piece of logic.
List<NotificationItem> buildNotificationItems(WidgetRef ref) {
  final downloads = ref.watch(downloadsControllerProvider);
  final history = ref.watch(historyControllerProvider);
  final dateFormat = DateFormat('dd MMM, HH:mm');

  return [
    for (final task in downloads.where((t) => t.status == DownloadStatus.completed))
      NotificationItem(
        icon: Icons.download_done_rounded,
        color: AppColors.success,
        title: 'Download complete',
        subtitle: '${task.title} · ${dateFormat.format(task.createdAt)}',
        onTap: (context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DownloadManagerScreen()),
        ),
      ),
    for (final task in downloads.where((t) => t.status == DownloadStatus.failed))
      NotificationItem(
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
        title: 'Download failed',
        subtitle: '${task.title} · tap to retry',
        onTap: (context) => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DownloadManagerScreen()),
        ),
      ),
    ...history.where((e) => e.isResumable).take(1).map(
          (entry) => NotificationItem(
            icon: Icons.play_circle_outline_rounded,
            color: AppColors.primary,
            title: 'Continue watching',
            subtitle: '${entry.title} · ${(entry.progress * 100).toStringAsFixed(0)}% watched',
          ),
        ),
  ];
}
