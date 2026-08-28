import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/series_details_entity.dart';
import '../repositories/series_repository.dart';

class GetSeriesDetails {
  final SeriesRepository repository;

  GetSeriesDetails(this.repository);

  Future<Result<SeriesDetailsEntity>> call(XtreamCredentials creds, int seriesId) {
    return repository.getSeriesDetails(creds, seriesId);
  }
}
