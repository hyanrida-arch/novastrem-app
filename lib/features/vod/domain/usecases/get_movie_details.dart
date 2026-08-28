import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/movie_details_entity.dart';
import '../repositories/vod_repository.dart';

class GetMovieDetails {
  final VodRepository repository;

  GetMovieDetails(this.repository);

  Future<Result<MovieDetailsEntity>> call(XtreamCredentials creds, int vodId) {
    return repository.getMovieDetails(creds, vodId);
  }
}
