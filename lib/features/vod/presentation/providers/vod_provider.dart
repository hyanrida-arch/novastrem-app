import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_content.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/providers/xtream_session_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/vod_remote_datasource.dart';
import '../../data/repositories/vod_repository_impl.dart';
import '../../domain/entities/movie_details_entity.dart';
import '../../domain/entities/movie_entity.dart';
import '../../domain/entities/vod_category_entity.dart';
import '../../domain/repositories/vod_repository.dart';
import '../../domain/usecases/get_movie_details.dart';
import '../../domain/usecases/get_movies.dart';
import '../../domain/usecases/get_vod_categories.dart';

// ---------------------------------------------------------------------------
// Dependency wiring
// ---------------------------------------------------------------------------

final vodRemoteDataSourceProvider = Provider<VodRemoteDataSource>(
  (ref) => VodRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final vodRepositoryProvider = Provider<VodRepository>(
  (ref) => VodRepositoryImpl(ref.watch(vodRemoteDataSourceProvider)),
);

final getVodCategoriesProvider =
    Provider((ref) => GetVodCategories(ref.watch(vodRepositoryProvider)));

final getMoviesProvider = Provider((ref) => GetMovies(ref.watch(vodRepositoryProvider)));

final getMovieDetailsProvider =
    Provider((ref) => GetMovieDetails(ref.watch(vodRepositoryProvider)));

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

final vodCategoriesProvider = FutureProvider.autoDispose<List<VodCategoryEntity>>((ref) async {
  if (ref.watch(isDemoSessionProvider)) return DemoContent.vodCategories;

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Movies require an Xtream Codes login.');
  }
  final result = await ref.watch(getVodCategoriesProvider).call(creds);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final moviesProvider =
    FutureProvider.autoDispose.family<List<MovieEntity>, String?>((ref, categoryId) async {
  if (ref.watch(isDemoSessionProvider)) {
    return categoryId == null
        ? DemoContent.movies
        : DemoContent.movies.where((m) => m.categoryId == categoryId).toList();
  }

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Movies require an Xtream Codes login.');
  }
  final result = await ref.watch(getMoviesProvider).call(creds, categoryId: categoryId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

final movieDetailsProvider =
    FutureProvider.autoDispose.family<MovieDetailsEntity, int>((ref, vodId) async {
  if (ref.watch(isDemoSessionProvider)) {
    final details = DemoContent.movieDetails[vodId];
    if (details == null) throw const ServerFailure('Demo movie not found.');
    return details;
  }

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Movies require an Xtream Codes login.');
  }
  final result = await ref.watch(getMovieDetailsProvider).call(creds, vodId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});
