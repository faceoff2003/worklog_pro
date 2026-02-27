// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'attachment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease use `MyClass.someNamedConstructor()` instead.');

Attachment _$AttachmentFromJson(Map<String, dynamic> json) {
  return _Attachment.fromJson(json);
}

/// @nodoc
mixin _$Attachment {
  AttachmentType get type => throw _privateConstructorUsedError;
  String get storagePath => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AttachmentCopyWith<Attachment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AttachmentCopyWith<$Res> {
  factory $AttachmentCopyWith(
          Attachment value, $Res Function(Attachment) then) =
      _$AttachmentCopyWithImpl<$Res, Attachment>;
  @useResult
  $Res call(
      {AttachmentType type,
      String storagePath,
      String name,
      String? note,
      int sizeBytes});
}

/// @nodoc
class _$AttachmentCopyWithImpl<$Res, $Val extends Attachment>
    implements $AttachmentCopyWith<$Res> {
  _$AttachmentCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? storagePath = null,
    Object? name = null,
    Object? note = freezed,
    Object? sizeBytes = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type as AttachmentType,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath as String,
      name: null == name
          ? _value.name
          : name as String,
      note: freezed == note
          ? _value.note
          : note as String?,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AttachmentImplCopyWith<$Res>
    implements $AttachmentCopyWith<$Res> {
  factory _$$AttachmentImplCopyWith(
          _$AttachmentImpl value, $Res Function(_$AttachmentImpl) then) =
      __$$AttachmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AttachmentType type,
      String storagePath,
      String name,
      String? note,
      int sizeBytes});
}

/// @nodoc
class __$$AttachmentImplCopyWithImpl<$Res>
    extends _$AttachmentCopyWithImpl<$Res, _$AttachmentImpl>
    implements _$$AttachmentImplCopyWith<$Res> {
  __$$AttachmentImplCopyWithImpl(
      _$AttachmentImpl _value, $Res Function(_$AttachmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? storagePath = null,
    Object? name = null,
    Object? note = freezed,
    Object? sizeBytes = null,
  }) {
    return _then(_$AttachmentImpl(
      type: null == type
          ? _value.type
          : type as AttachmentType,
      storagePath: null == storagePath
          ? _value.storagePath
          : storagePath as String,
      name: null == name
          ? _value.name
          : name as String,
      note: freezed == note
          ? _value.note
          : note as String?,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AttachmentImpl implements _Attachment {
  const _$AttachmentImpl(
      {required this.type,
      required this.storagePath,
      required this.name,
      this.note,
      required this.sizeBytes});

  factory _$AttachmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$AttachmentImplFromJson(json);

  @override
  final AttachmentType type;
  @override
  final String storagePath;
  @override
  final String name;
  @override
  final String? note;
  @override
  final int sizeBytes;

  @override
  String toString() {
    return 'Attachment(type: $type, storagePath: $storagePath, name: $name, note: $note, sizeBytes: $sizeBytes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AttachmentImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.storagePath, storagePath) ||
                other.storagePath == storagePath) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, storagePath, name, note, sizeBytes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      __$$AttachmentImplCopyWithImpl<_$AttachmentImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AttachmentImplToJson(
      this,
    );
  }
}

abstract class _Attachment implements Attachment {
  const factory _Attachment(
      {required final AttachmentType type,
      required final String storagePath,
      required final String name,
      final String? note,
      required final int sizeBytes}) = _$AttachmentImpl;

  factory _Attachment.fromJson(Map<String, dynamic> json) =
      _$AttachmentImpl.fromJson;

  @override
  AttachmentType get type;
  @override
  String get storagePath;
  @override
  String get name;
  @override
  String? get note;
  @override
  int get sizeBytes;
  @override
  @JsonKey(ignore: true)
  _$$AttachmentImplCopyWith<_$AttachmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
