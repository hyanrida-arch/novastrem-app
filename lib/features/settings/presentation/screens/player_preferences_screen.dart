import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/glass_surface.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_provider.dart';

/// Hardware Acceleration / Default Player / Buffer Size — reached from the
/// main Settings screen's "Player preferences" row. Split out from
/// `settings_screen.dart` (which now matches an exact external design
/// reference with its own fixed item list) so this still-functional
/// control panel isn't lost; it reads/writes the same
/// [settingsControllerProvider] as before, and [PlayerScreen] already
/// consumes these values for real playback behavior.
class PlayerPreferencesScreen extends ConsumerWidget {
  const PlayerPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return GlassScaffold(
      title: const Text('Player Preferences'),
      body: Builder(
        builder: (context) => ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32)
            .copyWith(top: MediaQuery.paddingOf(context).top + 8),
        children: [
          Container(
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                SwitchListTile(
                  value: settings.hardwareAcceleration,
                  onChanged: controller.setHardwareAcceleration,
                  title: const Text('Hardware Acceleration'),
                  subtitle: const Text(
                    'Uses the device GPU to decode video. Turn off only if playback is unstable.',
                  ),
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Row(
                    children: [
                      const Expanded(child: Text('Default Player')),
                      SegmentedButton<PlayerBackend>(
                        segments: const [
                          ButtonSegment(value: PlayerBackend.vlc, label: Text('VLC')),
                          ButtonSegment(value: PlayerBackend.exoPlayer, label: Text('ExoPlayer')),
                        ],
                        selected: {settings.defaultPlayer},
                        onSelectionChanged: (selection) => controller.setDefaultPlayer(selection.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Text('Buffer Size'),
                      const Spacer(),
                      Text(
                        '${(settings.bufferSizeMs / 1000).toStringAsFixed(1)}s',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Slider(
                  value: settings.bufferSizeMs.toDouble(),
                  min: 500,
                  max: 10000,
                  divisions: 19,
                  activeColor: AppColors.primary,
                  label: '${(settings.bufferSizeMs / 1000).toStringAsFixed(1)}s',
                  onChanged: (value) => controller.setBufferSizeMs(value.round()),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(
                    'Higher buffers smooth out unstable connections but take longer to start playback.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
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
