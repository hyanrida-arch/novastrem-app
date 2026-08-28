import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_content.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/providers/xtream_session_provider.dart';
import '../../data/datasources/live_tv_remote_datasource.dart';
import '../../data/repositories/live_tv_repository_impl.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/entities/channel_entity.dart';
import '../../domain/entities/epg_program_entity.dart';
import '../../domain/repositories/live_tv_repository.dart';
import '../../domain/usecases/get_current_epg_program.dart';
import '../../domain/usecases/get_live_categories.dart';
import '../../domain/usecases/get_live_channels.dart';

// ---------------------------------------------------------------------------
// Dependency wiring
// ---------------------------------------------------------------------------

final liveTvRemoteDataSourceProvider = Provider<LiveTvRemoteDataSource>(
  (ref) => LiveTvRemoteDataSourceImpl(ref.watch(apiClientProvider)),
);

final liveTvRepositoryProvider = Provider<LiveTvRepository>(
  (ref) => LiveTvRepositoryImpl(ref.watch(liveTvRemoteDataSourceProvider)),
);

final getLiveCategoriesProvider =
    Provider((ref) => GetLiveCategories(ref.watch(liveTvRepositoryProvider)));

final getLiveChannelsProvider =
    Provider((ref) => GetLiveChannels(ref.watch(liveTvRepositoryProvider)));

final getCurrentEpgProgramProvider =
    Provider((ref) => GetCurrentEpgProgram(ref.watch(liveTvRepositoryProvider)));

// ---------------------------------------------------------------------------
// Data providers (AsyncValue-friendly: throw on failure so `.when` on the
// FutureProvider's AsyncValue gives the UI loading/error/data for free)
// ---------------------------------------------------------------------------

final liveCategoriesProvider = FutureProvider.autoDispose<List<CategoryEntity>>((ref) async {
  if (ref.watch(isDemoSessionProvider)) return DemoContent.liveCategories;

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Live TV requires an Xtream Codes login.');
  }
  final result = await ref.watch(getLiveCategoriesProvider).call(creds);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// `categoryId == null` fetches every channel across all categories.
final liveChannelsProvider =
    FutureProvider.autoDispose.family<List<ChannelEntity>, String?>((ref, categoryId) async {
  if (ref.watch(isDemoSessionProvider)) {
    return categoryId == null
        ? DemoContent.liveChannels
        : DemoContent.liveChannels.where((c) => c.categoryId == categoryId).toList();
  }

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) {
    throw const AuthFailure('Live TV requires an Xtream Codes login.');
  }
  final result = await ref.watch(getLiveChannelsProvider).call(creds, categoryId: categoryId);
  return result.when(success: (data) => data, failure: (f) => throw f);
});

/// Current EPG program for a channel. Errors are swallowed to `null` rather
/// than thrown — a missing/broken EPG on one channel shouldn't put the
/// whole channel list into an error state; the row just shows no subtitle.
final currentEpgProvider = FutureProvider.autoDispose.family<EpgProgramEntity?, int>((ref, streamId) async {
  if (ref.watch(isDemoSessionProvider)) return DemoContent.epgFor(streamId);

  final creds = ref.watch(xtreamCredentialsProvider);
  if (creds == null) return null;

  final result = await ref.watch(getCurrentEpgProgramProvider).call(creds, streamId);
  return result.when(success: (data) => data, failure: (_) => null);
});
