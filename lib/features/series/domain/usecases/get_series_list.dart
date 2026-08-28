import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/series_entity.dart';
import '../repositories/series_repository.dart';

class GetSeriesList {
  final SeriesRepository repository;

  GetSeriesList(this.repository);

  Future<Result<List<SeriesEntity>>> call(XtreamCredentials creds, {String? categoryId}) {
    return repository.getSeries(creds, categoryId: categoryId);
  }
}
