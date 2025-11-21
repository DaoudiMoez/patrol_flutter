import 'package:json_annotation/json_annotation.dart';

part 'scan_request.g.dart';

@JsonSerializable()
class ScanRequest {
  @JsonKey(name: 'api_key')
  final String apiKey;
  @JsonKey(name: 'session_id')
  final int sessionId;
  final String code;
  @JsonKey(name: 'scan_type')
  final String scanType;
  final double lat;
  final double lon;
  final double? accuracy;
  final String? timestamp;
  final String? note;

  ScanRequest({
    required this.apiKey,
    required this.sessionId,
    required this.code,
    required this.scanType,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.timestamp,
    this.note,
  });

  Map<String, dynamic> toJson() => _$ScanRequestToJson(this);
}