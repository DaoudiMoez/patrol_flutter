// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_patrol_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartPatrolResponse _$StartPatrolResponseFromJson(Map<String, dynamic> json) =>
    StartPatrolResponse(
      sessionId: (json['session_id'] as num?)?.toInt(),
      name: json['name'] as String?,
      error: json['error'] as String?,
      route: json['route'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$StartPatrolResponseToJson(
        StartPatrolResponse instance) =>
    <String, dynamic>{
      'session_id': instance.sessionId,
      'name': instance.name,
      'error': instance.error,
      'route': instance.route,
    };
