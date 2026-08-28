import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/category_entity.dart';
import '../entities/channel_entity.dart';
import '../entities/epg_program_entity.dart';

abstract class LiveTvRepository {
  Future<Result<List<CategoryEntity>>> getCategories(XtreamCredentials creds);

  Future<Result<List<ChannelEntity>>> getChannels(
    XtreamCredentials creds, {
    String? categoryId,
  });

  Future<Result<EpgProgramEntity?>> getCurrentProgram(XtreamCredentials creds, int streamId);
}
