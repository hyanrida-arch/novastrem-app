import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Frosted-glass container: blurs whatever scrolls behind it and tints it
/// with a translucent surface color. Used for the app's AppBars and bottom
/// navigation so content visibly scrolls *under* them instead of being
/// hidden behind a flat, opaque bar.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final Color tint;
  final BorderRadius? borderRadius;
  final Border? border;

  const GlassSurface({
    super.key,
    required this.child,
    this.blurSigma = 18,
    this.tint = const Color(0xCC12151B),
    this.borderRadius,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: DecoratedBox(
          decoration: BoxDecoration(color: tint, border: border),
          child: child,
        ),
      ),
    );
  }
}

/// A [PreferredSizeWidget] AppBar with the glass treatment baked in — drop-in
/// replacement anywhere a flat `AppBar` was used, for screens that scroll
/// content behind it (wrap the `Scaffold.body` in a `Stack`/`CustomScrollView`
/// with `extendBodyBehindAppBar`-style layering).
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;

  const GlassAppBar({super.key, this.title, this.actions, this.leading, this.bottom});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      border: const Border(bottom: BorderSide(color: Colors.white10, width: 0.6)),
      child: AppBar(
        title: title,
        actions: actions,
        leading: leading,
        bottom: bottom,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// A [Scaffold] whose app bar is frosted glass and whose body scrolls
/// *behind* it — the same treatment the main tabs get from
/// [GlassSliverAppBar], for screens that use a plain box body instead of a
/// `CustomScrollView`.
///
/// The subtlety this exists to solve: `extendBodyBehindAppBar: true` makes
/// the body start at y=0, and Flutter's `Scaffold` also zeroes the body's
/// `MediaQuery.padding.top` whenever an app bar is present. Left alone,
/// that puts the first item of every list underneath the bar. So this
/// widget measures the bar from the *outer* context (where `padding.top` is
/// still the real status-bar inset) and re-injects that total as the body's
/// top padding.
///
/// What that means for callers:
/// * A scrollable with `padding: null` (e.g. a bare `ListView.separated`)
///   picks the inset up automatically — nothing to do.
/// * A scrollable that sets its own `padding` overrides that, so wrap it in
///   a `Builder` and add `MediaQuery.paddingOf(context).top` to the top
///   edge yourself.
class GlassScaffold extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget body;

  /// Overrides the scaffold background — Settings uses its own palette.
  final Color? backgroundColor;

  const GlassScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottom,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final appBar = GlassAppBar(title: title, actions: actions, bottom: bottom);
    // Read from the outer context: inside the Scaffold body, padding.top has
    // already been zeroed because an app bar exists.
    final topInset = MediaQuery.paddingOf(context).top + appBar.preferredSize.height;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Builder(
        builder: (context) {
          final media = MediaQuery.of(context);
          return MediaQuery(
            data: media.copyWith(padding: media.padding.copyWith(top: topInset)),
            child: body,
          );
        },
      ),
    );
  }
}

/// [GlassAppBar]'s `CustomScrollView` counterpart — every tab (Home, Live
/// TV, Movies, Series) now owns its own `SliverAppBar` instead of sharing
/// one flat bar at the Dashboard level, so content visibly scrolls behind
/// it and each screen can add its own actions (e.g. the Filter icon).
class GlassSliverAppBar extends StatelessWidget {
  final Widget? title;
  final List<Widget>? actions;

  const GlassSliverAppBar({super.key, this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: title,
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: const DecoratedBox(
            decoration: BoxDecoration(
              color: Color(0xCC12151B),
              border: Border(bottom: BorderSide(color: Colors.white10, width: 0.6)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass wrapper for the dashboard's bottom navigation bar.
class GlassBottomNav extends StatelessWidget {
  final Widget child;
  const GlassBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      tint: const Color(0xE012151B),
      border: const Border(top: BorderSide(color: Colors.white10, width: 0.6)),
      child: child,
    );
  }
}

/// Small pill used across cards/rows for the IMDB-style rating badge.
class RatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;

  const RatingBadge({super.key, required this.rating, this.fontSize = 11});

  @override
  Widget build(BuildContext context) {
    if (rating <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: AppColors.ratingGold, size: fontSize + 3),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(color: Colors.white, fontSize: fontSize, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// App bar that floats *over* a hero banner: fully transparent at the top
/// of the scroll, fading into the frosted [GlassSurface] treatment as
/// content scrolls up behind it.
///
/// Why the fade rather than permanent transparency: a bar that stays clear
/// forever is only readable while artwork happens to sit behind it. Once
/// the user scrolls past the hero, poster rails and section headings would
/// slide under bare icons. Crossfading to glass keeps the immersive look at
/// rest and stays legible everywhere else.
///
/// Pair with `Scaffold(extendBodyBehindAppBar: true)` so the hero can run
/// to the top edge, under both this bar and the status bar.
class HeroOverlayAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;

  /// Current scroll offset of the body. Listened to directly so scrolling
  /// repaints only this bar instead of rebuilding the whole screen.
  final ValueListenable<double> scrollOffset;

  /// False when there's no hero behind the bar (e.g. the filtered grid),
  /// in which case it stays glass at all times.
  final bool transparentAtTop;

  const HeroOverlayAppBar({
    super.key,
    required this.scrollOffset,
    this.title,
    this.actions,
    this.transparentAtTop = true,
  });

  /// Scroll distance over which transparent → glass completes.
  static const double _fadeDistance = 140;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollOffset,
      builder: (context, offset, _) {
        final glass = transparentAtTop ? (offset / _fadeDistance).clamp(0.0, 1.0) : 1.0;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Top-down scrim: what keeps the icons readable against bright
            // artwork while the bar is still clear. Fades out as the glass
            // fades in so the two don't stack into a dark band.
            if (transparentAtTop)
              IgnorePointer(
                child: Opacity(
                  opacity: 1 - glass,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x8C000000), Color(0x00000000)],
                      ),
                    ),
                  ),
                ),
              ),
            // Skip the BackdropFilter entirely while it would be invisible —
            // blur is not free, and this bar is on screen constantly.
            if (glass > 0.01)
              Opacity(
                opacity: glass,
                child: GlassSurface(
                  border: const Border(bottom: BorderSide(color: Colors.white10, width: 0.6)),
                  child: const SizedBox.expand(),
                ),
              ),
            AppBar(
              title: title,
              actions: actions,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              // Drop shadow on icons/title for the stretch where the bar is
              // clear and the scrim alone may not carry a very bright frame.
              iconTheme: const IconThemeData(
                color: Colors.white,
                shadows: [Shadow(color: Color(0xB3000000), blurRadius: 8)],
              ),
              actionsIconTheme: const IconThemeData(
                color: Colors.white,
                shadows: [Shadow(color: Color(0xB3000000), blurRadius: 8)],
              ),
              titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                    shadows: const [Shadow(color: Color(0xB3000000), blurRadius: 8)],
                  ) ??
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    shadows: [Shadow(color: Color(0xB3000000), blurRadius: 8)],
                  ),
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
