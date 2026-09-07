// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_portal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientPortal {
  /// uid Firebase Auth du compte portail (= l'ID du document).
  String get portalUid;

  /// uid de l'artisan propriétaire de ce lien. Immuable.
  String get artisanUid;

  /// Identifiant du Client (users/{artisanUid}/clients/{clientId}) lié à
  /// ce portail. Immuable.
  String get clientId;

  /// Accès actif ou non. Ne gate que le client — jamais le mirroring de
  /// l'artisan, qui continue même désactivé.
  bool get enabled;

  /// Nom d'affichage propre au client, modifiable par lui.
  String? get displayName;
  DateTime get createdAt;

  /// Create a copy of ClientPortal
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ClientPortalCopyWith<ClientPortal> get copyWith =>
      _$ClientPortalCopyWithImpl<ClientPortal>(
          this as ClientPortal, _$identity);

  /// Serializes this ClientPortal to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ClientPortal &&
            (identical(other.portalUid, portalUid) ||
                other.portalUid == portalUid) &&
            (identical(other.artisanUid, artisanUid) ||
                other.artisanUid == artisanUid) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, portalUid, artisanUid, clientId,
      enabled, displayName, createdAt);

  @override
  String toString() {
    return 'ClientPortal(portalUid: $portalUid, artisanUid: $artisanUid, clientId: $clientId, enabled: $enabled, displayName: $displayName, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $ClientPortalCopyWith<$Res> {
  factory $ClientPortalCopyWith(
          ClientPortal value, $Res Function(ClientPortal) _then) =
      _$ClientPortalCopyWithImpl;
  @useResult
  $Res call(
      {String portalUid,
      String artisanUid,
      String clientId,
      bool enabled,
      String? displayName,
      DateTime createdAt});
}

/// @nodoc
class _$ClientPortalCopyWithImpl<$Res> implements $ClientPortalCopyWith<$Res> {
  _$ClientPortalCopyWithImpl(this._self, this._then);

  final ClientPortal _self;
  final $Res Function(ClientPortal) _then;

  /// Create a copy of ClientPortal
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? portalUid = null,
    Object? artisanUid = null,
    Object? clientId = null,
    Object? enabled = null,
    Object? displayName = freezed,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      portalUid: null == portalUid
          ? _self.portalUid
          : portalUid // ignore: cast_nullable_to_non_nullable
              as String,
      artisanUid: null == artisanUid
          ? _self.artisanUid
          : artisanUid // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [ClientPortal].
extension ClientPortalPatterns on ClientPortal {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_ClientPortal value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientPortal() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_ClientPortal value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientPortal():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_ClientPortal value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientPortal() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(String portalUid, String artisanUid, String clientId,
            bool enabled, String? displayName, DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientPortal() when $default != null:
        return $default(_that.portalUid, _that.artisanUid, _that.clientId,
            _that.enabled, _that.displayName, _that.createdAt);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(String portalUid, String artisanUid, String clientId,
            bool enabled, String? displayName, DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientPortal():
        return $default(_that.portalUid, _that.artisanUid, _that.clientId,
            _that.enabled, _that.displayName, _that.createdAt);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(String portalUid, String artisanUid, String clientId,
            bool enabled, String? displayName, DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientPortal() when $default != null:
        return $default(_that.portalUid, _that.artisanUid, _that.clientId,
            _that.enabled, _that.displayName, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ClientPortal implements ClientPortal {
  const _ClientPortal(
      {required this.portalUid,
      required this.artisanUid,
      required this.clientId,
      required this.enabled,
      this.displayName,
      required this.createdAt});
  factory _ClientPortal.fromJson(Map<String, dynamic> json) =>
      _$ClientPortalFromJson(json);

  /// uid Firebase Auth du compte portail (= l'ID du document).
  @override
  final String portalUid;

  /// uid de l'artisan propriétaire de ce lien. Immuable.
  @override
  final String artisanUid;

  /// Identifiant du Client (users/{artisanUid}/clients/{clientId}) lié à
  /// ce portail. Immuable.
  @override
  final String clientId;

  /// Accès actif ou non. Ne gate que le client — jamais le mirroring de
  /// l'artisan, qui continue même désactivé.
  @override
  final bool enabled;

  /// Nom d'affichage propre au client, modifiable par lui.
  @override
  final String? displayName;
  @override
  final DateTime createdAt;

  /// Create a copy of ClientPortal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ClientPortalCopyWith<_ClientPortal> get copyWith =>
      __$ClientPortalCopyWithImpl<_ClientPortal>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ClientPortalToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ClientPortal &&
            (identical(other.portalUid, portalUid) ||
                other.portalUid == portalUid) &&
            (identical(other.artisanUid, artisanUid) ||
                other.artisanUid == artisanUid) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, portalUid, artisanUid, clientId,
      enabled, displayName, createdAt);

  @override
  String toString() {
    return 'ClientPortal(portalUid: $portalUid, artisanUid: $artisanUid, clientId: $clientId, enabled: $enabled, displayName: $displayName, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$ClientPortalCopyWith<$Res>
    implements $ClientPortalCopyWith<$Res> {
  factory _$ClientPortalCopyWith(
          _ClientPortal value, $Res Function(_ClientPortal) _then) =
      __$ClientPortalCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String portalUid,
      String artisanUid,
      String clientId,
      bool enabled,
      String? displayName,
      DateTime createdAt});
}

/// @nodoc
class __$ClientPortalCopyWithImpl<$Res>
    implements _$ClientPortalCopyWith<$Res> {
  __$ClientPortalCopyWithImpl(this._self, this._then);

  final _ClientPortal _self;
  final $Res Function(_ClientPortal) _then;

  /// Create a copy of ClientPortal
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? portalUid = null,
    Object? artisanUid = null,
    Object? clientId = null,
    Object? enabled = null,
    Object? displayName = freezed,
    Object? createdAt = null,
  }) {
    return _then(_ClientPortal(
      portalUid: null == portalUid
          ? _self.portalUid
          : portalUid // ignore: cast_nullable_to_non_nullable
              as String,
      artisanUid: null == artisanUid
          ? _self.artisanUid
          : artisanUid // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      enabled: null == enabled
          ? _self.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      displayName: freezed == displayName
          ? _self.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
