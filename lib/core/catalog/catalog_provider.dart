import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/live_tv/presentation/providers/live_tv_provider.dart';
import '../../features/series/presentation/providers/series_provider.dart';
import '../../features/vod/presentation/providers/vod_provider.dart';
import '../error/failures.dart';
import 'prepared_catalog.dart';

/// Stages of first-run preparation, in order. [label] is what the
/// initialization screen shows the user.
enum InitPhase {
  connecting('Connecting to server…'),
  liveTv('Fetching Live TV channels…'),
  movies('Fetching Movies…'),
  series('Fetching Series…'),
  sorting('Sorting your library…'),
  ready('Preparing your experience…'),
  failed('Something went wrong.');

  final String label;
  const InitPhase(this.label);
}

@immutable
class CatalogState {
  final InitPhase phase;
  final PreparedCatalog catalog;
  final String? error;

  /// When the catalog last finished loading, or null if it never has.
  /// Settings' "Last refresh" reads this instead of inventing a date.
  final DateTime? loadedAt;

  const CatalogState({
    this.phase = InitPhase.connecting,
    this.catalog = PreparedCatalog.empty,
    this.error,
    this.loadedAt,
  });

  bool get isReady => phase == InitPhase.ready;
  bool get hasFailed => phase == InitPhase.failed;

  /// 0..1 for the splash progress bar, derived from the phase so the bar
  /// and the status text can never disagree.
  double get progress {
    if (hasFailed) return 1;
    return (phase.index + 1) / InitPhase.ready.index.clamp(1, 999);
  }

  CatalogState copyWith({InitPhase? phase, PreparedCatalog? catalog, String? error}) {
    return CatalogState(
      phase: phase ?? this.phase,
      catalog: catalog ?? this.catalog,
      error: error,
      loadedAt: loadedAt,
    );
  }
}

/// Owns the one-time catalog load: fetches every section, then hands the
/// sorting to a background isolate so the UI thread never stalls.
///
/// Screens read the finished [PreparedCatalog] instead of re-deriving it,
/// which is what keeps `build` cheap.
class CatalogController extends StateNotifier<CatalogState> {
  final Ref _ref;

  CatalogController(this._ref) : super(const CatalogState());

  Future<void> load() async {
    state = const CatalogState(phase: InitPhase.connecting);
    try {
      // Each section is awaited in turn so the status text reflects real
      // progress rather than a fake timeline. They're cheap relative to the
      // sort, and sequencing keeps a slow panel from opening N sockets at
      // once.
      state = state.copyWith(phase: InitPhase.liveTv);
      final liveCategories = await _ref.read(liveCategoriesProvider.future);
      final channels = await _ref.read(liveChannelsProvider(null).future);

      state = state.copyWith(phase: InitPhase.movies);
      final vodCategories = await _ref.read(vodCategoriesProvider.future);
      final movies = await _ref.read(moviesProvider(null).future);

      state = state.copyWith(phase: InitPhase.series);
      final seriesCategories = await _ref.read(seriesCategoriesProvider.future);
      final series = await _ref.read(seriesListProvider(null).future);

      state = state.copyWith(phase: InitPhase.sorting);
      final raw = RawCatalog(
        channels: channels,
        liveCategories: liveCategories,
        movies: movies,
        vodCategories: vodCategories,
        series: series,
        seriesCategories: seriesCategories,
      );

      // `compute` spawns a short-lived isolate; the UI keeps animating
      // while the catalog is sorted.
      final prepared = await compute(prepareCatalog, raw);

      state = CatalogState(
        phase: InitPhase.ready,
        catalog: prepared,
        loadedAt: DateTime.now(),
      );
    } on Failure catch (f) {
      // Providers rethrow domain Failures; show the human message rather
      // than the Equatable toString ("UnknownFailure(...)").
      state = CatalogState(phase: InitPhase.failed, error: f.message, loadedAt: state.loadedAt);
    } catch (e) {
      state = CatalogState(phase: InitPhase.failed, error: e.toString(), loadedAt: state.loadedAt);
    }
  }

  /// Drops every cached section response and reloads from the provider.
  /// This is what Settings > Playlists > "Refresh all" calls — without the
  /// invalidation the `FutureProvider`s would just hand back their cached
  /// lists and nothing would actually be refetched.
  Future<void> refresh() async {
    _ref.invalidate(liveCategoriesProvider);
    _ref.invalidate(liveChannelsProvider);
    _ref.invalidate(vodCategoriesProvider);
    _ref.invalidate(moviesProvider);
    _ref.invalidate(seriesCategoriesProvider);
    _ref.invalidate(seriesListProvider);
    await load();
  }
}

final catalogControllerProvider =
    StateNotifierProvider<CatalogController, CatalogState>((ref) => CatalogController(ref));

/// Convenience for screens: the finished catalog (empty until ready).
final preparedCatalogProvider = Provider<PreparedCatalog>(
  (ref) => ref.watch(catalogControllerProvider).catalog,
);
