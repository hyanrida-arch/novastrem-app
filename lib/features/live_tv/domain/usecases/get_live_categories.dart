import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/category_entity.dart';
import '../repositories/live_tv_repository.dart';

class GetLiveCategories {
  final LiveTvRepository repository;

  GetLiveCategories(this.repository);

  Future<Result<List<CategoryEntity>>> call(XtreamCredentials creds) {
    return repository.getCategories(creds);
  }
}
