import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'route_config.g.dart';

@JsonSerializable()
class RouteConfig extends Equatable {
  final int id;
  final String name;
  final String description;
  @JsonKey(name: 'is_active')
  final bool isActive;
  final List<CheckpointOrder> checkpoints;
  @JsonKey(name: 'create_date')
  final DateTime? createdAt;
  @JsonKey(name: 'write_date')
  final DateTime? updatedAt;

  const RouteConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.isActive,
    required this.checkpoints,
    this.createdAt,
    this.updatedAt,
  });

  factory RouteConfig.fromJson(Map<String, dynamic> json) =>
      _$RouteConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RouteConfigToJson(this);

  @override
  List<Object?> get props => [id, name, description, isActive, checkpoints];
}

@JsonSerializable()
class CheckpointOrder extends Equatable {
  @JsonKey(name: 'checkpoint_id')
  final int checkpointId;
  @JsonKey(name: 'checkpoint_name')
  final String checkpointName;
  @JsonKey(name: 'sequence')
  final int order;
  @JsonKey(name: 'is_required')
  final bool isRequired;

  const CheckpointOrder({
    required this.checkpointId,
    required this.checkpointName,
    required this.order,
    this.isRequired = true,
  });

  factory CheckpointOrder.fromJson(Map<String, dynamic> json) =>
      _$CheckpointOrderFromJson(json);

  Map<String, dynamic> toJson() => _$CheckpointOrderToJson(this);

  @override
  List<Object?> get props => [checkpointId, checkpointName, order, isRequired];
}

// ============================================================
// Request models (no .g.dart needed as they're only for sending)
// ============================================================

class CreateRouteRequest {
  final String name;
  final String description;
  final List<CheckpointOrderRequest> checkpoints;

  CreateRouteRequest({
    required this.name,
    required this.description,
    required this.checkpoints,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'checkpoints': checkpoints.map((cp) => cp.toJson()).toList(),
    };
  }
}

class CheckpointOrderRequest {
  final int checkpointId;
  final int order;
  final bool isRequired;

  CheckpointOrderRequest({
    required this.checkpointId,
    required this.order,
    this.isRequired = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'checkpoint_id': checkpointId,
      'sequence': order, // Odoo uses 'sequence'
      'is_required': isRequired,
    };
  }
}