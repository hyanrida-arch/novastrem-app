import 'package:equatable/equatable.dart';

/// A single playable episode within a season.
class EpisodeEntity extends Equatable {
  final int episodeId;
  final String title;
  final int episodeNum;
  final int season;
  final String containerExtension;

  const EpisodeEntity({
    required this.episodeId,
    required this.title,
    required this.episodeNum,
    required this.season,
    this.containerExtension = 'mp4',
  });

  @override
  List<Object?> get props => [episodeId, title, episodeNum, season, containerExtension];
}
