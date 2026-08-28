import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/network/dio_error_mapper.dart';
import '../../../../core/network/xtream_response.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/entities/epg_program_entity.dart';
import '../../domain/repositories/live_tv_repository.dart';
import '../datasources/live_tv_remote_datasource.dart';

class LiveTvRepositoryImpl implements LiveTvRepository {
  final LiveTvRemoteDataSource remote;

  LiveTvRepositoryImpl(this.remote);

  @override
  Future<Result<List<CategoryEntity>>> getCategories(XtreamCredentials creds) async {
    try {
      final models = await remote.getLiveCategories(creds);
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
  Future<Result<List<ChannelEntity>>> getChannels(
    XtreamCredentials creds, {
    String? categoryId,
  }) async {
    try {
      final models = await remote.getLiveStreams(creds, categoryId: categoryId);
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
  Future<Result<EpgProgramEntity?>> getCurrentProgram(XtreamCredentials creds, int streamId) async {
    try {
      final model = await remote.getShortEpg(creds, streamId);
      return Result.success(model?.toEntity());
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
