// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'payment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Payment {
  /// Identifiant unique UUID v4.
  String get id;

  /// Date à laquelle le paiement a été reçu.
  DateOnly get date;

  /// Identifiant du client ayant effectué le paiement.
  String get clientId;

  /// Chantier concerné (optionnel, permet d'associer un paiement spécifiquement).
  String? get projectId;

  /// Montant encaissé, stocké en centimes via [Money] pour la précision.
  Money get amount;

  /// Méthode utilisée (Espèces, Virement, Chèque, etc.).
  PaymentMethod get method;

  /// Notes ou référence bancaire.
  String? get note;

  /// Date de création.
  DateTime get createdAt;

  /// Date de modification.
  DateTime get updatedAt;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PaymentCopyWith<Payment> get copyWith =>
      _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);

  /// Serializes this Payment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, clientId, projectId,
      amount, method, note, createdAt, updatedAt);

  @override
  String toString() {
    return 'Payment(id: $id, date: $date, clientId: $clientId, projectId: $projectId, amount: $amount, method: $method, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res> {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) =
      _$PaymentCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      String clientId,
      String? projectId,
      Money amount,
      PaymentMethod method,
      String? note,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$PaymentCopyWithImpl<$Res> implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? amount = null,
    Object? method = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as Money,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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
    TResult Function(_Payment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
    TResult Function(_Payment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
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
    TResult? Function(_Payment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
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
    TResult Function(
            String id,
            DateOnly date,
            String clientId,
            String? projectId,
            Money amount,
            PaymentMethod method,
            String? note,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.amount,
            _that.method,
            _that.note,
            _that.createdAt,
            _that.updatedAt);
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
    TResult Function(
            String id,
            DateOnly date,
            String clientId,
            String? projectId,
            Money amount,
            PaymentMethod method,
            String? note,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment():
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.amount,
            _that.method,
            _that.note,
            _that.createdAt,
            _that.updatedAt);
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
    TResult? Function(
            String id,
            DateOnly date,
            String clientId,
            String? projectId,
            Money amount,
            PaymentMethod method,
            String? note,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Payment() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.amount,
            _that.method,
            _that.note,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Payment implements Payment {
  const _Payment(
      {required this.id,
      required this.date,
      required this.clientId,
      this.projectId,
      required this.amount,
      required this.method,
      this.note,
      required this.createdAt,
      required this.updatedAt});
  factory _Payment.fromJson(Map<String, dynamic> json) =>
      _$PaymentFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Date à laquelle le paiement a été reçu.
  @override
  final DateOnly date;

  /// Identifiant du client ayant effectué le paiement.
  @override
  final String clientId;

  /// Chantier concerné (optionnel, permet d'associer un paiement spécifiquement).
  @override
  final String? projectId;

  /// Montant encaissé, stocké en centimes via [Money] pour la précision.
  @override
  final Money amount;

  /// Méthode utilisée (Espèces, Virement, Chèque, etc.).
  @override
  final PaymentMethod method;

  /// Notes ou référence bancaire.
  @override
  final String? note;

  /// Date de création.
  @override
  final DateTime createdAt;

  /// Date de modification.
  @override
  final DateTime updatedAt;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PaymentCopyWith<_Payment> get copyWith =>
      __$PaymentCopyWithImpl<_Payment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PaymentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Payment &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.method, method) || other.method == method) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, date, clientId, projectId,
      amount, method, note, createdAt, updatedAt);

  @override
  String toString() {
    return 'Payment(id: $id, date: $date, clientId: $clientId, projectId: $projectId, amount: $amount, method: $method, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) =
      __$PaymentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      String clientId,
      String? projectId,
      Money amount,
      PaymentMethod method,
      String? note,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$PaymentCopyWithImpl<$Res> implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

  /// Create a copy of Payment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? amount = null,
    Object? method = null,
    Object? note = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_Payment(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      amount: null == amount
          ? _self.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as Money,
      method: null == method
          ? _self.method
          : method // ignore: cast_nullable_to_non_nullable
              as PaymentMethod,
      note: freezed == note
          ? _self.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: null == createdAt
          ? _self.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
