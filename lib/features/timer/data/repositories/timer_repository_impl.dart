import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/timer/domain/entities/timer_state.dart';
import 'package:worklog_pro/features/timer/domain/repositories/timer_repository.dart';

class TimerRepositoryImpl implements TimerRepository {
  static const String _timerStateKey = 'timer_state_json';

  @override
  Future<void> saveTimerState(TimerState state) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(state.toJson());
    await prefs.setString(_timerStateKey, jsonString);
  }

  @override
  Future<TimerState?> getTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_timerStateKey);
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString);
      return TimerState.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_timerStateKey);
  }
}
