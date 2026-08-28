import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../../features/downloads/presentation/screens/download_manager_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/search_screen.dart';

/// Search / Download / Notifications icon buttons carried by every tab's
/// AppBar. Profile and Settings deliberately live in the bottom nav's
/// "Menu" tab instead (see `menu_sheet.dart`) — they're settings-shaped
/// destinations, not per-screen actions, so the header stays reserved for
/// things you reach for while browsing.
List<Widget> commonAppBarActions(BuildContext context) {
  return [
    IconButton(
      icon: const Icon(Icons.search_rounded),
      tooltip: AppStrings.search,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SearchScreen()),
      ),
    ),
    IconButton(
      icon: const Icon(Icons.download_rounded),
      tooltip: AppStrings.downloads,
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DownloadManagerScreen()),
      ),
    ),
    const _NotificationsBell(),
  ];
}

/// Bell icon with an unread dot whenever there's anything in the
/// notifications inbox — driven by the same [buildNotificationItems] the
/// screen itself uses, so the badge can't drift out of sync with content.
class _NotificationsBell extends ConsumerWidget {
  const _NotificationsBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = buildNotificationItems(ref).isNotEmpty;

    return IconButton(
      tooltip: 'Notifications',
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
      ),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded),
          if (hasItems)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }
}
