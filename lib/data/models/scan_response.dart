import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'scan_response.g.dart';

@JsonSerializable()
class ScanResponse extends Equatable {
  @JsonKey(name: 'event_id')
  final int? eventId;
  final String? error;

  const ScanResponse({this.eventId, this.error});

  factory ScanResponse.fromJson(Map<String, dynamic> json) =>
      _$ScanResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScanResponseToJson(this);

  @override
  List<Object?> get props => [eventId, error];
}