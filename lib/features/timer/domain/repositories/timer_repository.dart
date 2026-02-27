import 'package:worklog_pro/features/timer/domain/entities/timer_state.dart';

abstract class TimerRepository {
  /// Save the current state of the timer
  Future<void> saveTimerState(TimerState state);

  /// Get the saved timer state
  Future<TimerState?> getTimerState();

  /// Clear the saved timer state (stop timer)
  Future<void> clearTimerState();
}
