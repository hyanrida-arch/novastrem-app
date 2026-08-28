import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/xtream_response.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/movie_details_entity.dart';
import '../../domain/entities/movie_entity.dart';
import '../../domain/entities/vod_category_entity.dart';
import '../../domain/repositories/vod_repository.dart';
import '../datasources/vod_remote_datasource.dart';

class VodRepositoryImpl implements VodRepository {
  final VodRemoteDataSource remote;

  VodRepositoryImpl(this.remote);

  @override
  Future<Result<List<VodCategoryEntity>>> getCategories(XtreamCredentials creds) async {
    try {
      final models = await remote.getVodCategories(creds);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } on XtreamApiException catch (e) {
      // The panel answered, but told us something actionable —
      // expired subscription, rejected credentials, an error payload.
      return Result.failure(ServerFailure(e.message));
    } catch (e, stack) {
      // Non-Dio failures are almost always a parsing problem (a panel
      // returning HTML instead of JSON, an unexpected field shape).
      // Surface the detail instead of discarding it — a bare
      // "unexpected error" is undiagnosable from a device.
      if (kDebugMode) debugPrint('[NovaStream] parse/unknown failure: $e\n$stack');
      return Result.failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<List<MovieEntity>>> getMovies(
    XtreamCredentials creds, {
    String? categoryId,
  }) async {
    try {
      final models = await remote.getVodStreams(creds, categoryId: categoryId);
      return Result.success(models.map((m) => m.toEntity()).toList());
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } on XtreamApiException catch (e) {
      // The panel answered, but told us something actionable —
      // expired subscription, rejected credentials, an error payload.
      return Result.failure(ServerFailure(e.message));
    } catch (e, stack) {
      // Non-Dio failures are almost always a parsing problem (a panel
      // returning HTML instead of JSON, an unexpected field shape).
      // Surface the detail instead of discarding it — a bare
      // "unexpected error" is undiagnosable from a device.
      if (kDebugMode) debugPrint('[NovaStream] parse/unknown failure: $e\n$stack');
      return Result.failure(UnknownFailure('Unexpected error: $e'));
    }
  }

  @override
  Future<Result<MovieDetailsEntity>> getMovieDetails(XtreamCredentials creds, int vodId) async {
    try {
      final model = await remote.getVodInfo(creds, vodId);
      return Result.success(model.toEntity());
    } on DioException catch (e) {
      return Result.failure(mapDioError(e));
    } on XtreamApiException catch (e) {
      // The panel answered, but told us something actionable —
      // expired subscription, rejected credentials, an error payload.
      return Result.failure(ServerFailure(e.message));
    } catch (e, stack) {
      // Non-Dio failures are almost always a parsing problem (a panel
      // returning HTML instead of JSON, an unexpected field shape).
      // Surface the detail instead of discarding it — a bare
      // "unexpected error" is undiagnosable from a device.
      if (kDebugMode) debugPrint('[NovaStream] parse/unknown failure: $e\n$stack');
      return Result.failure(UnknownFailure('Unexpected error: $e'));
    }
  }
}
