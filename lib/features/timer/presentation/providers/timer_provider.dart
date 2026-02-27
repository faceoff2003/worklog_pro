
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/timer/data/repositories/timer_repository_impl.dart';
import 'package:worklog_pro/features/timer/domain/entities/timer_state.dart';
import 'package:worklog_pro/features/timer/domain/repositories/timer_repository.dart';

// Repository Provider
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  return TimerRepositoryImpl();
});

// Timer Controller Provider
final timerControllerProvider = StateNotifierProvider<TimerController, TimerState>((ref) {
  final repository = ref.watch(timerRepositoryProvider);
  return TimerController(repository);
});

// Stream that emits current duration every second if running
final timerDurationProvider = StreamProvider.autoDispose<int>((ref) {
  final state = ref.watch(timerControllerProvider);
  
  if (!state.isRunning || state.startTime == null) {
    if (state.startTime != null && !state.isRunning) {
        // Paused: return static duration
        return Stream.value(_calculateDuration(state));
    }
    return Stream.value(0);
  }

  // running: emit every sec
  return Stream.periodic(const Duration(seconds: 1), (_) {
    return _calculateDuration(state);
  });
});

int _calculateDuration(TimerState state) {
  if (state.startTime == null) return 0;
  
  final now = DateTime.now();
  final totalElapsed = now.difference(state.startTime!).inSeconds;
  
  // Subtract past accumulated pauses
  var duration = totalElapsed - state.accumulatedPauseDurationSeconds;
  
  // Subtract current pause if currently paused (though isRunning check handles this usually)
  // If isRunning is false, it means we are paused NOW.
  // The state.lastPauseTime should be set.
  if (!state.isRunning && state.lastPauseTime != null) {
     // We are paused. Duration is constant.
     // Total elapsed since start includes the current pause duration.
     // We need to subtract it.
     // Or simpler: We stopped counting when we paused.
     // It's tricky to calculate "live" from a static state if we include "current pause".
     
     // Better logic:
     // Duration = (Time when paused - StartTime) - Previous Pauses.
     
     final pauseTime = state.lastPauseTime!;
     final activeDuration = pauseTime.difference(state.startTime!).inSeconds - state.accumulatedPauseDurationSeconds;
     return activeDuration;
  }
  
  return duration;
}

class TimerController extends StateNotifier<TimerState> {
  final TimerRepository _repository;

  TimerController(this._repository) : super(TimerState.initial()) {
    _loadState();
  }

  Future<void> _loadState() async {
    final saved = await _repository.getTimerState();
    if (saved != null) {
      state = saved;
    }
  }

  Future<void> start() async {
    if (state.startTime != null) return; // already started

    final now = DateTime.now();
    final newState = state.copyWith(
      startTime: now,
      isRunning: true,
      accumulatedPauseDurationSeconds: 0,
      lastPauseTime: null,
    );
    
    state = newState;
    await _repository.saveTimerState(newState);
  }

  Future<void> pause() async {
    if (!state.isRunning) return;

    final now = DateTime.now();
    final newState = state.copyWith(
      isRunning: false,
      lastPauseTime: now,
    );

    state = newState;
    await _repository.saveTimerState(newState);
  }

  Future<void> resume() async {
    if (state.isRunning || state.startTime == null) return;
    
    // Calculate how long we were paused
    final now = DateTime.now();
    final pauseStart = state.lastPauseTime ?? now; // fallback
    final pauseDuration = now.difference(pauseStart).inSeconds;
    
    final newState = state.copyWith(
      isRunning: true,
      lastPauseTime: null,
      accumulatedPauseDurationSeconds: state.accumulatedPauseDurationSeconds + pauseDuration,
    );
    
    state = newState;
    await _repository.saveTimerState(newState);
  }

  Future<int> stop() async {
    final duration = _calculateDuration(state);
    
    state = TimerState.initial();
    await _repository.clearTimerState();
    
    return duration;
  }
}
