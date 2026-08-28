import 'package:hive/hive.dart';

import '../../domain/entities/user_login_entity.dart';

/// Hive-persisted version of [UserLoginEntity].
///
/// `typeId: 0` is reserved for this model — if you add more `@HiveType`
/// classes later, keep the ids stable and unique across the whole app.
///
/// NOTE: The [UserLoginModelAdapter] below is hand-written (rather than
/// produced by `hive_generator`/`build_runner`) to keep this project
/// buildable without a code-generation step. If you'd rather generate it,
/// add `@HiveType`/`@HiveField` are already in place — just wire up
/// `hive_generator` + `build_runner` and delete the adapter class.
class UserLoginModel {
  final int playlistTypeIndex; // PlaylistType.index
  final String playlistName;
  final String? serverUrl;
  final String? username;
  final String? password;
  final String? m3uUrl;
  final String? status;
  final int? expiryDateEpochSeconds;
  final int? activeConnections;
  final int? maxConnections;

  const UserLoginModel({
    required this.playlistTypeIndex,
    required this.playlistName,
    this.serverUrl,
    this.username,
    this.password,
    this.m3uUrl,
    this.status,
    this.expiryDateEpochSeconds,
    this.activeConnections,
    this.maxConnections,
  });

  factory UserLoginModel.fromEntity(UserLoginEntity entity) {
    return UserLoginModel(
      playlistTypeIndex: entity.type.index,
      playlistName: entity.playlistName,
      serverUrl: entity.serverUrl,
      username: entity.username,
      password: entity.password,
      m3uUrl: entity.m3uUrl,
      status: entity.status,
      expiryDateEpochSeconds: entity.expiryDate == null
          ? null
          : entity.expiryDate!.millisecondsSinceEpoch ~/ 1000,
      activeConnections: entity.activeConnections,
      maxConnections: entity.maxConnections,
    );
  }

  UserLoginEntity toEntity() {
    return UserLoginEntity(
      type: PlaylistType.values[playlistTypeIndex],
      playlistName: playlistName,
      serverUrl: serverUrl,
      username: username,
      password: password,
      m3uUrl: m3uUrl,
      status: status,
      expiryDate: expiryDateEpochSeconds == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(expiryDateEpochSeconds! * 1000),
      activeConnections: activeConnections,
      maxConnections: maxConnections,
    );
  }
}

/// Hand-written Hive `TypeAdapter` (see class doc above for why).
class UserLoginModelAdapter extends TypeAdapter<UserLoginModel> {
  @override
  final int typeId = 0;

  @override
  UserLoginModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };
    return UserLoginModel(
      playlistTypeIndex: fields[0] as int,
      playlistName: fields[1] as String,
      serverUrl: fields[2] as String?,
      username: fields[3] as String?,
      password: fields[4] as String?,
      m3uUrl: fields[5] as String?,
      status: fields[6] as String?,
      expiryDateEpochSeconds: fields[7] as int?,
      activeConnections: fields[8] as int?,
      maxConnections: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, UserLoginModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.playlistTypeIndex)
      ..writeByte(1)
      ..write(obj.playlistName)
      ..writeByte(2)
      ..write(obj.serverUrl)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.password)
      ..writeByte(5)
      ..write(obj.m3uUrl)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.expiryDateEpochSeconds)
      ..writeByte(8)
      ..write(obj.activeConnections)
      ..writeByte(9)
      ..write(obj.maxConnections);
  }
}
