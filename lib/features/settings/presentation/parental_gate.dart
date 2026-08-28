import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/settings_provider.dart';
import 'widgets/pin_entry_dialog.dart';

/// Global entry point for gating any screen/action behind the Parental
/// Control PIN. Not wired into any screen yet — this is the seam described
/// in the Settings screen's "Parental Control" section for doing so later.
///
/// ## How to use this later
///
/// Wrap whatever needs gating — e.g. a "Adult" Live TV category's `onTap`,
/// or a whole route via `onGenerateRoute` — with a check like:
///
/// ```dart
/// onTap: () async {
///   final allowed = await requireParentalPin(context, ref);
///   if (!allowed) return; // user cancelled or entered the wrong PIN
///   Navigator.of(context).push(MaterialPageRoute(builder: (_) => RestrictedScreen()));
/// },
/// ```
///
/// Typical places to add that check in this codebase:
/// - `live_tv_screen.dart` / `movies_screen.dart` / `series_screen.dart` —
///   gate specific category names (e.g. anything containing "18+" or
///   "Adult") before opening that category's rail/filtered grid.
/// - `dashboard_screen.dart` — gate the whole Movies or Series tab if you
///   want a stricter "kids mode" rather than per-category gating.
/// - `SettingsScreen` itself — gate *disabling* Parental Control the same
///   way (already done inline in `settings_screen.dart`, since removing
///   the PIN is itself a sensitive action).
///
/// Returns `true` immediately (no prompt) if no PIN has been set — i.e.
/// Parental Control is opt-in, matching IPTV Smarters-style apps.
Future<bool> requireParentalPin(BuildContext context, WidgetRef ref) async {
  final settings = ref.read(settingsControllerProvider);
  if (!settings.hasParentalPin) return true;

  String? error;
  for (var attempt = 0; attempt < 3; attempt++) {
    if (!context.mounted) return false;
    final pin = await PinEntryDialog.show(
      context,
      title: 'Enter Parental PIN',
      subtitle: 'This section is protected by Parental Control.',
      errorText: error,
    );
    if (pin == null) return false; // user cancelled

    final ok = ref.read(settingsControllerProvider.notifier).verifyParentalPin(pin);
    if (ok) return true;
    error = 'Incorrect PIN. Try again.';
  }
  return false;
}
