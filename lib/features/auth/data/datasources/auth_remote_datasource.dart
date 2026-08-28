import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/utils/xtream_url_builder.dart';

/// Thrown when the Xtream panel responds but rejects the credentials
/// (`user_info.auth == 0`), as opposed to a network/transport failure.
class XtreamAuthException implements Exception {
  final String message;
  XtreamAuthException([this.message = 'Invalid Xtream credentials.']);
}

/// Raw account/server info returned by a successful Xtream login, still
/// shaped like the API response (mapping to the domain entity happens in
/// the repository).
class XtreamAccountInfo {
  final Map<String, dynamic> userInfo;
  final Map<String, dynamic> serverInfo;

  XtreamAccountInfo({required this.userInfo, required this.serverInfo});
}

abstract class AuthRemoteDataSource {
  /// Calls `player_api.php?username=..&password=..` and validates the
  /// response. Throws [XtreamAuthException] on bad credentials, or a
  /// [DioException] on network failure.
  Future<XtreamAccountInfo> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  });

  /// Basic reachability check for an M3U URL (HEAD/GET), since M3U
  /// "login" has no real auth step — we just confirm the playlist loads.
  Future<void> validateM3uUrl(String m3uUrl);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl(this.apiClient);

  @override
  Future<XtreamAccountInfo> loginWithXtream({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final builder = XtreamUrlBuilder(
      serverUrl: serverUrl,
      username: username,
      password: password,
    );

    final response = await apiClient.get(builder.loginUrl);

    late final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    } on FormatException {
      // Panel returned HTML (wrong URL, maintenance page, etc).
      throw XtreamAuthException('Server did not return a valid Xtream response.');
    }

    final userInfo = json['user_info'] as Map<String, dynamic>?;
    final serverInfo = json['server_info'] as Map<String, dynamic>?;

    if (userInfo == null) {
      throw XtreamAuthException('Unexpected response from server.');
    }

    // Xtream returns auth: 0/1 (sometimes as string) for bad credentials.
    final auth = userInfo['auth'];
    final authOk = auth == 1 || auth == '1';
    if (!authOk) {
      throw XtreamAuthException();
    }

    return XtreamAccountInfo(userInfo: userInfo, serverInfo: serverInfo ?? {});
  }

  @override
  Future<void> validateM3uUrl(String m3uUrl) async {
    // Real M3U playlists can be many MBs (thousands of channels) — fetching
    // the whole thing just to check the first line risks timing out on a
    // slow connection for no reason. Stream instead, and stop reading once
    // we have enough bytes to check the header.
    //
    // NOTE: this deliberately does NOT also call `CancelToken.cancel()` —
    // breaking out of `await for` already cancels the stream subscription
    // (and, with it, the underlying connection); an extra manual cancel on
    // top of that was surfacing as a spurious `DioExceptionType.cancel`
    // that got misreported to the user as a generic "Server error."
    final response = await apiClient.dio.get<ResponseBody>(
      m3uUrl,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        // Some Xtream reseller panels front their playlist endpoint with a
        // proxy/WAF that answers with wildly non-standard HTTP status codes
        // (seen in the wild: 3-digit codes outside the real 100–599 range)
        // while still serving a perfectly valid #EXTM3U body. Dio's default
        // `validateStatus` rejects anything outside 200–299 before we ever
        // get to look at the body, so a working playlist was being thrown
        // away as a "server error." Accept any status here and let the
        // content itself (checked below) be the real judge of validity.
        validateStatus: (_) => true,
      ),
    );

    final buffer = StringBuffer();
    await for (final chunk in response.data!.stream) {
      buffer.write(utf8.decode(chunk, allowMalformed: true));
      if (buffer.length >= 32) break; // "#EXTM3U" is 7 chars; leaves slack for a BOM/whitespace
    }

    // Some panels prepend a UTF-8 BOM before the header — strip it (and any
    // leading whitespace) before checking, or a perfectly valid playlist
    // gets rejected.
    final head = buffer.toString().replaceFirst('﻿', '').trimLeft();
    if (!head.startsWith('#EXTM3U')) {
      final status = response.statusCode;
      throw XtreamAuthException(
        'This does not look like a valid M3U playlist${status != null ? ' (server returned status $status)' : ''}.',
      );
    }
  }
}
