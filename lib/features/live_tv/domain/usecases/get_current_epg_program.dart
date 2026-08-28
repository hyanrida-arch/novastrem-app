import '../../../../core/models/xtream_credentials.dart';
import '../../../../core/utils/result.dart';
import '../entities/epg_program_entity.dart';
import '../repositories/live_tv_repository.dart';

class GetCurrentEpgProgram {
  final LiveTvRepository repository;

  GetCurrentEpgProgram(this.repository);

  Future<Result<EpgProgramEntity?>> call(XtreamCredentials creds, int streamId) {
    return repository.getCurrentProgram(creds, streamId);
  }
}
