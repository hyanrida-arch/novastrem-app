import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'glass_surface.dart';

/// One slide's worth of data — deliberately entity-agnostic so Home can mix
/// movies, series and live channels in a single rotation while the Movies
/// and Series screens feed it a single content type.
class HeroSlideData {
  final String title;
  final String? imageUrl;
  final double rating;

  /// Small kicker above the title ("FEATURED", "LIVE NOW", "NEW MOVIE"…).
  final String badge;

  /// Highlights the badge in the "live" red rather than the brand gradient.
  final bool isLive;

  /// Release year, shown in the metadata line under the title.
  final int? year;

  /// Genre label. Xtream's list endpoints carry no genre field — only the
  /// per-item detail call does — so callers pass the item's *category name*,
  /// which is exactly what a category represents in an Xtream catalog.
  final String? genre;

  final VoidCallback onPlay;
  final VoidCallback onToggleMyList;
  final bool inMyList;

  /// Opens the details screen. Wired to a tap anywhere on the artwork, so
  /// "More Info" is reachable without adding a third button that would
  /// duplicate Play for series (whose Play already opens the episode list).
  final VoidCallback? onOpenDetails;

  const HeroSlideData({
    required this.title,
    required this.badge,
    required this.onPlay,
    required this.onToggleMyList,
    this.imageUrl,
    this.rating = 0,
    this.isLive = false,
    this.year,
    this.genre,
    this.inMyList = false,
    this.onOpenDetails,
  });

  /// "2010 · Sci-Fi · ★ 8.1" — whichever parts exist.
  String get metadataLine {
    return [
      if (year != null) '$year',
      if (genre != null && genre!.trim().isNotEmpty) genre!.trim(),
    ].join('  ·  ');
  }
}

/// Full-bleed auto-advancing hero slider, sized as a fraction of screen
/// height so it feels immersive on any device.
///
/// Auto-play pauses while the app is backgrounded and while the user is
/// dragging, so it never fights the user's own scrolling.
///
/// NOTE: the Dashboard keeps every tab alive in an `IndexedStack`, so an
/// instance stays mounted while you're on another tab. The timer is cheap
/// (one page animation every 6s); gate `_startAutoPlay` on a visibility
/// signal (e.g. `visibility_detector`) if you ever want it fully idle.
class HeroCarousel extends StatefulWidget {
  final List<HeroSlideData> slides;
  final Duration interval;

  /// Portion of screen height the banner occupies. Clamped to
  /// [_minHeight]/[_maxHeight] so it stays sane on very small phones and
  /// very tall tablets.
  final double heightFraction;

  const HeroCarousel({
    super.key,
    required this.slides,
    this.interval = const Duration(seconds: 6),
    this.heightFraction = 0.46,
  });

  static const double _minHeight = 340;
  static const double _maxHeight = 560;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> with WidgetsBindingObserver {
  final PageController _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(HeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The catalog can arrive/refresh after first build — restart so a
    // single-slide carousel doesn't keep an unnecessary timer running, and
    // a newly-multi-slide one actually starts rotating.
    if (oldWidget.slides.length != widget.slides.length) {
      _index = 0;
      _startAutoPlay();
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if (widget.slides.length < 2) return; // nothing to rotate between
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_index + 1) % widget.slides.length,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startAutoPlay();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.slides.isEmpty) return const SizedBox.shrink();

    final height = (MediaQuery.sizeOf(context).height * widget.heightFraction)
        .clamp(HeroCarousel._minHeight, HeroCarousel._maxHeight);

    return SizedBox(
      height: height,
      child: NotificationListener<ScrollNotification>(
        // Hand control to the user the moment they touch the slider, and
        // resume the rotation once they let go.
        onNotification: (notification) {
          if (notification is ScrollStartNotification && notification.dragDetails != null) {
            _timer?.cancel();
          } else if (notification is ScrollEndNotification) {
            _startAutoPlay();
          }
          return false;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, index) => _HeroSlide(slide: widget.slides[index]),
            ),
            if (widget.slides.length > 1)
              Positioned(
                bottom: 14,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < widget.slides.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 4,
                        width: i == _index ? 20 : 6,
                        decoration: BoxDecoration(
                          color: i == _index ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroSlide extends StatelessWidget {
  final HeroSlideData slide;
  const _HeroSlide({required this.slide});

  @override
  Widget build(BuildContext context) {
    final metadata = slide.metadataLine;

    return GestureDetector(
      onTap: slide.onOpenDetails,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (slide.imageUrl == null || slide.imageUrl!.isEmpty)
            const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradient))
          else
            CachedNetworkImage(
              imageUrl: slide.imageUrl!,
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 350),
              placeholder: (_, _) => const ColoredBox(color: AppColors.surface),
              errorWidget: (_, _, _) =>
                  const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.brandGradient)),
            ),
          // Bottom fade so the copy stays legible over any artwork and the
          // banner melts into the rails below instead of ending on a seam.
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimBottom)),
          Positioned(
            left: 20,
            right: 20,
            bottom: 34,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: slide.isLive ? null : AppColors.brandGradient,
                        color: slide.isLive ? AppColors.live : null,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        slide.badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    if (slide.rating > 0) ...[
                      const SizedBox(width: 8),
                      RatingBadge(rating: slide.rating, fontSize: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  slide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.15),
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    metadata,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: slide.onPlay,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(slide.inMyList ? Icons.check_rounded : Icons.add_rounded),
                        label: Text(slide.inMyList ? 'In My List' : 'My List'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: slide.onToggleMyList,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
