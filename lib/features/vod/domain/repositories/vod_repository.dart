import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/movie_details_entity.dart';
import '../entities/movie_entity.dart';
import '../entities/vod_category_entity.dart';

abstract class VodRepository {
  Future<Result<List<VodCategoryEntity>>> getCategories(XtreamCredentials creds);

  Future<Result<List<MovieEntity>>> getMovies(XtreamCredentials creds, {String? categoryId});

  Future<Result<MovieDetailsEntity>> getMovieDetails(XtreamCredentials creds, int vodId);
}
