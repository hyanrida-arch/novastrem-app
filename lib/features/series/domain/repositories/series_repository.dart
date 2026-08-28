import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/series_category_entity.dart';
import '../entities/series_details_entity.dart';
import '../entities/series_entity.dart';

abstract class SeriesRepository {
  Future<Result<List<SeriesCategoryEntity>>> getCategories(XtreamCredentials creds);

  Future<Result<List<SeriesEntity>>> getSeries(XtreamCredentials creds, {String? categoryId});

  Future<Result<SeriesDetailsEntity>> getSeriesDetails(XtreamCredentials creds, int seriesId);
}
