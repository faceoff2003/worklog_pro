// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Payment _$PaymentFromJson(Map<String, dynamic> json) => _Payment(
      id: json['id'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      clientId: json['clientId'] as String,
      projectId: json['projectId'] as String?,
      amount: Money.fromJson((json['amount'] as num).toInt()),
      method: $enumDecode(_$PaymentMethodEnumMap, json['method']),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$PaymentToJson(_Payment instance) => <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toJson(),
      'clientId': instance.clientId,
      'projectId': instance.projectId,
      'amount': instance.amount.toJson(),
      'method': instance.method.toJson(),
      'note': instance.note,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.virement: 'virement',
  PaymentMethod.autre: 'autre',
};
