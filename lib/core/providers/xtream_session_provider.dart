import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../models/xtream_credentials.dart';

/// Derives the active [XtreamCredentials] from the signed-in session.
/// Returns null when the user authenticated via a plain M3U playlist
/// instead of Xtream Codes (live TV/VOD/series screens should treat that
/// as "not available" for now — see README notes on M3U parsing).
final xtreamCredentialsProvider = Provider<XtreamCredentials?>((ref) {
  final session = ref.watch(authControllerProvider).session;
  if (session == null || !session.isXtream) return null;
  if (session.serverUrl == null || session.username == null || session.password == null) {
    return null;
  }
  return XtreamCredentials(
    serverUrl: session.serverUrl!,
    username: session.username!,
    password: session.password!,
  );
});

/// True when the user is signed into the built-in "Quick Demo Account"
/// rather than a real Xtream/M3U source. Feature providers check this to
/// serve [DemoContent] instead of hitting the network.
final isDemoSessionProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).session?.isDemo ?? false;
});
