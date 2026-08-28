import '../../features/live_tv/domain/entities/category_entity.dart';
import '../../features/live_tv/domain/entities/channel_entity.dart';
import '../../features/live_tv/domain/entities/epg_program_entity.dart';
import '../../features/series/domain/entities/episode_entity.dart';
import '../../features/series/domain/entities/series_category_entity.dart';
import '../../features/series/domain/entities/series_details_entity.dart';
import '../../features/series/domain/entities/series_entity.dart';
import '../../features/vod/domain/entities/movie_details_entity.dart';
import '../../features/vod/domain/entities/movie_entity.dart';
import '../../features/vod/domain/entities/vod_category_entity.dart';

/// Built-in, network-free sample catalog behind "Try Quick Demo Account".
///
/// It exists so the entire app — Live TV, Movies, Series, and real
/// `flutter_vlc_player` playback — can be explored with zero setup, no
/// Xtream/M3U account required. Every stream URL below is a freely
/// licensed/public test stream (Blender Foundation open movies, Apple's
/// and Mux's public HLS demo endpoints), not a real IPTV feed.
///
/// IDs are namespaced by feature (9xxx live, 91xx movies, 92xx/93xx series)
/// purely so [streamUrlFor] can do one flat lookup; they're otherwise
/// meaningless placeholders standing in for Xtream's `stream_id`.
///
/// Movie/series titles deliberately end in "(YYYY)" — that's the same
/// convention [extractYearFromTitle] parses for real catalogs, so the demo
/// exercises the exact same Release Year filter code path instead of a
/// separate demo-only shortcut.
abstract class DemoContent {
  DemoContent._();

  // ---------------------------------------------------------------------
  // Live TV
  // ---------------------------------------------------------------------

  static const liveCategories = [
    CategoryEntity(categoryId: 'demo-news', categoryName: 'News (Demo)'),
    CategoryEntity(categoryId: 'demo-entertainment', categoryName: 'Entertainment (Demo)'),
    CategoryEntity(categoryId: 'demo-sports', categoryName: 'Sports (Demo)'),
    CategoryEntity(categoryId: 'demo-kids', categoryName: 'Kids (Demo)'),
    CategoryEntity(categoryId: 'demo-movies-live', categoryName: 'Movies (Demo)'),
  ];

  static const liveChannels = [
    ChannelEntity(streamId: 9001, name: 'NovaStream News', categoryId: 'demo-news'),
    ChannelEntity(streamId: 9002, name: 'NovaStream Kids', categoryId: 'demo-kids'),
    ChannelEntity(streamId: 9003, name: 'NovaStream Movies Live', categoryId: 'demo-movies-live'),
    ChannelEntity(streamId: 9004, name: 'NovaStream Entertainment', categoryId: 'demo-entertainment'),
    ChannelEntity(streamId: 9005, name: 'NovaStream Sports 1', categoryId: 'demo-sports'),
  ];

  // ---------------------------------------------------------------------
  // Movies (VOD)
  // ---------------------------------------------------------------------

  static const vodCategories = [
    VodCategoryEntity(categoryId: 'demo-action', categoryName: 'Action (Demo)'),
    VodCategoryEntity(categoryId: 'demo-scifi', categoryName: 'Sci-Fi (Demo)'),
  ];

  /// `addedAt`/`lastModified` are relative to "now" so the demo catalog
  /// actually populates the "New This Week" / "New Seasons" rails the same
  /// way a real provider's timestamps would, instead of those rows being
  /// permanently empty in demo mode.
  static final List<MovieEntity> movies = [
    MovieEntity(
      streamId: 9101,
      name: 'Big Buck Bunny (2008)',
      categoryId: 'demo-action',
      rating: 7.8,
      addedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    MovieEntity(
      streamId: 9102,
      name: 'Tears of Steel (2012)',
      categoryId: 'demo-action',
      rating: 7.2,
      addedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    MovieEntity(
      streamId: 9103,
      name: 'Sintel (2010)',
      categoryId: 'demo-scifi',
      rating: 8.1,
      addedAt: DateTime.now().subtract(const Duration(days: 40)),
    ),
    MovieEntity(
      streamId: 9104,
      name: "Elephant's Dream (2006)",
      categoryId: 'demo-scifi',
      rating: 7.0,
      addedAt: DateTime.now().subtract(const Duration(days: 120)),
    ),
  ];

  static final Map<int, MovieDetailsEntity> movieDetails = {
    9101: const MovieDetailsEntity(
      streamId: 9101,
      name: 'Big Buck Bunny (2008)',
      description:
          'A giant rabbit deals with three bullying rodents, in this fan-favorite '
          'Blender Foundation open movie — NovaStream\'s sample title for trying out '
          'Movies playback.',
      genre: 'Animation, Comedy',
      director: 'Sacha Goedegebure',
      releaseDate: '2008-04-10',
      rating: 7.8,
      duration: '10m',
    ),
    9102: const MovieDetailsEntity(
      streamId: 9102,
      name: 'Tears of Steel (2012)',
      description:
          'A group of warriors and scientists gather in Amsterdam to stage a crucial '
          'event from the past, in this open-source sci-fi short from Blender Foundation.',
      genre: 'Sci-Fi',
      director: 'Ian Hubert',
      releaseDate: '2012-09-26',
      rating: 7.2,
      duration: '12m',
    ),
    9103: const MovieDetailsEntity(
      streamId: 9103,
      name: 'Sintel (2010)',
      description:
          'A lonely young woman, Sintel, helps and befriends a dragon, whom she '
          'calls Scales. Another Blender Foundation open movie.',
      genre: 'Fantasy, Adventure',
      director: 'Colin Levy',
      releaseDate: '2010-09-30',
      rating: 8.1,
      duration: '15m',
    ),
    9104: const MovieDetailsEntity(
      streamId: 9104,
      name: "Elephant's Dream (2006)",
      description:
          'Two strange characters explore a capricious and seemingly infinite '
          'machine. The first Blender Foundation open movie.',
      genre: 'Sci-Fi, Animation',
      director: 'Bassam Kurdali',
      releaseDate: '2006-03-24',
      rating: 7.0,
      duration: '11m',
    ),
  };

  // ---------------------------------------------------------------------
  // Series
  // ---------------------------------------------------------------------

  static const seriesCategories = [
    SeriesCategoryEntity(categoryId: 'demo-originals', categoryName: 'NovaStream Originals (Demo)'),
  ];

  static final List<SeriesEntity> seriesList = [
    SeriesEntity(
      seriesId: 9201,
      name: 'NovaStream Originals (2024)',
      categoryId: 'demo-originals',
      rating: 7.9,
      lastModified: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SeriesEntity(
      seriesId: 9202,
      name: 'Nova Chronicles (2023)',
      categoryId: 'demo-originals',
      rating: 7.4,
      lastModified: DateTime.now().subtract(const Duration(days: 90)),
    ),
  ];

  static final Map<int, SeriesDetailsEntity> seriesDetails = {
    9201: const SeriesDetailsEntity(
      seriesId: 9201,
      name: 'NovaStream Originals (2024)',
      description: 'A two-part sampler series demonstrating NovaStream\'s season/episode playback.',
      genre: 'Anthology',
      releaseDate: '2024-01-12',
      rating: 7.9,
      episodesBySeason: {
        1: [
          EpisodeEntity(episodeId: 9301, title: 'Pilot', episodeNum: 1, season: 1),
          EpisodeEntity(episodeId: 9302, title: 'The Signal', episodeNum: 2, season: 1),
        ],
      },
    ),
    9202: const SeriesDetailsEntity(
      seriesId: 9202,
      name: 'Nova Chronicles (2023)',
      description: 'A second sampler series, so category/season navigation has more than one show to show off.',
      genre: 'Anthology',
      releaseDate: '2023-11-03',
      rating: 7.4,
      episodesBySeason: {
        1: [
          EpisodeEntity(episodeId: 9303, title: 'Awakening', episodeNum: 1, season: 1),
          EpisodeEntity(episodeId: 9304, title: 'Echoes', episodeNum: 2, season: 1),
        ],
      },
    ),
  };

  // ---------------------------------------------------------------------
  // EPG ("what's on now")
  // ---------------------------------------------------------------------

  static const Map<int, List<String>> _epgRotation = {
    9001: ['Morning Bulletin', 'World Report', 'Business Hour', 'Evening Edition', 'Late Night Wrap-Up'],
    9002: ['Cartoon Carnival', "Kids' Adventure Hour", 'Storytime Special', 'Puzzle Playhouse'],
    9003: ['Blockbuster Hour', 'Director Spotlight', 'Classic Cinema', 'Premiere Night'],
    9004: ['Talk of the Town', 'Prime Variety', 'Late Show', 'Music Countdown'],
    9005: ['Matchday Live', 'Post-Game Analysis', 'Sports Roundup', 'Highlight Reel'],
  };

  /// Deterministic "now playing" program for a demo channel: the catalog is
  /// static, so programs rotate through fixed 30-minute slots keyed off the
  /// real clock — enough to make the progress bar/subtitle feel alive
  /// without needing a real EPG backend.
  static EpgProgramEntity? epgFor(int channelStreamId) {
    final titles = _epgRotation[channelStreamId];
    if (titles == null || titles.isEmpty) return null;

    final now = DateTime.now();
    final slotStart = DateTime(now.year, now.month, now.day, now.hour, now.minute - now.minute % 30);
    final slotEnd = slotStart.add(const Duration(minutes: 30));
    final slotsSinceMidnight = slotStart.hour * 2 + slotStart.minute ~/ 30;
    final title = titles[slotsSinceMidnight % titles.length];

    return EpgProgramEntity(title: title, start: slotStart, end: slotEnd);
  }

  // ---------------------------------------------------------------------
  // Playback resolution
  // ---------------------------------------------------------------------

  /// Freely licensed public test streams, standing in for real Xtream
  /// stream URLs so Play/Download actually work end-to-end in demo mode.
  ///
  /// NOTE: Google's old `commondatastorage.googleapis.com/gtv-videos-bucket`
  /// sample bucket (the "classic" Big Buck Bunny/Sintel demo URLs) now
  /// returns 403 — Google appears to have locked it down. Replaced with
  /// test-videos.co.uk (small, purpose-built H.264 test clips) and MDN's
  /// CC0 sample video set, both confirmed reachable. If you see download/
  /// playback failures again in the future, it's almost certainly this
  /// class of issue — a demo URL went dead — not app logic; curl -I the
  /// URL first before debugging the download/player code.
  static const Map<int, String> _streamUrls = {
    // Live TV -> public HLS demo endpoints (showcases .m3u8 playback).
    9001: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8',
    9002: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_fmp4/master.m3u8',
    9003: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    9004: 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    9005: 'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8',

    // Movies -> small public-domain/CC0 mp4 test clips (showcases .mp4 playback).
    9101: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    9102: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4',
    9103: 'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
    9104: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',

    // Series episodes -> reuse the same clips as stand-in episodes.
    9301: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/Big_Buck_Bunny_360_10s_1MB.mp4',
    9302: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/friday.mp4',
    9303: 'https://interactive-examples.mdn.mozilla.net/media/cc0-videos/flower.mp4',
    9304: 'https://test-videos.co.uk/vids/sintel/mp4/h264/360/Sintel_360_10s_1MB.mp4',
  };

  static String? streamUrlFor(int id) => _streamUrls[id];
}
