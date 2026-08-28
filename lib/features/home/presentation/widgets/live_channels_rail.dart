import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class LiveChannelChipData {
  final String name;
  final String? logoUrl;

  /// "What's on now", when the channel has EPG data — shown under the name.
  final String? nowPlaying;
  final VoidCallback onTap;

  const LiveChannelChipData({
    required this.name,
    required this.onTap,
    this.logoUrl,
    this.nowPlaying,
  });
}

/// "Quick Live Channels" — a horizontal rail of round channel logos with a
/// small LIVE pip, sized for one-tap zapping straight into a stream rather
/// than browsing a list.
class LiveChannelsRail extends StatelessWidget {
  final List<LiveChannelChipData> channels;
  const LiveChannelsRail({super.key, required this.channels});

  @override
  Widget build(BuildContext context) {
    if (channels.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: channels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _LiveChannelChip(data: channels[index]),
      ),
    );
  }
}

class _LiveChannelChip extends StatelessWidget {
  final LiveChannelChipData data;
  const _LiveChannelChip({required this.data});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                    boxShadow: AppColors.cardShadow,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: (data.logoUrl == null || data.logoUrl!.isEmpty)
                      ? const Icon(Icons.live_tv_rounded, color: AppColors.textSecondary, size: 28)
                      : Padding(
                          padding: const EdgeInsets.all(10),
                          child: CachedNetworkImage(
                            imageUrl: data.logoUrl!,
                            fit: BoxFit.contain,
                            errorWidget: (_, _, _) =>
                                const Icon(Icons.live_tv_rounded, color: AppColors.textSecondary, size: 28),
                            placeholder: (_, _) => const SizedBox.shrink(),
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.live,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.background, width: 1.5),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
            ),
            if (data.nowPlaying != null)
              Text(
                data.nowPlaying!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
