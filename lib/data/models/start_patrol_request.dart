import 'package:json_annotation/json_annotation.dart';

part 'start_patrol_request.g.dart';

@JsonSerializable()
class StartPatrolRequest {
  @JsonKey(name: 'api_key')
  final String apiKey;
  @JsonKey(name: 'device_id')
  final String deviceId;
  final String? name;

  StartPatrolRequest({
    required this.apiKey,
    required this.deviceId,
    this.name,
  });

  Map<String, dynamic> toJson() => _$StartPatrolRequestToJson(this);
}