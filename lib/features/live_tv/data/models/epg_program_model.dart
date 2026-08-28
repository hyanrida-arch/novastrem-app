import 'dart:convert';

import '../../domain/entities/epg_program_entity.dart';

/// Maps one entry of Xtream's `get_short_epg` response.
///
/// Example payload (trimmed):
/// ```json
/// {
///   "title": "UHJpbWV0aW1lIE5ld3M=",
///   "start_timestamp": "1735678800",
///   "stop_timestamp": "1735682400"
/// }
/// ```
/// `title`/`description` are base64-encoded per the Xtream spec — some
/// panels don't bother encoding despite that, so decoding falls back to the
/// raw string if it isn't valid base64.
class EpgProgramModel {
  final String title;
  final DateTime start;
  final DateTime end;

  const EpgProgramModel({required this.title, required this.start, required this.end});

  factory EpgProgramModel.fromJson(Map<String, dynamic> json) {
    return EpgProgramModel(
      title: _decodeBase64(json['title']?.toString()),
      start: _parseUnixSeconds(json['start_timestamp']),
      end: _parseUnixSeconds(json['stop_timestamp']),
    );
  }

  static String _decodeBase64(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown program';
    try {
      return utf8.decode(base64.decode(raw));
    } catch (_) {
      return raw; // not actually base64 despite the spec — use as-is
    }
  }

  static DateTime _parseUnixSeconds(dynamic value) {
    final seconds = int.tryParse('$value') ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }

  EpgProgramEntity toEntity() => EpgProgramEntity(title: title, start: start, end: end);
}
