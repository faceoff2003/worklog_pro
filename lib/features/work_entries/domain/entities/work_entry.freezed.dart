// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'work_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkEntry {
  /// Identifiant unique UUID v4.
  String get id;

  /// Date précise à laquelle la prestation a eu lieu.
  DateOnly get date;

  /// Heure d'arrivée sur les lieux (exprimée en minutes écoulées depuis minuit, ex: 480 pour 08h00).
  int get startTime;

  /// Heure de départ des lieux (exprimée en minutes écoulées depuis minuit).
  int get endTime;

  /// Temps de pause en minutes (ex: repas de midi). Sera déduit du temps total.
  int get pauseMinutes;

  /// Durée de travail calculée = (endTime - startTime) - pauseMinutes.
  int get durationMinutes;

  /// Client lié à la prestation.
  String get clientId;

  /// Chantier lié à la prestation (Optionnel).
  String? get projectId;

  /// Liste des tâches accomplies durant la journée.
  List<String> get tasks;

  /// Notes ou détails internes pour l'organisation.
  String? get notes;

  /// Mode de facturation choisi (Horaire ou Forfait).
  BillingMode get billingMode;

  /// Taux appliqué pour construire la facture finale.
  Money get rateApplied;

  /// Total monétaire (Main d'Oeuvre HT) facturé.
  Money get laborAmountHT;

  /// Distance (Aller) parcourue pour le chantier.
  double get travelDistanceKm;

  /// Indemnité facturée par kilomètre.
  double get travelRatePerKm;

  /// Total facturé pour le déplacement : (travelDistanceKm * 2) * travelRatePerKm.
  Money get travelAmountHT;

  /// Vrai si la durée a été chronométrée au lieu d'être entrée manuellement.
  bool get timerUsed;

  /// Étiquettes pour classifier la prestation.
  List<String> get tags;

  /// Fichiers ou photos associés (Bons de travaux, signatures...).
  List<Attachment> get attachments;

  /// Date de création.
  DateTime get createdAt;

  /// Date de modification.
  DateTime get updatedAt;

  /// Create a copy of WorkEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkEntryCopyWith<WorkEntry> get copyWith =>
      _$WorkEntryCopyWithImpl<WorkEntry>(this as WorkEntry, _$identity);

  /// Serializes this WorkEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.pauseMinutes, pauseMinutes) ||
                other.pauseMinutes == pauseMinutes) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            const DeepCollectionEquality().equals(other.tasks, tasks) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.billingMode, billingMode) ||
                other.billingMode == billingMode) &&
            (identical(other.rateApplied, rateApplied) ||
                other.rateApplied == rateApplied) &&
            (identical(other.laborAmountHT, laborAmountHT) ||
                other.laborAmountHT == laborAmountHT) &&
            (identical(other.travelDistanceKm, travelDistanceKm) ||
                other.travelDistanceKm == travelDistanceKm) &&
            (identical(other.travelRatePerKm, travelRatePerKm) ||
                other.travelRatePerKm == travelRatePerKm) &&
            (identical(other.travelAmountHT, travelAmountHT) ||
                other.travelAmountHT == travelAmountHT) &&
            (identical(other.timerUsed, timerUsed) ||
                other.timerUsed == timerUsed) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            const DeepCollectionEquality()
                .equals(other.attachments, attachments) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        date,
        startTime,
        endTime,
        pauseMinutes,
        durationMinutes,
        clientId,
        projectId,
        const DeepCollectionEquality().hash(tasks),
        notes,
        billingMode,
        rateApplied,
        laborAmountHT,
        travelDistanceKm,
        travelRatePerKm,
        travelAmountHT,
        timerUsed,
        const DeepCollectionEquality().hash(tags),
        const DeepCollectionEquality().hash(attachments),
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'WorkEntry(id: $id, date: $date, startTime: $startTime, endTime: $endTime, pauseMinutes: $pauseMinutes, durationMinutes: $durationMinutes, clientId: $clientId, projectId: $projectId, tasks: $tasks, notes: $notes, billingMode: $billingMode, rateApplied: $rateApplied, laborAmountHT: $laborAmountHT, travelDistanceKm: $travelDistanceKm, travelRatePerKm: $travelRatePerKm, travelAmountHT: $travelAmountHT, timerUsed: $timerUsed, tags: $tags, attachments: $attachments, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $WorkEntryCopyWith<$Res> {
  factory $WorkEntryCopyWith(WorkEntry value, $Res Function(WorkEntry) _then) =
      _$WorkEntryCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      int startTime,
      int endTime,
      int pauseMinutes,
      int durationMinutes,
      String clientId,
      String? projectId,
      List<String> tasks,
      String? notes,
      BillingMode billingMode,
      Money rateApplied,
      Money laborAmountHT,
      double travelDistanceKm,
      double travelRatePerKm,
      Money travelAmountHT,
      bool timerUsed,
      List<String> tags,
      List<Attachment> attachments,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$WorkEntryCopyWithImpl<$Res> implements $WorkEntryCopyWith<$Res> {
  _$WorkEntryCopyWithImpl(this._self, this._then);

  final WorkEntry _self;
  final $Res Function(WorkEntry) _then;

  /// Create a copy of WorkEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? pauseMinutes = null,
    Object? durationMinutes = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? tasks = null,
    Object? notes = freezed,
    Object? billingMode = null,
    Object? rateApplied = null,
    Object? laborAmountHT = null,
    Object? travelDistanceKm = null,
    Object? travelRatePerKm = null,
    Object? travelAmountHT = null,
    Object? timerUsed = null,
    Object? tags = null,
    Object? attachments = null,
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
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int,
      pauseMinutes: null == pauseMinutes
          ? _self.pauseMinutes
          : pauseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      tasks: null == tasks
          ? _self.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      billingMode: null == billingMode
          ? _self.billingMode
          : billingMode // ignore: cast_nullable_to_non_nullable
              as BillingMode,
      rateApplied: null == rateApplied
          ? _self.rateApplied
          : rateApplied // ignore: cast_nullable_to_non_nullable
              as Money,
      laborAmountHT: null == laborAmountHT
          ? _self.laborAmountHT
          : laborAmountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      travelDistanceKm: null == travelDistanceKm
          ? _self.travelDistanceKm
          : travelDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      travelRatePerKm: null == travelRatePerKm
          ? _self.travelRatePerKm
          : travelRatePerKm // ignore: cast_nullable_to_non_nullable
              as double,
      travelAmountHT: null == travelAmountHT
          ? _self.travelAmountHT
          : travelAmountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      timerUsed: null == timerUsed
          ? _self.timerUsed
          : timerUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      attachments: null == attachments
          ? _self.attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Attachment>,
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

/// Adds pattern-matching-related methods to [WorkEntry].
extension WorkEntryPatterns on WorkEntry {
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
    TResult Function(_WorkEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkEntry() when $default != null:
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
    TResult Function(_WorkEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkEntry():
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
    TResult? Function(_WorkEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkEntry() when $default != null:
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
            int startTime,
            int endTime,
            int pauseMinutes,
            int durationMinutes,
            String clientId,
            String? projectId,
            List<String> tasks,
            String? notes,
            BillingMode billingMode,
            Money rateApplied,
            Money laborAmountHT,
            double travelDistanceKm,
            double travelRatePerKm,
            Money travelAmountHT,
            bool timerUsed,
            List<String> tags,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkEntry() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.startTime,
            _that.endTime,
            _that.pauseMinutes,
            _that.durationMinutes,
            _that.clientId,
            _that.projectId,
            _that.tasks,
            _that.notes,
            _that.billingMode,
            _that.rateApplied,
            _that.laborAmountHT,
            _that.travelDistanceKm,
            _that.travelRatePerKm,
            _that.travelAmountHT,
            _that.timerUsed,
            _that.tags,
            _that.attachments,
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
            int startTime,
            int endTime,
            int pauseMinutes,
            int durationMinutes,
            String clientId,
            String? projectId,
            List<String> tasks,
            String? notes,
            BillingMode billingMode,
            Money rateApplied,
            Money laborAmountHT,
            double travelDistanceKm,
            double travelRatePerKm,
            Money travelAmountHT,
            bool timerUsed,
            List<String> tags,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkEntry():
        return $default(
            _that.id,
            _that.date,
            _that.startTime,
            _that.endTime,
            _that.pauseMinutes,
            _that.durationMinutes,
            _that.clientId,
            _that.projectId,
            _that.tasks,
            _that.notes,
            _that.billingMode,
            _that.rateApplied,
            _that.laborAmountHT,
            _that.travelDistanceKm,
            _that.travelRatePerKm,
            _that.travelAmountHT,
            _that.timerUsed,
            _that.tags,
            _that.attachments,
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
            int startTime,
            int endTime,
            int pauseMinutes,
            int durationMinutes,
            String clientId,
            String? projectId,
            List<String> tasks,
            String? notes,
            BillingMode billingMode,
            Money rateApplied,
            Money laborAmountHT,
            double travelDistanceKm,
            double travelRatePerKm,
            Money travelAmountHT,
            bool timerUsed,
            List<String> tags,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkEntry() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.startTime,
            _that.endTime,
            _that.pauseMinutes,
            _that.durationMinutes,
            _that.clientId,
            _that.projectId,
            _that.tasks,
            _that.notes,
            _that.billingMode,
            _that.rateApplied,
            _that.laborAmountHT,
            _that.travelDistanceKm,
            _that.travelRatePerKm,
            _that.travelAmountHT,
            _that.timerUsed,
            _that.tags,
            _that.attachments,
            _that.createdAt,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkEntry implements WorkEntry {
  const _WorkEntry(
      {required this.id,
      required this.date,
      required this.startTime,
      required this.endTime,
      this.pauseMinutes = 0,
      required this.durationMinutes,
      required this.clientId,
      this.projectId,
      final List<String> tasks = const [],
      this.notes,
      required this.billingMode,
      required this.rateApplied,
      required this.laborAmountHT,
      this.travelDistanceKm = 0.0,
      this.travelRatePerKm = 0.20,
      this.travelAmountHT = Money.zero,
      this.timerUsed = false,
      final List<String> tags = const [],
      final List<Attachment> attachments = const [],
      required this.createdAt,
      required this.updatedAt})
      : _tasks = tasks,
        _tags = tags,
        _attachments = attachments;
  factory _WorkEntry.fromJson(Map<String, dynamic> json) =>
      _$WorkEntryFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Date précise à laquelle la prestation a eu lieu.
  @override
  final DateOnly date;

  /// Heure d'arrivée sur les lieux (exprimée en minutes écoulées depuis minuit, ex: 480 pour 08h00).
  @override
  final int startTime;

  /// Heure de départ des lieux (exprimée en minutes écoulées depuis minuit).
  @override
  final int endTime;

  /// Temps de pause en minutes (ex: repas de midi). Sera déduit du temps total.
  @override
  @JsonKey()
  final int pauseMinutes;

  /// Durée de travail calculée = (endTime - startTime) - pauseMinutes.
  @override
  final int durationMinutes;

  /// Client lié à la prestation.
  @override
  final String clientId;

  /// Chantier lié à la prestation (Optionnel).
  @override
  final String? projectId;

  /// Liste des tâches accomplies durant la journée.
  final List<String> _tasks;

  /// Liste des tâches accomplies durant la journée.
  @override
  @JsonKey()
  List<String> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

  /// Notes ou détails internes pour l'organisation.
  @override
  final String? notes;

  /// Mode de facturation choisi (Horaire ou Forfait).
  @override
  final BillingMode billingMode;

  /// Taux appliqué pour construire la facture finale.
  @override
  final Money rateApplied;

  /// Total monétaire (Main d'Oeuvre HT) facturé.
  @override
  final Money laborAmountHT;

  /// Distance (Aller) parcourue pour le chantier.
  @override
  @JsonKey()
  final double travelDistanceKm;

  /// Indemnité facturée par kilomètre.
  @override
  @JsonKey()
  final double travelRatePerKm;

  /// Total facturé pour le déplacement : (travelDistanceKm * 2) * travelRatePerKm.
  @override
  @JsonKey()
  final Money travelAmountHT;

  /// Vrai si la durée a été chronométrée au lieu d'être entrée manuellement.
  @override
  @JsonKey()
  final bool timerUsed;

  /// Étiquettes pour classifier la prestation.
  final List<String> _tags;

  /// Étiquettes pour classifier la prestation.
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// Fichiers ou photos associés (Bons de travaux, signatures...).
  final List<Attachment> _attachments;

  /// Fichiers ou photos associés (Bons de travaux, signatures...).
  @override
  @JsonKey()
  List<Attachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  /// Date de création.
  @override
  final DateTime createdAt;

  /// Date de modification.
  @override
  final DateTime updatedAt;

  /// Create a copy of WorkEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkEntryCopyWith<_WorkEntry> get copyWith =>
      __$WorkEntryCopyWithImpl<_WorkEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.pauseMinutes, pauseMinutes) ||
                other.pauseMinutes == pauseMinutes) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.billingMode, billingMode) ||
                other.billingMode == billingMode) &&
            (identical(other.rateApplied, rateApplied) ||
                other.rateApplied == rateApplied) &&
            (identical(other.laborAmountHT, laborAmountHT) ||
                other.laborAmountHT == laborAmountHT) &&
            (identical(other.travelDistanceKm, travelDistanceKm) ||
                other.travelDistanceKm == travelDistanceKm) &&
            (identical(other.travelRatePerKm, travelRatePerKm) ||
                other.travelRatePerKm == travelRatePerKm) &&
            (identical(other.travelAmountHT, travelAmountHT) ||
                other.travelAmountHT == travelAmountHT) &&
            (identical(other.timerUsed, timerUsed) ||
                other.timerUsed == timerUsed) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        date,
        startTime,
        endTime,
        pauseMinutes,
        durationMinutes,
        clientId,
        projectId,
        const DeepCollectionEquality().hash(_tasks),
        notes,
        billingMode,
        rateApplied,
        laborAmountHT,
        travelDistanceKm,
        travelRatePerKm,
        travelAmountHT,
        timerUsed,
        const DeepCollectionEquality().hash(_tags),
        const DeepCollectionEquality().hash(_attachments),
        createdAt,
        updatedAt
      ]);

  @override
  String toString() {
    return 'WorkEntry(id: $id, date: $date, startTime: $startTime, endTime: $endTime, pauseMinutes: $pauseMinutes, durationMinutes: $durationMinutes, clientId: $clientId, projectId: $projectId, tasks: $tasks, notes: $notes, billingMode: $billingMode, rateApplied: $rateApplied, laborAmountHT: $laborAmountHT, travelDistanceKm: $travelDistanceKm, travelRatePerKm: $travelRatePerKm, travelAmountHT: $travelAmountHT, timerUsed: $timerUsed, tags: $tags, attachments: $attachments, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$WorkEntryCopyWith<$Res>
    implements $WorkEntryCopyWith<$Res> {
  factory _$WorkEntryCopyWith(
          _WorkEntry value, $Res Function(_WorkEntry) _then) =
      __$WorkEntryCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      int startTime,
      int endTime,
      int pauseMinutes,
      int durationMinutes,
      String clientId,
      String? projectId,
      List<String> tasks,
      String? notes,
      BillingMode billingMode,
      Money rateApplied,
      Money laborAmountHT,
      double travelDistanceKm,
      double travelRatePerKm,
      Money travelAmountHT,
      bool timerUsed,
      List<String> tags,
      List<Attachment> attachments,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$WorkEntryCopyWithImpl<$Res> implements _$WorkEntryCopyWith<$Res> {
  __$WorkEntryCopyWithImpl(this._self, this._then);

  final _WorkEntry _self;
  final $Res Function(_WorkEntry) _then;

  /// Create a copy of WorkEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? pauseMinutes = null,
    Object? durationMinutes = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? tasks = null,
    Object? notes = freezed,
    Object? billingMode = null,
    Object? rateApplied = null,
    Object? laborAmountHT = null,
    Object? travelDistanceKm = null,
    Object? travelRatePerKm = null,
    Object? travelAmountHT = null,
    Object? timerUsed = null,
    Object? tags = null,
    Object? attachments = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_WorkEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateOnly,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as int,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as int,
      pauseMinutes: null == pauseMinutes
          ? _self.pauseMinutes
          : pauseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      tasks: null == tasks
          ? _self._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      billingMode: null == billingMode
          ? _self.billingMode
          : billingMode // ignore: cast_nullable_to_non_nullable
              as BillingMode,
      rateApplied: null == rateApplied
          ? _self.rateApplied
          : rateApplied // ignore: cast_nullable_to_non_nullable
              as Money,
      laborAmountHT: null == laborAmountHT
          ? _self.laborAmountHT
          : laborAmountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      travelDistanceKm: null == travelDistanceKm
          ? _self.travelDistanceKm
          : travelDistanceKm // ignore: cast_nullable_to_non_nullable
              as double,
      travelRatePerKm: null == travelRatePerKm
          ? _self.travelRatePerKm
          : travelRatePerKm // ignore: cast_nullable_to_non_nullable
              as double,
      travelAmountHT: null == travelAmountHT
          ? _self.travelAmountHT
          : travelAmountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      timerUsed: null == timerUsed
          ? _self.timerUsed
          : timerUsed // ignore: cast_nullable_to_non_nullable
              as bool,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      attachments: null == attachments
          ? _self._attachments
          : attachments // ignore: cast_nullable_to_non_nullable
              as List<Attachment>,
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
