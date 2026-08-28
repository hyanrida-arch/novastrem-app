import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/xtream_response.dart';
import '../../../../core/utils/xtream_url_builder.dart';
import '../models/category_model.dart';
import '../models/channel_model.dart';
import '../models/epg_program_model.dart';

/// Talks to `player_api.php` for everything Live-TV related.
abstract class LiveTvRemoteDataSource {
  Future<List<CategoryModel>> getLiveCategories(XtreamCredentials creds);

  /// When [categoryId] is omitted, Xtream returns every channel across all
  /// categories (fine for small panels; the UI paginates/filters as needed).
  Future<List<ChannelModel>> getLiveStreams(XtreamCredentials creds, {String? categoryId});

  /// The single "now playing" program for [streamId], or null if the panel
  /// has no EPG data for that channel.
  Future<EpgProgramModel?> getShortEpg(XtreamCredentials creds, int streamId);
}

class LiveTvRemoteDataSourceImpl implements LiveTvRemoteDataSource {
  final ApiClient apiClient;

  LiveTvRemoteDataSourceImpl(this.apiClient);

  XtreamUrlBuilder _builderFor(XtreamCredentials creds) => XtreamUrlBuilder(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );

  @override
  Future<List<CategoryModel>> getLiveCategories(XtreamCredentials creds) async {
    final uri = _builderFor(creds).action(AppConstants.actionGetLiveCategories);
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows
        .map(CategoryModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<ChannelModel>> getLiveStreams(XtreamCredentials creds, {String? categoryId}) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetLiveStreams,
      categoryId != null ? {'category_id': categoryId} : null,
    );
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows
        .map(ChannelModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<EpgProgramModel?> getShortEpg(XtreamCredentials creds, int streamId) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetShortEpg,
      {'stream_id': '$streamId', 'limit': '1'},
    );
    final response = await apiClient.get(uri);
    // Same defensive stance as parseXtreamRows: a panel can answer with
    // HTML or an unexpected shape, and a missing EPG must never break
    // the channel list.
    final decoded = jsonDecode((response.data ?? '').trim().isEmpty ? '{}' : response.data!);
    if (decoded is! Map<String, dynamic>) return null;
    final listings = (decoded['epg_listings'] as List<dynamic>?) ?? const [];
    if (listings.isEmpty) return null;
    final first = listings.first;
    if (first is! Map<String, dynamic>) return null;
    return EpgProgramModel.fromJson(first);
  }
}
