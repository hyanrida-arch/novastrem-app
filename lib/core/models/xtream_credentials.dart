import 'package:equatable/equatable.dart';

/// Shared value object passed into every Xtream-backed data source
/// (live TV, VOD, series). Kept in `core/` because it's a cross-feature
/// concept, not something any single feature owns.
class XtreamCredentials extends Equatable {
  final String serverUrl;
  final String username;
  final String password;

  const XtreamCredentials({
    required this.serverUrl,
    required this.username,
    required this.password,
  });

  @override
  List<Object?> get props => [serverUrl, username, password];
}
