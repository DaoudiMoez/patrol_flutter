// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'location_update_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LocationUpdateRequest _$LocationUpdateRequestFromJson(
        Map<String, dynamic> json) =>
    LocationUpdateRequest(
      apiKey: json['api_key'] as String,
      sessionId: (json['session_id'] as num).toInt(),
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$LocationUpdateRequestToJson(
        LocationUpdateRequest instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'session_id': instance.sessionId,
      'lat': instance.lat,
      'lon': instance.lon,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp,
    };
