import '../../domain/entities/channel_entity.dart';

/// Maps a single entry from `get_live_streams` to [ChannelEntity].
///
/// Example payload (trimmed):
/// ```json
/// {
///   "num": 1,
///   "name": "CNN HD",
///   "stream_type": "live",
///   "stream_id": 10321,
///   "stream_icon": "http://provider.com/logos/cnn.png",
///   "epg_channel_id": "cnn.us",
///   "category_id": "5",
///   "tv_archive": 1
/// }
/// ```
class ChannelModel {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String categoryId;
  final String? epgChannelId;
  final int tvArchive;

  const ChannelModel({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.epgChannelId,
    this.tvArchive = 0,
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      streamId: int.tryParse('${json['stream_id']}') ?? 0,
      name: (json['name'] ?? 'Unknown channel').toString(),
      streamIcon: json['stream_icon']?.toString(),
      categoryId: json['category_id'].toString(),
      epgChannelId: json['epg_channel_id']?.toString(),
      tvArchive: int.tryParse('${json['tv_archive'] ?? 0}') ?? 0,
    );
  }

  ChannelEntity toEntity() => ChannelEntity(
        streamId: streamId,
        name: name,
        streamIcon: streamIcon,
        categoryId: categoryId,
        epgChannelId: epgChannelId,
        hasArchive: tvArchive == 1,
      );
}
