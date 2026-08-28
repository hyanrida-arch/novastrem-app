import 'package:equatable/equatable.dart';

/// How the active playlist/account was added to NovaStream.
///
/// [demo] is a special, network-free mode: "Try Quick Demo Account" on the
/// login screen signs the user straight into a small built-in catalog (see
/// `core/demo/demo_content.dart`) with real playable sample streams, so the
/// full app can be explored with zero setup.
enum PlaylistType { xtream, m3u, demo }

/// Domain-level representation of "the account/playlist the user is
/// currently signed into". This is what the presentation layer works with;
/// it knows nothing about Hive, Dio, or JSON.
class UserLoginEntity extends Equatable {
  final PlaylistType type;

  /// Friendly label shown in the UI (defaults to the username/host).
  final String playlistName;

  // Xtream Codes fields
  final String? serverUrl;
  final String? username;
  final String? password;

  // M3U fields
  final String? m3uUrl;

  /// Raw fields returned by Xtream's `user_info` object, kept for display
  /// (expiry date, max connections, status banner, etc).
  final String? status;
  final DateTime? expiryDate;
  final int? activeConnections;
  final int? maxConnections;

  const UserLoginEntity({
    required this.type,
    required this.playlistName,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.status,
    this.expiryDate,
    this.activeConnections,
    this.maxConnections,
  });

  bool get isXtream => type == PlaylistType.xtream;
  bool get isDemo => type == PlaylistType.demo;

  @override
  List<Object?> get props => [
        type,
        playlistName,
        serverUrl,
        username,
        password,
        m3uUrl,
        status,
        expiryDate,
        activeConnections,
        maxConnections,
      ];
}
