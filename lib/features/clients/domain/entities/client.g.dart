// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Client _$ClientFromJson(Map<String, dynamic> json) => _Client(
      id: json['id'] as String,
      name: json['name'] as String,
      type: $enumDecode(_$ClientTypeEnumMap, json['type']),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      notes: json['notes'] as String?,
      defaultRates:
          DefaultRates.fromJson(json['defaultRates'] as Map<String, dynamic>),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ClientToJson(_Client instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type.toJson(),
      'phone': instance.phone,
      'email': instance.email,
      'notes': instance.notes,
      'defaultRates': instance.defaultRates.toJson(),
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$ClientTypeEnumMap = {
  ClientType.patron: 'patron',
  ClientType.client_particulier: 'client_particulier',
  ClientType.entreprise: 'entreprise',
};

_DefaultRates _$DefaultRatesFromJson(Map<String, dynamic> json) =>
    _DefaultRates(
      hour: json['hour'] == null
          ? null
          : Money.fromJson((json['hour'] as num).toInt()),
      halfDay: json['halfDay'] == null
          ? null
          : Money.fromJson((json['halfDay'] as num).toInt()),
      day: json['day'] == null
          ? null
          : Money.fromJson((json['day'] as num).toInt()),
      fixedJob: json['fixedJob'] == null
          ? null
          : Money.fromJson((json['fixedJob'] as num).toInt()),
    );

Map<String, dynamic> _$DefaultRatesToJson(_DefaultRates instance) =>
    <String, dynamic>{
      'hour': instance.hour?.toJson(),
      'halfDay': instance.halfDay?.toJson(),
      'day': instance.day?.toJson(),
      'fixedJob': instance.fixedJob?.toJson(),
    };
