import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'start_patrol_response.g.dart';

@JsonSerializable()
class StartPatrolResponse extends Equatable {
  @JsonKey(name: 'session_id')
  final int? sessionId;
  final String? name;
  final String? error;

  const StartPatrolResponse({
    this.sessionId,
    this.name,
    this.error,
  });

  factory StartPatrolResponse.fromJson(Map<String, dynamic> json) =>
      _$StartPatrolResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StartPatrolResponseToJson(this);

  @override
  List<Object?> get props => [sessionId, name, error];
}