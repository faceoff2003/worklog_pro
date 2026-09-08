// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'client.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Client {
  /// Identifiant unique UUID v4.
  String get id;

  /// Nom ou raison sociale (ex: "Entreprise Dupont", "M. Jean").
  String get name;

  /// Type de client (Particulier ou Professionnel).
  ClientType get type;

  /// Numéro de téléphone.
  String? get phone;

  /// Adresse e-mail.
  String? get email;

  /// Notes internes.
  String? get notes;

  /// Tarifs par défaut appliqués aux prestations de ce client.
  DefaultRates get defaultRates;

  /// Étiquettes pour filtrer ou rechercher plus facilement.
  List<String> get tags;

  /// uid Firebase Auth du compte portail de ce client, si un accès lui a
  /// été créé (C-PORTAL). Null = pas de portail. Sert de clé vers
  /// clientPortals/{portalUid} — jamais l'inverse, ce document ne connaît
  /// jamais son propre portail avant qu'on le lui attribue explicitement.
  String? get portalUid;

  /// Date de création de la fiche.
  DateTime get createdAt;

  /// Date de dernière modification.
  DateTime get updatedAt;

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ClientCopyWith<Client> get copyWith =>
      _$ClientCopyWithImpl<Client>(this as Client, _$identity);

  /// Serializes this Client to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Client &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.defaultRates, defaultRates) ||
                other.defaultRates == defaultRates) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.portalUid, portalUid) ||
                other.portalUid == portalUid) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      phone,
      email,
      notes,
      defaultRates,
      const DeepCollectionEquality().hash(tags),
      portalUid,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Client(id: $id, name: $name, type: $type, phone: $phone, email: $email, notes: $notes, defaultRates: $defaultRates, tags: $tags, portalUid: $portalUid, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ClientCopyWith<$Res> {
  factory $ClientCopyWith(Client value, $Res Function(Client) _then) =
      _$ClientCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      ClientType type,
      String? phone,
      String? email,
      String? notes,
      DefaultRates defaultRates,
      List<String> tags,
      String? portalUid,
      DateTime createdAt,
      DateTime updatedAt});

  $DefaultRatesCopyWith<$Res> get defaultRates;
}

/// @nodoc
class _$ClientCopyWithImpl<$Res> implements $ClientCopyWith<$Res> {
  _$ClientCopyWithImpl(this._self, this._then);

  final Client _self;
  final $Res Function(Client) _then;

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? notes = freezed,
    Object? defaultRates = null,
    Object? tags = null,
    Object? portalUid = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ClientType,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultRates: null == defaultRates
          ? _self.defaultRates
          : defaultRates // ignore: cast_nullable_to_non_nullable
              as DefaultRates,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      portalUid: freezed == portalUid
          ? _self.portalUid
          : portalUid // ignore: cast_nullable_to_non_nullable
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

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DefaultRatesCopyWith<$Res> get defaultRates {
    return $DefaultRatesCopyWith<$Res>(_self.defaultRates, (value) {
      return _then(_self.copyWith(defaultRates: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Client].
extension ClientPatterns on Client {
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
    TResult Function(_Client value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Client() when $default != null:
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
    TResult Function(_Client value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Client():
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
    TResult? Function(_Client value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Client() when $default != null:
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
            String name,
            ClientType type,
            String? phone,
            String? email,
            String? notes,
            DefaultRates defaultRates,
            List<String> tags,
            String? portalUid,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Client() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.phone,
            _that.email,
            _that.notes,
            _that.defaultRates,
            _that.tags,
            _that.portalUid,
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
            String name,
            ClientType type,
            String? phone,
            String? email,
            String? notes,
            DefaultRates defaultRates,
            List<String> tags,
            String? portalUid,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Client():
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.phone,
            _that.email,
            _that.notes,
            _that.defaultRates,
            _that.tags,
            _that.portalUid,
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
            String name,
            ClientType type,
            String? phone,
            String? email,
            String? notes,
            DefaultRates defaultRates,
            List<String> tags,
            String? portalUid,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Client() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.type,
            _that.phone,
            _that.email,
            _that.notes,
            _that.defaultRates,
            _that.tags,
            _that.portalUid,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Client implements Client {
  const _Client(
      {required this.id,
      required this.name,
      required this.type,
      this.phone,
      this.email,
      this.notes,
      required this.defaultRates,
      final List<String> tags = const [],
      this.portalUid,
      required this.createdAt,
      required this.updatedAt})
      : _tags = tags;
  factory _Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Nom ou raison sociale (ex: "Entreprise Dupont", "M. Jean").
  @override
  final String name;

  /// Type de client (Particulier ou Professionnel).
  @override
  final ClientType type;

  /// Numéro de téléphone.
  @override
  final String? phone;

  /// Adresse e-mail.
  @override
  final String? email;

  /// Notes internes.
  @override
  final String? notes;

  /// Tarifs par défaut appliqués aux prestations de ce client.
  @override
  final DefaultRates defaultRates;

  /// Étiquettes pour filtrer ou rechercher plus facilement.
  final List<String> _tags;

  /// Étiquettes pour filtrer ou rechercher plus facilement.
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// uid Firebase Auth du compte portail de ce client, si un accès lui a
  /// été créé (C-PORTAL). Null = pas de portail. Sert de clé vers
  /// clientPortals/{portalUid} — jamais l'inverse, ce document ne connaît
  /// jamais son propre portail avant qu'on le lui attribue explicitement.
  @override
  final String? portalUid;

  /// Date de création de la fiche.
  @override
  final DateTime createdAt;

  /// Date de dernière modification.
  @override
  final DateTime updatedAt;

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ClientCopyWith<_Client> get copyWith =>
      __$ClientCopyWithImpl<_Client>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ClientToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Client &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.defaultRates, defaultRates) ||
                other.defaultRates == defaultRates) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.portalUid, portalUid) ||
                other.portalUid == portalUid) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      type,
      phone,
      email,
      notes,
      defaultRates,
      const DeepCollectionEquality().hash(_tags),
      portalUid,
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Client(id: $id, name: $name, type: $type, phone: $phone, email: $email, notes: $notes, defaultRates: $defaultRates, tags: $tags, portalUid: $portalUid, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ClientCopyWith<$Res> implements $ClientCopyWith<$Res> {
  factory _$ClientCopyWith(_Client value, $Res Function(_Client) _then) =
      __$ClientCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      ClientType type,
      String? phone,
      String? email,
      String? notes,
      DefaultRates defaultRates,
      List<String> tags,
      String? portalUid,
      DateTime createdAt,
      DateTime updatedAt});

  @override
  $DefaultRatesCopyWith<$Res> get defaultRates;
}

/// @nodoc
class __$ClientCopyWithImpl<$Res> implements _$ClientCopyWith<$Res> {
  __$ClientCopyWithImpl(this._self, this._then);

  final _Client _self;
  final $Res Function(_Client) _then;

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? type = null,
    Object? phone = freezed,
    Object? email = freezed,
    Object? notes = freezed,
    Object? defaultRates = null,
    Object? tags = null,
    Object? portalUid = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_Client(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ClientType,
      phone: freezed == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      defaultRates: null == defaultRates
          ? _self.defaultRates
          : defaultRates // ignore: cast_nullable_to_non_nullable
              as DefaultRates,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      portalUid: freezed == portalUid
          ? _self.portalUid
          : portalUid // ignore: cast_nullable_to_non_nullable
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

  /// Create a copy of Client
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DefaultRatesCopyWith<$Res> get defaultRates {
    return $DefaultRatesCopyWith<$Res>(_self.defaultRates, (value) {
      return _then(_self.copyWith(defaultRates: value));
    });
  }
}

/// @nodoc
mixin _$DefaultRates {
  /// Tarif appliqué pour 1 heure de travail en centimes.
  Money? get hour;

  /// Tarif appliqué pour une demi-journée en centimes.
  Money? get halfDay;

  /// Tarif appliqué pour une journée complète en centimes.
  Money? get day;

  /// Tarif au forfait (sans notion de durée).
  Money? get fixedJob;

  /// Create a copy of DefaultRates
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DefaultRatesCopyWith<DefaultRates> get copyWith =>
      _$DefaultRatesCopyWithImpl<DefaultRates>(
          this as DefaultRates, _$identity);

  /// Serializes this DefaultRates to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DefaultRates &&
            (identical(other.hour, hour) || other.hour == hour) &&
            (identical(other.halfDay, halfDay) || other.halfDay == halfDay) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.fixedJob, fixedJob) ||
                other.fixedJob == fixedJob));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hour, halfDay, day, fixedJob);

  @override
  String toString() {
    return 'DefaultRates(hour: $hour, halfDay: $halfDay, day: $day, fixedJob: $fixedJob)';
  }
}

/// @nodoc
abstract mixin class $DefaultRatesCopyWith<$Res> {
  factory $DefaultRatesCopyWith(
          DefaultRates value, $Res Function(DefaultRates) _then) =
      _$DefaultRatesCopyWithImpl;
  @useResult
  $Res call({Money? hour, Money? halfDay, Money? day, Money? fixedJob});
}

/// @nodoc
class _$DefaultRatesCopyWithImpl<$Res> implements $DefaultRatesCopyWith<$Res> {
  _$DefaultRatesCopyWithImpl(this._self, this._then);

  final DefaultRates _self;
  final $Res Function(DefaultRates) _then;

  /// Create a copy of DefaultRates
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hour = freezed,
    Object? halfDay = freezed,
    Object? day = freezed,
    Object? fixedJob = freezed,
  }) {
    return _then(_self.copyWith(
      hour: freezed == hour
          ? _self.hour
          : hour // ignore: cast_nullable_to_non_nullable
              as Money?,
      halfDay: freezed == halfDay
          ? _self.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as Money?,
      day: freezed == day
          ? _self.day
          : day // ignore: cast_nullable_to_non_nullable
              as Money?,
      fixedJob: freezed == fixedJob
          ? _self.fixedJob
          : fixedJob // ignore: cast_nullable_to_non_nullable
              as Money?,
    ));
  }
}

/// Adds pattern-matching-related methods to [DefaultRates].
extension DefaultRatesPatterns on DefaultRates {
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
    TResult Function(_DefaultRates value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DefaultRates() when $default != null:
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
    TResult Function(_DefaultRates value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DefaultRates():
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
    TResult? Function(_DefaultRates value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DefaultRates() when $default != null:
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
    TResult Function(Money? hour, Money? halfDay, Money? day, Money? fixedJob)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DefaultRates() when $default != null:
        return $default(_that.hour, _that.halfDay, _that.day, _that.fixedJob);
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
    TResult Function(Money? hour, Money? halfDay, Money? day, Money? fixedJob)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DefaultRates():
        return $default(_that.hour, _that.halfDay, _that.day, _that.fixedJob);
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
    TResult? Function(Money? hour, Money? halfDay, Money? day, Money? fixedJob)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DefaultRates() when $default != null:
        return $default(_that.hour, _that.halfDay, _that.day, _that.fixedJob);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DefaultRates implements DefaultRates {
  const _DefaultRates({this.hour, this.halfDay, this.day, this.fixedJob});
  factory _DefaultRates.fromJson(Map<String, dynamic> json) =>
      _$DefaultRatesFromJson(json);

  /// Tarif appliqué pour 1 heure de travail en centimes.
  @override
  final Money? hour;

  /// Tarif appliqué pour une demi-journée en centimes.
  @override
  final Money? halfDay;

  /// Tarif appliqué pour une journée complète en centimes.
  @override
  final Money? day;

  /// Tarif au forfait (sans notion de durée).
  @override
  final Money? fixedJob;

  /// Create a copy of DefaultRates
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DefaultRatesCopyWith<_DefaultRates> get copyWith =>
      __$DefaultRatesCopyWithImpl<_DefaultRates>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DefaultRatesToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DefaultRates &&
            (identical(other.hour, hour) || other.hour == hour) &&
            (identical(other.halfDay, halfDay) || other.halfDay == halfDay) &&
            (identical(other.day, day) || other.day == day) &&
            (identical(other.fixedJob, fixedJob) ||
                other.fixedJob == fixedJob));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, hour, halfDay, day, fixedJob);

  @override
  String toString() {
    return 'DefaultRates(hour: $hour, halfDay: $halfDay, day: $day, fixedJob: $fixedJob)';
  }
}

/// @nodoc
abstract mixin class _$DefaultRatesCopyWith<$Res>
    implements $DefaultRatesCopyWith<$Res> {
  factory _$DefaultRatesCopyWith(
          _DefaultRates value, $Res Function(_DefaultRates) _then) =
      __$DefaultRatesCopyWithImpl;
  @override
  @useResult
  $Res call({Money? hour, Money? halfDay, Money? day, Money? fixedJob});
}

/// @nodoc
class __$DefaultRatesCopyWithImpl<$Res>
    implements _$DefaultRatesCopyWith<$Res> {
  __$DefaultRatesCopyWithImpl(this._self, this._then);

  final _DefaultRates _self;
  final $Res Function(_DefaultRates) _then;

  /// Create a copy of DefaultRates
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hour = freezed,
    Object? halfDay = freezed,
    Object? day = freezed,
    Object? fixedJob = freezed,
  }) {
    return _then(_DefaultRates(
      hour: freezed == hour
          ? _self.hour
          : hour // ignore: cast_nullable_to_non_nullable
              as Money?,
      halfDay: freezed == halfDay
          ? _self.halfDay
          : halfDay // ignore: cast_nullable_to_non_nullable
              as Money?,
      day: freezed == day
          ? _self.day
          : day // ignore: cast_nullable_to_non_nullable
              as Money?,
      fixedJob: freezed == fixedJob
          ? _self.fixedJob
          : fixedJob // ignore: cast_nullable_to_non_nullable
              as Money?,
    ));
  }
}

// dart format on
