import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/series_category_entity.dart';
import '../repositories/series_repository.dart';

class GetSeriesCategories {
  final SeriesRepository repository;

  GetSeriesCategories(this.repository);

  Future<Result<List<SeriesCategoryEntity>>> call(XtreamCredentials creds) {
    return repository.getCategories(creds);
  }
}
