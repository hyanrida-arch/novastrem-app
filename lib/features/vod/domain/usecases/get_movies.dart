import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/movie_entity.dart';
import '../repositories/vod_repository.dart';

class GetMovies {
  final VodRepository repository;

  GetMovies(this.repository);

  Future<Result<List<MovieEntity>>> call(XtreamCredentials creds, {String? categoryId}) {
    return repository.getMovies(creds, categoryId: categoryId);
  }
}
