// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_patrol_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartPatrolRequest _$StartPatrolRequestFromJson(Map<String, dynamic> json) =>
    StartPatrolRequest(
      apiKey: json['api_key'] as String,
      deviceId: json['device_id'] as String,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$StartPatrolRequestToJson(StartPatrolRequest instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'device_id': instance.deviceId,
      'name': instance.name,
    };
