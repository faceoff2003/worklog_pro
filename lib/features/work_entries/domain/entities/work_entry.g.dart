// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'work_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkEntry _$WorkEntryFromJson(Map<String, dynamic> json) => _WorkEntry(
      id: json['id'] as String,
      date: DateOnly.fromJson(json['date'] as String),
      startTime: (json['startTime'] as num).toInt(),
      endTime: (json['endTime'] as num).toInt(),
      pauseMinutes: (json['pauseMinutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num).toInt(),
      clientId: json['clientId'] as String,
      projectId: json['projectId'] as String?,
      tasks:
          (json['tasks'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
      billingMode: $enumDecode(_$BillingModeEnumMap, json['billingMode']),
      rateApplied: Money.fromJson((json['rateApplied'] as num).toInt()),
      laborAmountHT: Money.fromJson((json['laborAmountHT'] as num).toInt()),
      travelDistanceKm: (json['travelDistanceKm'] as num?)?.toDouble() ?? 0.0,
      travelRatePerKm: (json['travelRatePerKm'] as num?)?.toDouble() ?? 0.20,
      travelAmountHT: json['travelAmountHT'] == null
          ? Money.zero
          : Money.fromJson((json['travelAmountHT'] as num).toInt()),
      timerUsed: json['timerUsed'] as bool? ?? false,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => Attachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$WorkEntryToJson(_WorkEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'date': instance.date.toJson(),
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'pauseMinutes': instance.pauseMinutes,
      'durationMinutes': instance.durationMinutes,
      'clientId': instance.clientId,
      'projectId': instance.projectId,
      'tasks': instance.tasks,
      'notes': instance.notes,
      'billingMode': instance.billingMode.toJson(),
      'rateApplied': instance.rateApplied.toJson(),
      'laborAmountHT': instance.laborAmountHT.toJson(),
      'travelDistanceKm': instance.travelDistanceKm,
      'travelRatePerKm': instance.travelRatePerKm,
      'travelAmountHT': instance.travelAmountHT.toJson(),
      'timerUsed': instance.timerUsed,
      'tags': instance.tags,
      'attachments': instance.attachments.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };

const _$BillingModeEnumMap = {
  BillingMode.hourly: 'hourly',
  BillingMode.half_day: 'half_day',
  BillingMode.day: 'day',
  BillingMode.fixed_job: 'fixed_job',
};
