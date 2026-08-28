import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../favorites/presentation/screens/favorites_screen.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../settings/presentation/screens/settings_screen.dart';

/// The bottom sheet behind the nav bar's "Menu" tab — the new home for
/// Profile and Settings after they moved out of the top app bar, plus the
/// other account-level destinations that don't warrant their own tab.
class MenuSheet extends StatelessWidget {
  const MenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const MenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Menu', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
              ),
            ),
            _MenuTile(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              subtitle: 'Account details & sign out',
              builder: (_) => const ProfileScreen(),
            ),
            _MenuTile(
              icon: Icons.settings_outlined,
              label: AppStrings.sectionSettings,
              subtitle: 'Playlists, player, parental control',
              builder: (_) => const SettingsScreen(),
            ),
            // "My List" and "Favorites" are one and the same collection in
            // NovaStream — the hero banner's "+ My List" button and the
            // heart toggles on cards both write to the same store — so this
            // is deliberately a single entry rather than two rows opening
            // identical content. See `favorites_screen.dart`.
            _MenuTile(
              icon: Icons.favorite_border_rounded,
              label: 'My List',
              subtitle: 'Your favorite movies, series & channels',
              builder: (_) => const FavoritesScreen(),
            ),
            // Downloads deliberately omitted — it already has a permanent
            // download icon in every screen's app bar, so a second entry
            // here was redundant.
            _MenuTile(
              icon: Icons.history_rounded,
              label: 'Watch History',
              subtitle: 'Pick up where you left off',
              builder: (_) => const HistoryScreen(),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final WidgetBuilder builder;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
      onTap: () {
        // Close the sheet first so the pushed screen's back button returns
        // to the tab the user was browsing, not to a lingering sheet.
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(builder: builder));
      },
    );
  }
}
