// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'route_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RouteConfig _$RouteConfigFromJson(Map<String, dynamic> json) => RouteConfig(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      isActive: json['is_active'] as bool,
      checkpoints: (json['checkpoints'] as List<dynamic>)
          .map((e) => CheckpointOrder.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['create_date'] == null
          ? null
          : DateTime.parse(json['create_date'] as String),
      updatedAt: json['write_date'] == null
          ? null
          : DateTime.parse(json['write_date'] as String),
    );

Map<String, dynamic> _$RouteConfigToJson(RouteConfig instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'is_active': instance.isActive,
      'checkpoints': instance.checkpoints,
      'create_date': instance.createdAt?.toIso8601String(),
      'write_date': instance.updatedAt?.toIso8601String(),
    };

CheckpointOrder _$CheckpointOrderFromJson(Map<String, dynamic> json) =>
    CheckpointOrder(
      checkpointId: (json['checkpoint_id'] as num).toInt(),
      checkpointName: json['checkpoint_name'] as String,
      order: (json['sequence'] as num).toInt(),
      isRequired: json['is_required'] as bool? ?? true,
    );

Map<String, dynamic> _$CheckpointOrderToJson(CheckpointOrder instance) =>
    <String, dynamic>{
      'checkpoint_id': instance.checkpointId,
      'checkpoint_name': instance.checkpointName,
      'sequence': instance.order,
      'is_required': instance.isRequired,
    };
