// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timer_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

TimerState _$TimerStateFromJson(Map<String, dynamic> json) {
  return _TimerState.fromJson(json);
}

/// @nodoc
mixin _$TimerState {
  DateTime? get startTime => throw _privateConstructorUsedError;
  bool get isRunning => throw _privateConstructorUsedError;
  int get accumulatedPauseDurationSeconds => throw _privateConstructorUsedError;
  DateTime? get lastPauseTime => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TimerStateCopyWith<TimerState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimerStateCopyWith<$Res> {
  factory $TimerStateCopyWith(
          TimerState value, $Res Function(TimerState) then) =
      _$TimerStateCopyWithImpl<$Res, TimerState>;
  @useResult
  $Res call(
      {DateTime? startTime,
      bool isRunning,
      int accumulatedPauseDurationSeconds,
      DateTime? lastPauseTime});
}

/// @nodoc
class _$TimerStateCopyWithImpl<$Res, $Val extends TimerState>
    implements $TimerStateCopyWith<$Res> {
  _$TimerStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = freezed,
    Object? isRunning = null,
    Object? accumulatedPauseDurationSeconds = null,
    Object? lastPauseTime = freezed,
  }) {
    return _then(_value.copyWith(
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      accumulatedPauseDurationSeconds: null == accumulatedPauseDurationSeconds
          ? _value.accumulatedPauseDurationSeconds
          : accumulatedPauseDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      lastPauseTime: freezed == lastPauseTime
          ? _value.lastPauseTime
          : lastPauseTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimerStateImplCopyWith<$Res>
    implements $TimerStateCopyWith<$Res> {
  factory _$$TimerStateImplCopyWith(
          _$TimerStateImpl value, $Res Function(_$TimerStateImpl) then) =
      __$$TimerStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime? startTime,
      bool isRunning,
      int accumulatedPauseDurationSeconds,
      DateTime? lastPauseTime});
}

/// @nodoc
class __$$TimerStateImplCopyWithImpl<$Res>
    extends _$TimerStateCopyWithImpl<$Res, _$TimerStateImpl>
    implements _$$TimerStateImplCopyWith<$Res> {
  __$$TimerStateImplCopyWithImpl(
      _$TimerStateImpl _value, $Res Function(_$TimerStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startTime = freezed,
    Object? isRunning = null,
    Object? accumulatedPauseDurationSeconds = null,
    Object? lastPauseTime = freezed,
  }) {
    return _then(_$TimerStateImpl(
      startTime: freezed == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      isRunning: null == isRunning
          ? _value.isRunning
          : isRunning // ignore: cast_nullable_to_non_nullable
              as bool,
      accumulatedPauseDurationSeconds: null == accumulatedPauseDurationSeconds
          ? _value.accumulatedPauseDurationSeconds
          : accumulatedPauseDurationSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      lastPauseTime: freezed == lastPauseTime
          ? _value.lastPauseTime
          : lastPauseTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimerStateImpl implements _TimerState {
  const _$TimerStateImpl(
      {required this.startTime,
      this.isRunning = false,
      this.accumulatedPauseDurationSeconds = 0,
      this.lastPauseTime});

  factory _$TimerStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimerStateImplFromJson(json);

  @override
  final DateTime? startTime;
  @override
  @JsonKey()
  final bool isRunning;
  @override
  @JsonKey()
  final int accumulatedPauseDurationSeconds;
  @override
  final DateTime? lastPauseTime;

  @override
  String toString() {
    return 'TimerState(startTime: $startTime, isRunning: $isRunning, accumulatedPauseDurationSeconds: $accumulatedPauseDurationSeconds, lastPauseTime: $lastPauseTime)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimerStateImpl &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.isRunning, isRunning) ||
                other.isRunning == isRunning) &&
            (identical(other.accumulatedPauseDurationSeconds,
                    accumulatedPauseDurationSeconds) ||
                other.accumulatedPauseDurationSeconds ==
                    accumulatedPauseDurationSeconds) &&
            (identical(other.lastPauseTime, lastPauseTime) ||
                other.lastPauseTime == lastPauseTime));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, startTime, isRunning,
      accumulatedPauseDurationSeconds, lastPauseTime);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TimerStateImplCopyWith<_$TimerStateImpl> get copyWith =>
      __$$TimerStateImplCopyWithImpl<_$TimerStateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimerStateImplToJson(
      this,
    );
  }
}

abstract class _TimerState implements TimerState {
  const factory _TimerState(
      {required final DateTime? startTime,
      final bool isRunning,
      final int accumulatedPauseDurationSeconds,
      final DateTime? lastPauseTime}) = _$TimerStateImpl;

  factory _TimerState.fromJson(Map<String, dynamic> json) =
      _$TimerStateImpl.fromJson;

  @override
  DateTime? get startTime;
  @override
  bool get isRunning;
  @override
  int get accumulatedPauseDurationSeconds;
  @override
  DateTime? get lastPauseTime;
  @override
  @JsonKey(ignore: true)
  _$$TimerStateImplCopyWith<_$TimerStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
