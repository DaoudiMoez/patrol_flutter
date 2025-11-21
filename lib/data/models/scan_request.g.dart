// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScanRequest _$ScanRequestFromJson(Map<String, dynamic> json) => ScanRequest(
      apiKey: json['api_key'] as String,
      sessionId: (json['session_id'] as num).toInt(),
      code: json['code'] as String,
      scanType: json['scan_type'] as String,
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as String?,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$ScanRequestToJson(ScanRequest instance) =>
    <String, dynamic>{
      'api_key': instance.apiKey,
      'session_id': instance.sessionId,
      'code': instance.code,
      'scan_type': instance.scanType,
      'lat': instance.lat,
      'lon': instance.lon,
      'accuracy': instance.accuracy,
      'timestamp': instance.timestamp,
      'note': instance.note,
    };
