import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/channel_entity.dart';
import '../repositories/live_tv_repository.dart';

class GetLiveChannels {
  final LiveTvRepository repository;

  GetLiveChannels(this.repository);

  Future<Result<List<ChannelEntity>>> call(XtreamCredentials creds, {String? categoryId}) {
    return repository.getChannels(creds, categoryId: categoryId);
  }
}
