// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patrol_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatrolHistory _$PatrolHistoryFromJson(Map<String, dynamic> json) =>
    PatrolHistory(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      userName: json['user_name'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      status: json['state'] as String,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) =>
              PatrolCheckpointHistory.fromJson(e as Map<String, dynamic>))
          .toList(),
      locationPoints: (json['location_points'] as List<dynamic>)
          .map((e) => PatrolLocationPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      mapImageUrl: json['map_image'] as String?,
      totalDistance: (json['total_distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PatrolHistoryToJson(PatrolHistory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'user_name': instance.userName,
      'start_time': instance.startTime.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'state': instance.status,
      'checkpoints': instance.checkpoints,
      'location_points': instance.locationPoints,
      'map_image': instance.mapImageUrl,
      'total_distance': instance.totalDistance,
      'duration': instance.duration,
    };

PatrolCheckpointHistory _$PatrolCheckpointHistoryFromJson(
        Map<String, dynamic> json) =>
    PatrolCheckpointHistory(
      checkpointId: (json['checkpoint_id'] as num).toInt(),
      checkpointName: json['checkpoint_name'] as String,
      scannedAt: json['scan_time'] == null
          ? null
          : DateTime.parse(json['scan_time'] as String),
      isCompleted: json['is_completed'] as bool,
      orderInRoute: (json['sequence'] as num).toInt(),
    );

Map<String, dynamic> _$PatrolCheckpointHistoryToJson(
        PatrolCheckpointHistory instance) =>
    <String, dynamic>{
      'checkpoint_id': instance.checkpointId,
      'checkpoint_name': instance.checkpointName,
      'scan_time': instance.scannedAt?.toIso8601String(),
      'is_completed': instance.isCompleted,
      'sequence': instance.orderInRoute,
    };

PatrolLocationPoint _$PatrolLocationPointFromJson(Map<String, dynamic> json) =>
    PatrolLocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$PatrolLocationPointToJson(
        PatrolLocationPoint instance) =>
    <String, dynamic>{
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'timestamp': instance.timestamp.toIso8601String(),
    };
