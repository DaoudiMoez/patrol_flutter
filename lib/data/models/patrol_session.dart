import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patrol_session.g.dart';

@JsonSerializable()
class PatrolSession extends Equatable {
  @JsonKey(name: 'session_id')
  final int id;
  final String name;
  @JsonKey(name: 'start_time')
  final DateTime? startTime;
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  final String? state;

  const PatrolSession({
    required this.id,
    required this.name,
    this.startTime,
    this.endTime,
    this.state,
  });

  factory PatrolSession.fromJson(Map<String, dynamic> json) =>
      _$PatrolSessionFromJson(json);

  Map<String, dynamic> toJson() => _$PatrolSessionToJson(this);

  @override
  List<Object?> get props => [id, name, startTime, endTime, state];
}