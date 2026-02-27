// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timer_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimerStateImpl _$$TimerStateImplFromJson(Map<String, dynamic> json) =>
    _$TimerStateImpl(
      startTime: json['startTime'] == null
          ? null
          : DateTime.parse(json['startTime'] as String),
      isRunning: json['isRunning'] as bool? ?? false,
      accumulatedPauseDurationSeconds:
          (json['accumulatedPauseDurationSeconds'] as num?)?.toInt() ?? 0,
      lastPauseTime: json['lastPauseTime'] == null
          ? null
          : DateTime.parse(json['lastPauseTime'] as String),
    );

Map<String, dynamic> _$$TimerStateImplToJson(_$TimerStateImpl instance) =>
    <String, dynamic>{
      'startTime': instance.startTime?.toIso8601String(),
      'isRunning': instance.isRunning,
      'accumulatedPauseDurationSeconds':
          instance.accumulatedPauseDurationSeconds,
      'lastPauseTime': instance.lastPauseTime?.toIso8601String(),
    };
