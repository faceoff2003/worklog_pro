// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client_settlement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ClientSettlement {
  /// Identifiant unique UUID v4.
  String get id;

  /// Identifiant du client concerné.
  String get clientId;

  /// Date de remise à zéro (format YYYY-MM-DD).
  /// Seules les entrées strictement postérieures à cette date
  /// sont comptabilisées dans la balance courante.
  DateOnly get date;

  /// Montant soldé en centimes au moment de la remise à zéro.
  /// Enregistré à titre d'information / archivage.
  Money get balanceAtSettlement;

  /// Note libre (ex: "Règlement final chantier Rue de la Loi").
  String? get note;

  /// Date de création de l'enregistrement.
  DateTime get createdAt;

  /// Create a copy of ClientSettlement
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ClientSettlementCopyWith<ClientSettlement> get copyWith =>
      _$ClientSettlementCopyWithImpl<ClientSettlement>(
          this as ClientSettlement, _$identity);

  /// Serializes this ClientSettlement to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ClientSettlement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.balanceAtSettlement, balanceAtSettlement) ||
                other.balanceAtSettlement == balanceAtSettlement) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, clientId, date, balanceAtSettlement, note, createdAt);

  @override
  String toString() {
    return 'ClientSettlement(id: $id, clientId: $clientId, date: $date, balanceAtSettlement: $balanceAtSettlement, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $ClientSettlementCopyWith<$Res> {
  factory $ClientSettlementCopyWith(
          ClientSettlement value, $Res Function(ClientSettlement) _then) =
      _$ClientSettlementCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String clientId,
      DateOnly date,
      Money balanceAtSettlement,
      String? note,
      DateTime createdAt});
}

/// @nodoc
class _$ClientSettlementCopyWithImpl<$Res>
    implements $ClientSettlementCopyWith<$Res> {
  _$ClientSettlementCopyWithImpl(this._self, this._then);

  final ClientSettlement _self;
  final $Res Function(ClientSettlement) _then;

  /// Create a copy of ClientSettlement
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? date = null,
    Object? balanceAtSettlement = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      balanceAtSettlement: null == balanceAtSettlement
          ? _self.balanceAtSettlement
          : balanceAtSettlement // ignore: cast_nullable_to_non_nullable
              as Money,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [ClientSettlement].
extension ClientSettlementPatterns on ClientSettlement {
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
    TResult Function(_ClientSettlement value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement() when $default != null:
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
    TResult Function(_ClientSettlement value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement():
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
    TResult? Function(_ClientSettlement value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement() when $default != null:
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
    TResult Function(String id, String clientId, DateOnly date,
            Money balanceAtSettlement, String? note, DateTime createdAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement() when $default != null:
        return $default(_that.id, _that.clientId, _that.date,
            _that.balanceAtSettlement, _that.note, _that.createdAt);
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
    TResult Function(String id, String clientId, DateOnly date,
            Money balanceAtSettlement, String? note, DateTime createdAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement():
        return $default(_that.id, _that.clientId, _that.date,
            _that.balanceAtSettlement, _that.note, _that.createdAt);
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
    TResult? Function(String id, String clientId, DateOnly date,
            Money balanceAtSettlement, String? note, DateTime createdAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ClientSettlement() when $default != null:
        return $default(_that.id, _that.clientId, _that.date,
            _that.balanceAtSettlement, _that.note, _that.createdAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ClientSettlement implements ClientSettlement {
  const _ClientSettlement(
      {required this.id,
      required this.clientId,
      required this.date,
      required this.balanceAtSettlement,
      this.note,
      required this.createdAt});
  factory _ClientSettlement.fromJson(Map<String, dynamic> json) =>
      _$ClientSettlementFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Identifiant du client concerné.
  @override
  final String clientId;

  /// Date de remise à zéro (format YYYY-MM-DD).
  /// Seules les entrées strictement postérieures à cette date
  /// sont comptabilisées dans la balance courante.
  @override
  final DateOnly date;

  /// Montant soldé en centimes au moment de la remise à zéro.
  /// Enregistré à titre d'information / archivage.
  @override
  final Money balanceAtSettlement;

  /// Note libre (ex: "Règlement final chantier Rue de la Loi").
  @override
  final String? note;

  /// Date de création de l'enregistrement.
  @override
  final DateTime createdAt;

  /// Create a copy of ClientSettlement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ClientSettlementCopyWith<_ClientSettlement> get copyWith =>
      __$ClientSettlementCopyWithImpl<_ClientSettlement>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ClientSettlementToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ClientSettlement &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.balanceAtSettlement, balanceAtSettlement) ||
                other.balanceAtSettlement == balanceAtSettlement) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, clientId, date, balanceAtSettlement, note, createdAt);

  @override
  String toString() {
    return 'ClientSettlement(id: $id, clientId: $clientId, date: $date, balanceAtSettlement: $balanceAtSettlement, note: $note, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$ClientSettlementCopyWith<$Res>
    implements $ClientSettlementCopyWith<$Res> {
  factory _$ClientSettlementCopyWith(
          _ClientSettlement value, $Res Function(_ClientSettlement) _then) =
      __$ClientSettlementCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String clientId,
      DateOnly date,
      Money balanceAtSettlement,
      String? note,
      DateTime createdAt});
}

/// @nodoc
class __$ClientSettlementCopyWithImpl<$Res>
    implements _$ClientSettlementCopyWith<$Res> {
  __$ClientSettlementCopyWithImpl(this._self, this._then);

  final _ClientSettlement _self;
  final $Res Function(_ClientSettlement) _then;

  /// Create a copy of ClientSettlement
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? date = null,
    Object? balanceAtSettlement = null,
    Object? note = freezed,
    Object? createdAt = null,
  }) {
    return _then(_ClientSettlement(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      balanceAtSettlement: null == balanceAtSettlement
          ? _self.balanceAtSettlement
          : balanceAtSettlement // ignore: cast_nullable_to_non_nullable
              as Money,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
