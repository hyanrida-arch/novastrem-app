import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_content.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/providers/xtream_session_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/series_remote_datasource.dart';
import '../../data/repositories/series_repository_impl.dart';
import '../../domain/entities/series_category_entity.dart';
import '../../domain/entities/series_details_entity.dart';
import '../../domain/entities/series_entity.dart';
import '../../domain/repositories/series_repository.dart';
import '../../domain/usecases/get_series_categories.dart';
import '../../domain/usecases/get_series_details.dart';
import '../../domain/usecases/get_series_list.dart';

// ---------------------------------------------------------------------------
// Dependency wiring
// ---------------------------------------------------------------------------

final seriesRemoteDataSourceProvider = Provider<SeriesRemoteDataSource>(
  (ref) => SeriesRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final seriesRepositoryProvider = Provider<SeriesRepository>(
  (ref) => SeriesRepositoryImpl(ref.watch(seriesRemoteDataSourceProvider)),
);

final getSeriesCategoriesProvider =
    Provider((ref) => GetSeriesCategories(ref.watch(seriesRepositoryProvider)));

final getSeriesListProvider =
    Provider((ref) => GetSeriesList(ref.watch(seriesRepositoryProvider)));

final getSeriesDetailsProvider =
    Provider((ref) => GetSeriesDetails(ref.watch(seriesRepositoryProvider)));

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

final seriesCategoriesProvider = FutureProvider.autoDispose<List<SeriesCategoryEntity>>((ref) async {
  if (ref.watch(isDemoSessionProvider)) return DemoContent.seriesCategories;

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Series require an Xtream Codes login.');
  }
  final result = await ref.watch(getSeriesCategoriesProvider).call(creds);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final seriesListProvider =
    FutureProvider.autoDispose.family<List<SeriesEntity>, String?>((ref, categoryId) async {
  if (ref.watch(isDemoSessionProvider)) {
    return categoryId == null
        ? DemoContent.seriesList
        : DemoContent.seriesList.where((s) => s.categoryId == categoryId).toList();
  }

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Series require an Xtream Codes login.');
  }
  final result = await ref.watch(getSeriesListProvider).call(creds, categoryId: categoryId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final seriesDetailsProvider =
    FutureProvider.autoDispose.family<SeriesDetailsEntity, int>((ref, seriesId) async {
  if (ref.watch(isDemoSessionProvider)) {
    final details = DemoContent.seriesDetails[seriesId];
    if (details == null) throw const ServerFailure('Demo series not found.');
    return details;
  }

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Series require an Xtream Codes login.');
  }
  final result = await ref.watch(getSeriesDetailsProvider).call(creds, seriesId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});
