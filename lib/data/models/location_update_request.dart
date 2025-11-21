import 'package:json_annotation/json_annotation.dart';

part 'location_update_request.g.dart';

@JsonSerializable()
class LocationUpdateRequest {
  @JsonKey(name: 'api_key')
  final String apiKey;
  @JsonKey(name: 'session_id')
  final int sessionId;
  final double lat;
  final double lon;
  final double? accuracy;
  final String? timestamp;

  LocationUpdateRequest({
    required this.apiKey,
    required this.sessionId,
    required this.lat,
    required this.lon,
    this.accuracy,
    this.timestamp,
  });

  Map<String, dynamic> toJson() => _$LocationUpdateRequestToJson(this);
}