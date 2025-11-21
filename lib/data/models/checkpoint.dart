import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'checkpoint.g.dart';

@JsonSerializable()
class Checkpoint extends Equatable {
  final int id;
  final String name;
  final String code;
  final double? latitude;
  final double? longitude;
  final String? description;

  const Checkpoint({
    required this.id,
    required this.name,
    required this.code,
    this.latitude,
    this.longitude,
    this.description,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json) =>
      _$CheckpointFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointToJson(this);

  @override
  List<Object?> get props => [id, name, code, latitude, longitude, description];
}