import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/xtream_response.dart';
import '../../../../core/utils/xtream_url_builder.dart';
import '../models/series_category_model.dart';
import '../models/series_details_model.dart';
import '../models/series_model.dart';

abstract class SeriesRemoteDataSource {
  Future<List<SeriesCategoryModel>> getSeriesCategories(XtreamCredentials creds);
  Future<List<SeriesModel>> getSeries(XtreamCredentials creds, {String? categoryId});
  Future<SeriesDetailsModel> getSeriesInfo(XtreamCredentials creds, int seriesId);
}

class SeriesRemoteDataSourceImpl implements SeriesRemoteDataSource {
  final ApiClient apiClient;

  SeriesRemoteDataSourceImpl(this.apiClient);

  XtreamUrlBuilder _builderFor(XtreamCredentials creds) => XtreamUrlBuilder(
        serverUrl: creds.serverUrl,
        username: creds.username,
        password: creds.password,
      );

  @override
  Future<List<SeriesCategoryModel>> getSeriesCategories(XtreamCredentials creds) async {
    final uri = _builderFor(creds).action(AppConstants.actionGetSeriesCategories);
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows
        .map(SeriesCategoryModel.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<SeriesModel>> getSeries(XtreamCredentials creds, {String? categoryId}) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetSeries,
      categoryId != null ? {'category_id': categoryId} : null,
    );
    final response = await apiClient.get(uri);
    final rows = parseXtreamRows(response.data);
    return rows.map(SeriesModel.fromJson).toList(growable: false);
  }

  @override
  Future<SeriesDetailsModel> getSeriesInfo(XtreamCredentials creds, int seriesId) async {
    final uri = _builderFor(creds).action(
      AppConstants.actionGetSeriesInfo,
      {'series_id': '$seriesId'},
    );
    final response = await apiClient.get(uri);
    final json = jsonDecode(response.data ?? '{}') as Map<String, dynamic>;
    return SeriesDetailsModel.fromJson(json, fallbackSeriesId: seriesId);
  }
}
