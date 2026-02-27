import 'package:freezed_annotation/freezed_annotation.dart';

part 'timer_state.freezed.dart';
part 'timer_state.g.dart';

@freezed
class TimerState with _$TimerState {
  const factory TimerState({
    required DateTime? startTime,
    @Default(false) bool isRunning,
    @Default(0) int accumulatedPauseDurationSeconds,
    DateTime? lastPauseTime,
  }) = _TimerState;

  factory TimerState.initial() => const TimerState(
    startTime: null,
    isRunning: false,
    accumulatedPauseDurationSeconds: 0,
    lastPauseTime: null,
  );

  factory TimerState.fromJson(Map<String, dynamic> json) => _$TimerStateFromJson(json);
}
