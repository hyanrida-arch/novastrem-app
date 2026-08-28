import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../live_tv/presentation/screens/live_tv_screen.dart';
import '../../../series/presentation/screens/series_screen.dart';
import '../../../vod/presentation/screens/movies_screen.dart';
import '../widgets/menu_sheet.dart';

/// App shell: bottom navigation across the four content sections plus a
/// "Menu" entry. Each content tab (Home/Live TV/Movies/Series) owns its
/// own `Scaffold` + glass `SliverAppBar` — see `glass_surface.dart` —
/// rather than sharing one flat bar here, so content can scroll behind it
/// and each screen can add its own AppBar actions (e.g. the Filter icon).
///
/// `extendBody: true` lets each tab's scrollable content run underneath
/// the translucent, blurred bottom nav instead of stopping above it —
/// that's what makes the `BackdropFilter` glass effect actually visible.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    LiveTvScreen(),
    MoviesScreen(),
    SeriesScreen(),
  ];

  /// Index of the trailing "Menu" item — it isn't a real page, so tapping
  /// it opens [MenuSheet] and leaves the current tab selected instead of
  /// navigating (there's no 5th entry in [_screens] by design).
  static const _menuIndex = 4;

  void _onTap(int index) {
    if (index == _menuIndex) {
      MenuSheet.show(context);
      return;
    }
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: GlassBottomNav(
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTap,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: AppStrings.sectionHome),
            BottomNavigationBarItem(icon: Icon(Icons.live_tv_rounded), label: AppStrings.sectionLiveTv),
            BottomNavigationBarItem(icon: Icon(Icons.movie_rounded), label: AppStrings.sectionMovies),
            BottomNavigationBarItem(icon: Icon(Icons.video_library_rounded), label: AppStrings.sectionSeries),
            BottomNavigationBarItem(icon: Icon(Icons.more_vert_rounded), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}
