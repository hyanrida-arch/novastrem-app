import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/catalog/catalog_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/glass_surface.dart';
import '../../../auth/domain/entities/user_login_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../downloads/presentation/screens/download_manager_screen.dart';
import '../../../history/presentation/providers/history_provider.dart';
import '../../../history/presentation/screens/history_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../domain/entities/settings_entity.dart';
import '../providers/settings_provider.dart';
import 'player_preferences_screen.dart';

/// Settings screen, built to match an exact external design reference:
/// deep dark background, rounded dark-grey cards grouping related rows,
/// small uppercase grey section headers, and inset dividers between rows
/// in the same card.
///
/// Section order and row names follow that reference. Every row is backed by
/// something real: rows display live session/settings state rather than
/// placeholder text, and each `onTap` either performs a real action or says
/// plainly that the feature isn't built yet — a row must never look tappable
/// and then silently do nothing.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final settings = ref.watch(settingsControllerProvider);
    final catalog = ref.watch(catalogControllerProvider);

    final sections = <_SettingsSectionData>[
      _SettingsSectionData(
        header: 'Home',
        items: [
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.alternate_email_rounded),
            title: 'My NovaStream account',
            subtitle: session == null ? 'Sign in' : _accountSubtitle(session),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => session == null ? const LoginScreen() : const ProfileScreen(),
              ),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.workspace_premium_outlined),
            title: 'NovaStream+',
            subtitle: 'Switch to NovaStream+',
            onTap: () => _showUnavailable(
              context,
              feature: 'NovaStream+',
              detail: 'There is no NovaStream+ tier yet — this row is a '
                  'placeholder for a future subscription flow.',
            ),
          ),
        ],
      ),
      _SettingsSectionData(
        header: 'Playlists',
        items: [
          if (session != null)
            _SettingsItemData(
              leading: _LeadingLetter(session.playlistName),
              title: session.playlistName,
              subtitle: _refreshSubtitle(catalog),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.add_rounded),
            title: 'Add a playlist',
            // NovaStream keeps exactly one active session (a single Hive
            // `active_session` key), so "add" really means "replace" until
            // multi-playlist storage exists. Say so rather than silently
            // signing the user out of the playlist they're using.
            subtitle: session == null ? null : 'Replaces the current playlist',
            onTap: () => _addPlaylist(context, ref, hasSession: session != null),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.refresh_rounded),
            title: 'Refresh all',
            subtitle: 'Re-download channels, movies and series',
            onTap: session == null ? null : () => _refreshAll(context, ref),
          ),
        ],
      ),
      _SettingsSectionData(
        header: 'EPG Sources',
        items: [
          if (session != null && session.isXtream)
            _SettingsItemData(
              leading: _LeadingLetter(session.playlistName),
              title: session.playlistName,
              // Xtream serves EPG from the same account as the streams
              // (`get_short_epg`), so there is no separate source to manage.
              subtitle: 'Built into this Xtream account',
              onTap: () => _showInfo(
                context,
                title: 'EPG source',
                body: 'Programme data for this playlist comes from the same '
                    'Xtream account as the channels, so there is no separate '
                    'source to configure or refresh.',
              ),
            )
          else
            _SettingsItemData(
              leading: const _LeadingIcon(Icons.event_busy_rounded),
              title: 'No EPG source',
              subtitle: session == null
                  ? 'Sign in to a playlist first'
                  : 'This playlist type does not provide an EPG',
            ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.add_rounded),
            title: 'Add source',
            onTap: () => _showUnavailable(
              context,
              feature: 'External EPG sources',
              detail: 'NovaStream reads programme data from the signed-in '
                  'Xtream account. Loading a separate XMLTV file is not '
                  'implemented yet.',
            ),
          ),
        ],
      ),
      _SettingsSectionData(
        header: 'History',
        items: [
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.checklist_rounded),
            title: 'History',
            subtitle: _historySubtitle(ref),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.masks_rounded),
            title: 'Incognito',
            subtitle: settings.incognito
                ? 'Playback is not being recorded'
                : 'Record what you watch',
            trailing: Switch.adaptive(
              value: settings.incognito,
              activeThumbColor: AppColors.primary,
              onChanged: (value) =>
                  ref.read(settingsControllerProvider.notifier).setIncognito(value),
            ),
          ),
        ],
      ),
      _SettingsSectionData(
        header: 'UI & Preferences',
        items: [
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.download_rounded),
            title: 'Downloads',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DownloadManagerScreen()),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.layers_outlined),
            title: 'Interface',
            subtitle: settings.language.label,
            onTap: () => _pickLanguage(context, ref, current: settings.language),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.play_circle_outline_rounded),
            title: 'Player preferences',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlayerPreferencesScreen()),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.lock_outline_rounded),
            title: 'Parental control',
            subtitle: settings.hasParentalPin ? 'PIN set' : 'No PIN set',
            onTap: () => _parentalControl(context, ref, hasPin: settings.hasParentalPin),
          ),
        ],
      ),
      _SettingsSectionData(
        header: 'Misc',
        items: [
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.public_rounded),
            title: 'DNS',
            subtitle: 'System',
            onTap: () => _showInfo(
              context,
              title: 'DNS',
              body: 'NovaStream resolves hostnames through the DNS servers '
                  'your device is already configured to use. Overriding the '
                  'resolver inside the app is not implemented — change it in '
                  'your device or router settings instead.',
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.perm_identity_rounded),
            title: 'User-Agent',
            // The real header value, read from the same constant ApiClient
            // sends — not a lookalike string.
            subtitle: AppConstants.userAgent,
            onTap: () => _showInfo(
              context,
              title: 'User-Agent',
              body: 'Every request NovaStream makes to your provider carries '
                  'this header:\n\n${AppConstants.userAgent}\n\nSome panels '
                  'block unfamiliar clients. Setting a custom User-Agent is '
                  'not implemented yet.',
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.info_outline_rounded),
            title: 'Dev options',
            subtitle: 'Version ${AppConstants.appVersion}',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _DevOptionsScreen()),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.cleaning_services_outlined),
            title: 'Clear cache',
            subtitle: 'Delete cached artwork and temporary files',
            onTap: () => _clearCache(context, ref),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.shield_outlined),
            title: 'Privacy policy',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _PrivacyScreen()),
            ),
          ),
          _SettingsItemData(
            leading: const _LeadingIcon(Icons.gavel_outlined),
            title: 'Terms of use',
            onTap: () => _showUnavailable(
              context,
              feature: 'Terms of use',
              detail: 'No terms document is bundled with this build. Your use '
                  'of the channels, movies and series shown here is governed '
                  'by the agreement you have with your IPTV provider.',
            ),
          ),
        ],
      ),
    ];

    return GlassScaffold(
      backgroundColor: _Palette.background,
      title: const Text('Settings'),
      body: Builder(
        builder: (context) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32)
              .copyWith(top: MediaQuery.paddingOf(context).top + 8),
          itemCount: sections.length,
          itemBuilder: (context, index) => _SettingsSectionView(section: sections[index]),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Subtitles derived from real state
  // ---------------------------------------------------------------------------

  static String _accountSubtitle(UserLoginEntity session) {
    switch (session.type) {
      case PlaylistType.xtream:
        return session.username ?? session.playlistName;
      case PlaylistType.m3u:
        return 'M3U playlist';
      case PlaylistType.demo:
        return 'Demo account';
    }
  }

  /// "Last refresh" reflects when the catalog actually finished loading.
  /// Before that has happened once, say so instead of printing today's date.
  static String _refreshSubtitle(CatalogState catalog) {
    final loadedAt = catalog.loadedAt;
    if (loadedAt == null) {
      return catalog.hasFailed ? 'Last refresh failed' : 'Not refreshed yet';
    }
    return 'Last refresh: ${DateFormat('dd MMM yyyy, HH:mm').format(loadedAt)}';
  }

  static String _historySubtitle(WidgetRef ref) {
    final count = ref.watch(historyControllerProvider).length;
    if (count == 0) return 'Nothing watched yet';
    return count == 1 ? '1 item' : '$count items';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _addPlaylist(BuildContext context, WidgetRef ref, {required bool hasSession}) async {
    if (hasSession) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace current playlist?'),
          content: const Text(
            'NovaStream supports one playlist at a time. Signing in to another '
            'one will sign you out of the current playlist. Your favourites, '
            'history and downloads stay on this device.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
          ],
        ),
      );
      if (replace != true || !context.mounted) return;
    }
    if (!context.mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _refreshAll(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Refreshing your library…'), duration: Duration(seconds: 30)),
    );

    await ref.read(catalogControllerProvider.notifier).refresh();

    final state = ref.read(catalogControllerProvider);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          state.hasFailed
              ? 'Refresh failed: ${state.error ?? 'unknown error'}'
              : 'Library refreshed.',
        ),
      ),
    );
  }

  Future<void> _pickLanguage(
    BuildContext context,
    WidgetRef ref, {
    required AppLanguage current,
  }) async {
    final choice = await showModalBottomSheet<AppLanguage>(
      context: context,
      backgroundColor: _Palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Language',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            RadioGroup<AppLanguage>(
              groupValue: current,
              onChanged: (value) => Navigator.pop(context, value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final language in AppLanguage.values)
                    RadioListTile<AppLanguage>(
                      value: language,
                      activeColor: AppColors.primary,
                      title: Text(language.label, style: const TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (choice == null || choice == current) return;
    await ref.read(settingsControllerProvider.notifier).setLanguage(choice);
  }

  Future<void> _parentalControl(
    BuildContext context,
    WidgetRef ref, {
    required bool hasPin,
  }) async {
    if (!hasPin) {
      final pin = await _promptPin(context, title: 'Set a PIN', hint: 'Choose 4 digits');
      if (pin == null || !context.mounted) return;
      final confirm = await _promptPin(context, title: 'Confirm PIN', hint: 'Re-enter the 4 digits');
      if (confirm == null || !context.mounted) return;
      if (pin != confirm) {
        _toast(context, 'The two PINs did not match.');
        return;
      }
      await ref.read(settingsControllerProvider.notifier).setParentalPin(pin);
      if (context.mounted) _toast(context, 'Parental PIN set.');
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _Palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.password_rounded, color: Colors.white70),
              title: const Text('Change PIN', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'change'),
            ),
            ListTile(
              leading: const Icon(Icons.lock_open_rounded, color: Colors.white70),
              title: const Text('Remove PIN', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    // Both paths require proving you know the current PIN first.
    final currentPin = await _promptPin(context, title: 'Enter current PIN', hint: '4 digits');
    if (currentPin == null || !context.mounted) return;
    if (!ref.read(settingsControllerProvider.notifier).verifyParentalPin(currentPin)) {
      _toast(context, 'Incorrect PIN.');
      return;
    }

    if (action == 'remove') {
      await ref.read(settingsControllerProvider.notifier).clearParentalPin();
      if (context.mounted) _toast(context, 'Parental PIN removed.');
      return;
    }

    final newPin = await _promptPin(context, title: 'New PIN', hint: 'Choose 4 digits');
    if (newPin == null || !context.mounted) return;
    final confirm = await _promptPin(context, title: 'Confirm PIN', hint: 'Re-enter the 4 digits');
    if (confirm == null || !context.mounted) return;
    if (newPin != confirm) {
      _toast(context, 'The two PINs did not match.');
      return;
    }
    await ref.read(settingsControllerProvider.notifier).setParentalPin(newPin);
    if (context.mounted) _toast(context, 'Parental PIN updated.');
  }

  Future<void> _clearCache(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'Cached posters, channel logos and temporary files will be deleted. '
          'Your playlist, favourites, history and downloads are not affected.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(settingsControllerProvider.notifier).clearCache();
      messenger.showSnackBar(const SnackBar(content: Text('Cache cleared.')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not clear the cache: $e')));
    }
  }
}

// ---------------------------------------------------------------------------
// Small shared dialogs
// ---------------------------------------------------------------------------

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

/// Used by rows the design calls for but that have no implementation behind
/// them yet. A row that looks tappable must say *why* nothing happened.
void _showUnavailable(BuildContext context, {required String feature, required String detail}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(feature),
      content: Text('Not available yet.\n\n$detail'),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

void _showInfo(BuildContext context, {required String title, required String body}) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: Text(body)),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
    ),
  );
}

/// Modal 4-digit entry. Returns the digits, or null if dismissed.
Future<String?> _promptPin(BuildContext context, {required String title, required String hint}) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        decoration: InputDecoration(hintText: hint, counterText: ''),
        onSubmitted: (value) {
          if (value.length == 4) Navigator.pop(context, value);
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final value = controller.text;
            if (value.length == 4 && int.tryParse(value) != null) {
              Navigator.pop(context, value);
            }
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Misc destinations
// ---------------------------------------------------------------------------

/// Real diagnostics, not a stub: everything here is read from live state so
/// it's useful when a provider misbehaves.
class _DevOptionsScreen extends ConsumerWidget {
  const _DevOptionsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).session;
    final catalog = ref.watch(catalogControllerProvider);
    final settings = ref.watch(settingsControllerProvider);
    final prepared = catalog.catalog;

    final rows = <(String, String)>[
      ('App version', AppConstants.appVersion),
      ('User-Agent', AppConstants.userAgent),
      ('Playlist type', session?.type.name ?? '—'),
      // Host only — the full Xtream URL carries the account's credentials.
      ('Server host', _hostOf(session)),
      ('Account status', session?.status ?? '—'),
      (
        'Expiry',
        session?.expiryDate == null
            ? '—'
            : DateFormat('dd MMM yyyy').format(session!.expiryDate!),
      ),
      ('Connections', session == null ? '—' : '${session.activeConnections ?? 0} / ${session.maxConnections ?? 0}'),
      ('Catalog phase', catalog.phase.name),
      if (catalog.error != null) ('Catalog error', catalog.error!),
      ('Channels', '${prepared.channels.length}'),
      ('Live categories', '${prepared.liveCategories.length}'),
      ('Movies', '${prepared.moviesNewest.length}'),
      ('Series', '${prepared.seriesNewest.length}'),
      ('Hardware acceleration', settings.hardwareAcceleration ? 'on' : 'off'),
      ('Buffer', '${settings.bufferSizeMs} ms'),
      ('Incognito', settings.incognito ? 'on' : 'off'),
    ];

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(title: const Text('Dev options'), backgroundColor: _Palette.background),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1, color: _Palette.divider),
        itemBuilder: (context, index) {
          final (label, value) = rows[index];
          return ListTile(
            title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
            subtitle: SelectableText(
              value,
              style: const TextStyle(color: _Palette.grey, fontSize: 13),
            ),
          );
        },
      ),
    );
  }

  static String _hostOf(UserLoginEntity? session) {
    final raw = session?.serverUrl ?? session?.m3uUrl;
    if (raw == null) return '—';
    return Uri.tryParse(raw)?.host ?? raw;
  }
}

/// A factual description of what this build actually stores and transmits,
/// rather than boilerplate legal text nobody wrote.
class _PrivacyScreen extends StatelessWidget {
  const _PrivacyScreen();

  @override
  Widget build(BuildContext context) {
    const paragraphs = <(String, String)>[
      (
        'Stored on this device only',
        'Your playlist credentials, favourites, watch history, downloads and '
            'app preferences are kept in local storage on this device. They '
            'are not uploaded anywhere by NovaStream.',
      ),
      (
        'Sent to your provider',
        'To list and play content, NovaStream contacts the server address you '
            'signed in with, using your playlist credentials. Artwork is '
            'fetched from whatever image URLs that server returns.',
      ),
      (
        'No analytics',
        'This build contains no analytics, crash-reporting or advertising '
            'SDKs, and sends no usage data to NovaStream.',
      ),
      (
        'Parental PIN',
        'The parental PIN is stored as a SHA-256 hash, never as the digits '
            'you typed.',
      ),
      (
        'Incognito',
        'While Incognito is on, playback is not added to watch history and '
            'does not affect "Most Watched" or "Continue Watching".',
      ),
      (
        'Removing your data',
        'Signing out clears the stored playlist. "Clear cache" removes cached '
            'artwork and temporary files. Uninstalling the app removes '
            'everything listed above.',
      ),
    ];

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(title: const Text('Privacy'), backgroundColor: _Palette.background),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          for (final (heading, body) in paragraphs) ...[
            Padding(
              padding: const EdgeInsets.only(top: 18, bottom: 6),
              child: Text(
                heading,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(body, style: const TextStyle(color: _Palette.grey, height: 1.45, fontSize: 13.5)),
          ],
          const SizedBox(height: 24),
          const Text(
            'This is a description of how the app behaves, not a published '
            'legal policy document.',
            style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Design primitives
// ---------------------------------------------------------------------------

/// Colors scoped to this screen's exact design reference — distinct from
/// [AppColors] (which is a shade lighter/more purple-tinted) so this screen
/// matches the reference pixel-for-pixel rather than the app's usual theme.
abstract class _Palette {
  _Palette._();
  static const background = Color(0xFF121212);
  static const card = Color(0xFF1E1E1E);
  static const divider = Colors.white12;
  static const grey = Color(0xFF9E9E9E);
}

class _SettingsSectionData {
  final String header;
  final List<_SettingsItemData> items;
  const _SettingsSectionData({required this.header, required this.items});
}

class _SettingsItemData {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsItemData({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });
}

/// Minimalist leading glyph — plain icon, no background/circle, matching
/// the reference's flat style.
class _LeadingIcon extends StatelessWidget {
  final IconData icon;
  const _LeadingIcon(this.icon);

  @override
  Widget build(BuildContext context) => Icon(icon, color: Colors.white70, size: 22);
}

/// Leading glyph for playlist/EPG-source rows: a single-letter avatar taken
/// from the real playlist name instead of an icon.
class _LeadingLetter extends StatelessWidget {
  final String name;
  const _LeadingLetter(this.name);

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final letter = trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary,
      child: Text(
        letter,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

class _SettingsSectionView extends StatelessWidget {
  final _SettingsSectionData section;
  const _SettingsSectionView({required this.section});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
          child: Text(
            section.header.toUpperCase(),
            style: const TextStyle(
              color: _Palette.grey,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(color: _Palette.card, borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < section.items.length; i++) ...[
                _SettingsTile(item: section.items[i]),
                // Inset divider — starts past the leading icon so it lines
                // up under the title text, and doesn't span the full card.
                if (i != section.items.length - 1)
                  const Padding(
                    padding: EdgeInsets.only(left: 72),
                    child: Divider(height: 1, thickness: 0.6, color: _Palette.divider),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItemData item;
  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    // Rows with neither a tap target nor a control are informational; dim
    // them so they don't read as broken buttons.
    final isInert = item.onTap == null && item.trailing == null;
    return ListTile(
      enabled: !isInert,
      leading: item.leading,
      title: Text(
        item.title,
        style: TextStyle(color: isInert ? Colors.white54 : Colors.white, fontSize: 15.5),
      ),
      subtitle: item.subtitle == null
          ? null
          : Text(
              item.subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _Palette.grey, fontSize: 12.5),
            ),
      trailing: item.trailing,
      onTap: item.onTap,
    );
  }
}
