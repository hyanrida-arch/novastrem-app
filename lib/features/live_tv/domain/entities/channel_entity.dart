import 'package:equatable/equatable.dart';

/// A single Live TV channel within a category.
class ChannelEntity extends Equatable {
  final int streamId;
  final String name;
  final String? streamIcon;
  final String categoryId;
  final String? epgChannelId;
  final bool hasArchive;

  const ChannelEntity({
    required this.streamId,
    required this.name,
    required this.categoryId,
    this.streamIcon,
    this.epgChannelId,
    this.hasArchive = false,
  });

  @override
  List<Object?> get props => [streamId, name, streamIcon, categoryId, epgChannelId, hasArchive];
}
