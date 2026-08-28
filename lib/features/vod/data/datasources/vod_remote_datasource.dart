import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/xtream_response.dart';
import '../../../../core/utils/xtream_url_builder.dart';
import '../models/movie_details_model.dart';
import '../models/movie_model.dart';
import '../models/vod_category_model.dart';

abstract class VodRemoteDataSource {
  Future<List<VodCategoryModel>> getVodCategories(XtreamCredentials creds);
  Future<List<MovieModel>> getVodStreams(XtreamCredentials creds, {String? categoryId});
  Future<MovieDetailsModel> getVodInfo(XtreamCredentials creds, int vodId);
}

class VodRemoteDataSourceImpl implements VodRemoteDataSource {
  final ApiClient apiClient;

  VodRemoteDataSourceImpl(this.apiClient);

  XtreamUrlBuilder _builderFor(XtreamCredentials creds) => XtreamUrlBuilder(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );

  @override
  Future<List<VodCategoryModel>> getVodCategories(XtreamCredentials creds) async {
    final uri = _builderFor(creds).action(AppConstants.actionGetVodCategories);
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows
        .map(VodCategoryModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<MovieModel>> getVodStreams(XtreamCredentials creds, {String? categoryId}) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetVodStreams,
      categoryId != null ? {'category_id': categoryId} : null,
    );
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows.map(MovieModel.fromJson).toList(growable: false);
  }

  @override
  Future<MovieDetailsModel> getVodInfo(XtreamCredentials creds, int vodId) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetVodInfo,
      {'vod_id': '$vodId'},
    );
    final response = await apiClient.get(uri);
    final json = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    return MovieDetailsModel.fromJson(json);
  }
}
