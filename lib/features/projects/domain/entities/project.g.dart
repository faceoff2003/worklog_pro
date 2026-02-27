// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Project _$ProjectFromJson(Map<String, dynamic> json) => _Project(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      label: json['label'] as String,
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      type: $enumDecode(_$ProjectTypeEnumMap, json['type']),
      status: $enumDecode(_$ProjectStatusEnumMap, json['status']),
      notes: json['notes'] as String?,
      technicalNotes: json['technicalNotes'] as String?,
      accessNotes: json['accessNotes'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ProjectToJson(_Project instance) => <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'label': instance.label,
      'address': instance.address.toJson(),
      'type': instance.type.toJson(),
      'status': instance.status.toJson(),
      'notes': instance.notes,
      'technicalNotes': instance.technicalNotes,
      'accessNotes': instance.accessNotes,
      'distanceKm': instance.distanceKm,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ProjectTypeEnumMap = {
  ProjectType.nouvelle_installation: 'nouvelle_installation',
  ProjectType.mise_en_conformite: 'mise_en_conformite',
  ProjectType.depannage: 'depannage',
  ProjectType.renovation: 'renovation',
  ProjectType.domotique: 'domotique',
  ProjectType.autre: 'autre',
};

const _$ProjectStatusEnumMap = {
  ProjectStatus.actif: 'actif',
  ProjectStatus.termine: 'termine',
  ProjectStatus.en_attente: 'en_attente',
};
