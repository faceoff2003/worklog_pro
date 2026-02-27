import 'package:freezed_annotation/freezed_annotation.dart';

/// Value object representing work duration in minutes.
/// 
/// Handles time calculations, rounding, and formatting.
@immutable
class WorkDuration implements Comparable<WorkDuration> {
  /// Duration in minutes (always positive or zero)
  final int minutes;

  const WorkDuration._(this.minutes) : assert(minutes >= 0);

  /// Create duration from minutes
  factory WorkDuration.fromMinutes(int minutes) {
    if (minutes < 0) {
      throw ArgumentError('Duration cannot be negative: $minutes');
    }
    return WorkDuration._(minutes);
  }

  /// Create duration from hours (converted to minutes)
  factory WorkDuration.fromHours(double hours) {
    if (hours < 0) {
      throw ArgumentError('Duration cannot be negative: $hours');
    }
    return WorkDuration._((hours * 60).round());
  }

  /// Create from time points (minutes since midnight)
  /// startTime: 480 (08:00), endTime: 1020 (17:00), pauseMinutes: 30
  /// Result: 510 minutes (8h30)
  factory WorkDuration.fromTimeRange({
    required int startTime,
    required int endTime,
    required int pauseMinutes,
  }) {
    if (startTime < 0 || startTime > 1439) {
      throw ArgumentError('Invalid startTime: $startTime (must be 0-1439)');
    }
    if (endTime < 0 || endTime > 1439) {
      throw ArgumentError('Invalid endTime: $endTime (must be 0-1439)');
    }
    if (endTime <= startTime) {
      throw ArgumentError('endTime must be after startTime');
    }
    if (pauseMinutes < 0) {
      throw ArgumentError('pauseMinutes cannot be negative');
    }

    final total = endTime - startTime;
    if (pauseMinutes > total) {
      throw ArgumentError('pauseMinutes cannot exceed total duration');
    }

    return WorkDuration._(total - pauseMinutes);
  }

  /// Zero duration
  static const WorkDuration zero = WorkDuration._(0);

  /// Duration in hours (as double, for calculations)
  double get inHours => minutes / 60.0;

  /// Round duration to specified minutes
  /// roundingMinutes: 5, 10, 15, 30, or 0 (no rounding)
  WorkDuration round(int roundingMinutes) {
    if (roundingMinutes <= 0) return this;
    
    final rounded = (minutes / roundingMinutes).round() * roundingMinutes;
    return WorkDuration._(rounded);
  }

  /// Format as "7h 45min" or "8h 00min"
  String format() {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins.toString().padLeft(2, '0')}min';
  }

  /// Format as hours only (e.g., "7.75h")
  String formatHoursOnly() {
    return '${inHours.toStringAsFixed(2)}h';
  }

  /// Add duration
  WorkDuration operator +(WorkDuration other) {
    return WorkDuration._(minutes + other.minutes);
  }

  /// Subtract duration
  WorkDuration operator -(WorkDuration other) {
    if (other.minutes > minutes) {
      throw ArgumentError('Cannot subtract: result would be negative');
    }
    return WorkDuration._(minutes - other.minutes);
  }

  /// Multiply by factor
  WorkDuration operator *(num factor) {
    if (factor < 0) {
      throw ArgumentError('Cannot multiply by negative: $factor');
    }
    return WorkDuration._((minutes * factor).round());
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkDuration && minutes == other.minutes;
  }

  @override
  int get hashCode => minutes.hashCode;

  bool operator <(WorkDuration other) => minutes < other.minutes;
  bool operator <=(WorkDuration other) => minutes <= other.minutes;
  bool operator >(WorkDuration other) => minutes > other.minutes;
  bool operator >=(WorkDuration other) => minutes >= other.minutes;

  @override
  int compareTo(WorkDuration other) => minutes.compareTo(other.minutes);

  @override
  String toString() => format();

  /// Serialize to int for Firestore
  int toJson() => minutes;

  /// Deserialize from int
  factory WorkDuration.fromJson(int minutes) => WorkDuration.fromMinutes(minutes);
}
