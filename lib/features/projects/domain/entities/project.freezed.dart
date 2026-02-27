// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Project implements DiagnosticableTreeMixin {
  /// Identifiant unique UUID v4.
  String get id;

  /// Identifiant du client auquel appartient ce chantier.
  String get clientId;

  /// Nom ou titre descriptif du chantier (ex: "Rénovation Cuisine Dupont").
  String get label;
  Address get address;
  ProjectType get type;
  ProjectStatus get status;
  String? get notes;
  String? get technicalNotes;
  String? get accessNotes;

  /// Distance (Aller simple) en kilomètres depuis le siège/domicile vers le chantier.
  /// Sera multipliée par 2 pour les frais de déplacement.
  double? get distanceKm;

  /// Date et heure de la création du dossier chantier.
  DateTime get createdAt;

  /// Date et heure de la dernière modification des informations du chantier.
  DateTime get updatedAt;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ProjectCopyWith<Project> get copyWith =>
      _$ProjectCopyWithImpl<Project>(this as Project, _$identity);

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Project'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('clientId', clientId))
      ..add(DiagnosticsProperty('label', label))
      ..add(DiagnosticsProperty('address', address))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('notes', notes))
      ..add(DiagnosticsProperty('technicalNotes', technicalNotes))
      ..add(DiagnosticsProperty('accessNotes', accessNotes))
      ..add(DiagnosticsProperty('distanceKm', distanceKm))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Project &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.technicalNotes, technicalNotes) ||
                other.technicalNotes == technicalNotes) &&
            (identical(other.accessNotes, accessNotes) ||
                other.accessNotes == accessNotes) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
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
      clientId,
      label,
      address,
      type,
      status,
      notes,
      technicalNotes,
      accessNotes,
      distanceKm,
      createdAt,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Project(id: $id, clientId: $clientId, label: $label, address: $address, type: $type, status: $status, notes: $notes, technicalNotes: $technicalNotes, accessNotes: $accessNotes, distanceKm: $distanceKm, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) _then) =
      _$ProjectCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String clientId,
      String label,
      Address address,
      ProjectType type,
      ProjectStatus status,
      String? notes,
      String? technicalNotes,
      String? accessNotes,
      double? distanceKm,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res> implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._self, this._then);

  final Project _self;
  final $Res Function(Project) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? label = null,
    Object? address = null,
    Object? type = null,
    Object? status = null,
    Object? notes = freezed,
    Object? technicalNotes = freezed,
    Object? accessNotes = freezed,
    Object? distanceKm = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
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
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as Address,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ProjectType,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      technicalNotes: freezed == technicalNotes
          ? _self.technicalNotes
          : technicalNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      accessNotes: freezed == accessNotes
          ? _self.accessNotes
          : accessNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      distanceKm: freezed == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
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

/// Adds pattern-matching-related methods to [Project].
extension ProjectPatterns on Project {
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
    TResult Function(_Project value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Project() when $default != null:
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
    TResult Function(_Project value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Project():
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
    TResult? Function(_Project value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Project() when $default != null:
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
            String clientId,
            String label,
            Address address,
            ProjectType type,
            ProjectStatus status,
            String? notes,
            String? technicalNotes,
            String? accessNotes,
            double? distanceKm,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Project() when $default != null:
        return $default(
            _that.id,
            _that.clientId,
            _that.label,
            _that.address,
            _that.type,
            _that.status,
            _that.notes,
            _that.technicalNotes,
            _that.accessNotes,
            _that.distanceKm,
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
            String clientId,
            String label,
            Address address,
            ProjectType type,
            ProjectStatus status,
            String? notes,
            String? technicalNotes,
            String? accessNotes,
            double? distanceKm,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Project():
        return $default(
            _that.id,
            _that.clientId,
            _that.label,
            _that.address,
            _that.type,
            _that.status,
            _that.notes,
            _that.technicalNotes,
            _that.accessNotes,
            _that.distanceKm,
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
            String clientId,
            String label,
            Address address,
            ProjectType type,
            ProjectStatus status,
            String? notes,
            String? technicalNotes,
            String? accessNotes,
            double? distanceKm,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Project() when $default != null:
        return $default(
            _that.id,
            _that.clientId,
            _that.label,
            _that.address,
            _that.type,
            _that.status,
            _that.notes,
            _that.technicalNotes,
            _that.accessNotes,
            _that.distanceKm,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Project with DiagnosticableTreeMixin implements Project {
  const _Project(
      {required this.id,
      required this.clientId,
      required this.label,
      required this.address,
      required this.type,
      required this.status,
      this.notes,
      this.technicalNotes,
      this.accessNotes,
      this.distanceKm,
      required this.createdAt,
      required this.updatedAt});
  factory _Project.fromJson(Map<String, dynamic> json) =>
      _$ProjectFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Identifiant du client auquel appartient ce chantier.
  @override
  final String clientId;

  /// Nom ou titre descriptif du chantier (ex: "Rénovation Cuisine Dupont").
  @override
  final String label;
  @override
  final Address address;
  @override
  final ProjectType type;
  @override
  final ProjectStatus status;
  @override
  final String? notes;
  @override
  final String? technicalNotes;
  @override
  final String? accessNotes;

  /// Distance (Aller simple) en kilomètres depuis le siège/domicile vers le chantier.
  /// Sera multipliée par 2 pour les frais de déplacement.
  @override
  final double? distanceKm;

  /// Date et heure de la création du dossier chantier.
  @override
  final DateTime createdAt;

  /// Date et heure de la dernière modification des informations du chantier.
  @override
  final DateTime updatedAt;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ProjectCopyWith<_Project> get copyWith =>
      __$ProjectCopyWithImpl<_Project>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ProjectToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'Project'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('clientId', clientId))
      ..add(DiagnosticsProperty('label', label))
      ..add(DiagnosticsProperty('address', address))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('status', status))
      ..add(DiagnosticsProperty('notes', notes))
      ..add(DiagnosticsProperty('technicalNotes', technicalNotes))
      ..add(DiagnosticsProperty('accessNotes', accessNotes))
      ..add(DiagnosticsProperty('distanceKm', distanceKm))
      ..add(DiagnosticsProperty('createdAt', createdAt))
      ..add(DiagnosticsProperty('updatedAt', updatedAt));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Project &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.technicalNotes, technicalNotes) ||
                other.technicalNotes == technicalNotes) &&
            (identical(other.accessNotes, accessNotes) ||
                other.accessNotes == accessNotes) &&
            (identical(other.distanceKm, distanceKm) ||
                other.distanceKm == distanceKm) &&
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
      clientId,
      label,
      address,
      type,
      status,
      notes,
      technicalNotes,
      accessNotes,
      distanceKm,
      createdAt,
      updatedAt);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'Project(id: $id, clientId: $clientId, label: $label, address: $address, type: $type, status: $status, notes: $notes, technicalNotes: $technicalNotes, accessNotes: $accessNotes, distanceKm: $distanceKm, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ProjectCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$ProjectCopyWith(_Project value, $Res Function(_Project) _then) =
      __$ProjectCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String clientId,
      String label,
      Address address,
      ProjectType type,
      ProjectStatus status,
      String? notes,
      String? technicalNotes,
      String? accessNotes,
      double? distanceKm,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$ProjectCopyWithImpl<$Res> implements _$ProjectCopyWith<$Res> {
  __$ProjectCopyWithImpl(this._self, this._then);

  final _Project _self;
  final $Res Function(_Project) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? clientId = null,
    Object? label = null,
    Object? address = null,
    Object? type = null,
    Object? status = null,
    Object? notes = freezed,
    Object? technicalNotes = freezed,
    Object? accessNotes = freezed,
    Object? distanceKm = freezed,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_Project(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      address: null == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as Address,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as ProjectType,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as ProjectStatus,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      technicalNotes: freezed == technicalNotes
          ? _self.technicalNotes
          : technicalNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      accessNotes: freezed == accessNotes
          ? _self.accessNotes
          : accessNotes // ignore: cast_nullable_to_non_nullable
              as String?,
      distanceKm: freezed == distanceKm
          ? _self.distanceKm
          : distanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
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
