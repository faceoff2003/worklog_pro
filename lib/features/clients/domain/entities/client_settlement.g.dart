// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ClientSettlement _$ClientSettlementFromJson(Map<String, dynamic> json) =>
    _ClientSettlement(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      balanceAtSettlement:
          Money.fromJson((json['balanceAtSettlement'] as num).toInt()),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$ClientSettlementToJson(_ClientSettlement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'date': instance.date.toJson(),
      'balanceAtSettlement': instance.balanceAtSettlement.toJson(),
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
    };
