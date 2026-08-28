import 'dart:convert';

/// Raised when a panel answers a list endpoint with something that isn't a
/// list — carries a human-readable reason instead of a raw cast error.
class XtreamApiException implements Exception {
  final String message;
  XtreamApiException(this.message);

  @override
  String toString() => message;
}

/// Decodes an Xtream "list" endpoint (`get_live_streams`, `get_vod_streams`,
/// `get_series`, and the `*_categories` variants) into rows.
///
/// WHY THIS EXISTS: those endpoints normally return a JSON array, and the
/// data sources used to do `jsonDecode(body) as List`. But real
/// panels answer with a JSON *object* in several ordinary situations —
/// an expired or blocked account, a rate-limit notice, a maintenance or
/// error payload — all still served as HTTP 200 with
/// `content-type: application/json`. The blind cast threw
/// `_Map is not a subtype of List`, which was
/// swallowed into a generic "unexpected error" and took down the whole
/// catalog load.
///
/// Now a non-list payload raises [XtreamApiException] describing what the
/// panel actually said, and an empty body is treated as simply "no rows".
List<Map<String, dynamic>> parseXtreamRows(String? body) {
  final raw = (body ?? '').trim();
  if (raw.isEmpty) return const [];

  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    // Panels sometimes serve an HTML maintenance/block page as 200.
    throw XtreamApiException('Provider returned a non-JSON response.');
  }

  if (decoded is List) {
    return decoded.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  if (decoded is Map<String, dynamic>) {
    throw XtreamApiException(_describeObjectPayload(decoded));
  }

  return const [];
}

/// Turns an unexpected object payload into something actionable.
String _describeObjectPayload(Map<String, dynamic> payload) {
  final userInfo = payload['user_info'];
  if (userInfo is Map) {
    final auth = userInfo['auth'];
    if (auth == 0 || auth == '0') {
      return 'The provider rejected these credentials. Re-enter your login details.';
    }
    final status = userInfo['status']?.toString();
    if (status != null && status.isNotEmpty && status.toLowerCase() != 'active') {
      return 'Your subscription status is "$status". Contact your provider.';
    }
  }

  for (final key in const ['error', 'message', 'msg', 'status']) {
    final value = payload[key];
    if (value is String && value.trim().isNotEmpty) {
      return 'Provider said: ${value.trim()}';
    }
  }

  // Fall back to the shape so the cause is still diagnosable from a device.
  final keys = payload.keys.take(6).join(', ');
  return 'Provider returned an unexpected response (fields: $keys).';
}
