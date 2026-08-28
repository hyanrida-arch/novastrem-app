import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/vod_category_entity.dart';
import '../repositories/vod_repository.dart';

class GetVodCategories {
  final VodRepository repository;

  GetVodCategories(this.repository);

  Future<Result<List<VodCategoryEntity>>> call(XtreamCredentials creds) {
    return repository.getCategories(creds);
  }
}
