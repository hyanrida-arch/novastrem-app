import 'package:flutter/material.dart';

/// A titled horizontal section rendered as a sliver, with an optional
/// "See all". Shared by Home, Live TV, Movies and Series so every screen
/// keeps identical heading treatment and vertical rhythm — change the
/// spacing here and the whole app follows.
class RailSection extends StatelessWidget {
  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  /// Vertical gap above every section — the app's single source of truth
  /// for how much the layout "breathes".
  static const double gap = 30;

  const RailSection({super.key, required this.title, required this.child, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: gap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (onSeeAll != null)
                    TextButton(onPressed: onSeeAll, child: const Text('See all')),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// Generic horizontal strip that lays out already-built cards. Card widgets
/// differ per screen (poster vs. landscape channel plate), so this only
/// owns the scrolling, padding and gaps.
class RailStrip extends StatelessWidget {
  final List<Widget> children;
  final double height;

  const RailStrip({super.key, required this.children, required this.height});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: children.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
