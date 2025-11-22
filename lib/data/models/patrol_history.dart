import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'patrol_history.g.dart';

@JsonSerializable()
class PatrolHistory extends Equatable {
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'user_name')
  final String userName;
  @JsonKey(name: 'start_time')
  final DateTime startTime;
  @JsonKey(name: 'end_time')
  final DateTime? endTime;
  @JsonKey(name: 'state')
  final String status;
  final List<PatrolCheckpointHistory> checkpoints;
  @JsonKey(name: 'location_points')
  final List<PatrolLocationPoint> locationPoints;
  @JsonKey(name: 'map_image')
  final String? mapImageUrl;
  @JsonKey(name: 'total_distance')
  final double? totalDistance;
  final int? duration;

  const PatrolHistory({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.checkpoints,
    required this.locationPoints,
    this.mapImageUrl,
    this.totalDistance,
    this.duration,
  });

  factory PatrolHistory.fromJson(Map<String, dynamic> json) =>
      _$PatrolHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PatrolHistoryToJson(this);

  String get formattedDuration {
    if (duration == null) return 'N/A';
    final hours = duration! ~/ 3600;
    final minutes = (duration! % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  String get formattedDistance {
    if (totalDistance == null) return 'N/A';
    if (totalDistance! < 1000) {
      return '${totalDistance!.toStringAsFixed(0)}m';
    }
    return '${(totalDistance! / 1000).toStringAsFixed(2)}km';
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    userName,
    startTime,
    endTime,
    status,
    checkpoints,
    locationPoints
  ];
}

@JsonSerializable()
class PatrolCheckpointHistory extends Equatable {
  @JsonKey(name: 'checkpoint_id')
  final int checkpointId;
  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;
  @JsonKey(name: 'scan_time')
  final DateTime? scannedAt;
  @JsonKey(name: 'is_completed')
  final bool isCompleted;
  @JsonKey(name: 'sequence')
  final int orderInRoute;

  const PatrolCheckpointHistory({
    required this.checkpointId,
    required this.checkpointName,
    this.scannedAt,
    required this.isCompleted,
    required this.orderInRoute,
  });

  factory PatrolCheckpointHistory.fromJson(Map<String, dynamic> json) =>
      _$PatrolCheckpointHistoryFromJson(json);

  Map<String, dynamic> toJson() => _$PatrolCheckpointHistoryToJson(this);

  @override
  List<Object?> get props =>
      [checkpointId, checkpointName, scannedAt, isCompleted, orderInRoute];
}

@JsonSerializable()
class PatrolLocationPoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const PatrolLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory PatrolLocationPoint.fromJson(Map<String, dynamic> json) =>
      _$PatrolLocationPointFromJson(json);

  Map<String, dynamic> toJson() => _$PatrolLocationPointToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}