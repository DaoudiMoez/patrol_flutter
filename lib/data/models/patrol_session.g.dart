// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patrol_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PatrolSession _$PatrolSessionFromJson(Map<String, dynamic> json) =>
    PatrolSession(
      id: (json['session_id'] as num).toInt(),
      name: json['name'] as String,
      startTime: json['start_time'] == null
          ? null
          : DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] == null
          ? null
          : DateTime.parse(json['end_time'] as String),
      state: json['state'] as String?,
    );

Map<String, dynamic> _$PatrolSessionToJson(PatrolSession instance) =>
    <String, dynamic>{
      'session_id': instance.id,
      'name': instance.name,
      'start_time': instance.startTime?.toIso8601String(),
      'end_time': instance.endTime?.toIso8601String(),
      'state': instance.state,
    };
