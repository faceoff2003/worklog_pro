// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'expense.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Expense {
  /// Identifiant unique UUID v4.
  String get id;

  /// Date de la dépense.
  DateOnly get date;

  /// Client rattaché (ou aucun).
  String get clientId;

  /// Chantier concerné.
  String? get projectId;

  /// Catégorie comptable (matériaux, outillage, sous-traitance, etc.).
  ExpenseCategory get category;

  /// Montant Hors Taxes investi (stocké en centimes via [Money]).
  Money get amountHT;

  /// Description claire de la dépense (ex: "Peinture murale 10L").
  String get description; // Optional details
  /// Magasin ou fournisseur.
  String? get vendor;

  /// Sous-catégorie si c'est du matériel.
  MaterialCategory? get materialCategory;

  /// Type de transport utilisé si lié au déplacement.
  TravelMode? get travelMode;

  /// Kilomètres associés si frais de transport externe (péage, essence).
  double? get travelDistanceKm;

  /// Vrai si la dépense doit être refacturée au client au moment du bilan.
  bool get isBillable;

  /// Photos des reçus ou factures d'achat.
  List<Attachment> get attachments;

  /// Date de création de l'enregistrement.
  DateTime get createdAt;

  /// Dernière modification de l'enregistrement.
  DateTime get updatedAt;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExpenseCopyWith<Expense> get copyWith =>
      _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);

  /// Serializes this Expense to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Expense &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.amountHT, amountHT) ||
                other.amountHT == amountHT) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.materialCategory, materialCategory) ||
                other.materialCategory == materialCategory) &&
            (identical(other.travelMode, travelMode) ||
                other.travelMode == travelMode) &&
            (identical(other.travelDistanceKm, travelDistanceKm) ||
                other.travelDistanceKm == travelDistanceKm) &&
            (identical(other.isBillable, isBillable) ||
                other.isBillable == isBillable) &&
            const DeepCollectionEquality()
                .equals(other.attachments, attachments) &&
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
      date,
      clientId,
      projectId,
      category,
      amountHT,
      description,
      vendor,
      materialCategory,
      travelMode,
      travelDistanceKm,
      isBillable,
      const DeepCollectionEquality().hash(attachments),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Expense(id: $id, date: $date, clientId: $clientId, projectId: $projectId, category: $category, amountHT: $amountHT, description: $description, vendor: $vendor, materialCategory: $materialCategory, travelMode: $travelMode, travelDistanceKm: $travelDistanceKm, isBillable: $isBillable, attachments: $attachments, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res> {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) =
      _$ExpenseCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      String clientId,
      String? projectId,
      ExpenseCategory category,
      Money amountHT,
      String description,
      String? vendor,
      MaterialCategory? materialCategory,
      TravelMode? travelMode,
      double? travelDistanceKm,
      bool isBillable,
      List<Attachment> attachments,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class _$ExpenseCopyWithImpl<$Res> implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? category = null,
    Object? amountHT = null,
    Object? description = null,
    Object? vendor = freezed,
    Object? materialCategory = freezed,
    Object? travelMode = freezed,
    Object? travelDistanceKm = freezed,
    Object? isBillable = null,
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
      clientId: null == clientId
          ? _self.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String,
      projectId: freezed == projectId
          ? _self.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as ExpenseCategory,
      amountHT: null == amountHT
          ? _self.amountHT
          : amountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: freezed == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String?,
      materialCategory: freezed == materialCategory
          ? _self.materialCategory
          : materialCategory // ignore: cast_nullable_to_non_nullable
              as MaterialCategory?,
      travelMode: freezed == travelMode
          ? _self.travelMode
          : travelMode // ignore: cast_nullable_to_non_nullable
              as TravelMode?,
      travelDistanceKm: freezed == travelDistanceKm
          ? _self.travelDistanceKm
          : travelDistanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
      isBillable: null == isBillable
          ? _self.isBillable
          : isBillable // ignore: cast_nullable_to_non_nullable
              as bool,
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

/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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
    TResult Function(_Expense value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Expense() when $default != null:
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
    TResult Function(_Expense value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Expense():
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
    TResult? Function(_Expense value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Expense() when $default != null:
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
            ExpenseCategory category,
            Money amountHT,
            String description,
            String? vendor,
            MaterialCategory? materialCategory,
            TravelMode? travelMode,
            double? travelDistanceKm,
            bool isBillable,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Expense() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.category,
            _that.amountHT,
            _that.description,
            _that.vendor,
            _that.materialCategory,
            _that.travelMode,
            _that.travelDistanceKm,
            _that.isBillable,
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
            String clientId,
            String? projectId,
            ExpenseCategory category,
            Money amountHT,
            String description,
            String? vendor,
            MaterialCategory? materialCategory,
            TravelMode? travelMode,
            double? travelDistanceKm,
            bool isBillable,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Expense():
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.category,
            _that.amountHT,
            _that.description,
            _that.vendor,
            _that.materialCategory,
            _that.travelMode,
            _that.travelDistanceKm,
            _that.isBillable,
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
            String clientId,
            String? projectId,
            ExpenseCategory category,
            Money amountHT,
            String description,
            String? vendor,
            MaterialCategory? materialCategory,
            TravelMode? travelMode,
            double? travelDistanceKm,
            bool isBillable,
            List<Attachment> attachments,
            DateTime createdAt,
            DateTime updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Expense() when $default != null:
        return $default(
            _that.id,
            _that.date,
            _that.clientId,
            _that.projectId,
            _that.category,
            _that.amountHT,
            _that.description,
            _that.vendor,
            _that.materialCategory,
            _that.travelMode,
            _that.travelDistanceKm,
            _that.isBillable,
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
class _Expense implements Expense {
  const _Expense(
      {required this.id,
      required this.date,
      required this.clientId,
      this.projectId,
      required this.category,
      required this.amountHT,
      required this.description,
      this.vendor,
      this.materialCategory,
      this.travelMode,
      this.travelDistanceKm,
      this.isBillable = true,
      final List<Attachment> attachments = const [],
      required this.createdAt,
      required this.updatedAt})
      : _attachments = attachments;
  factory _Expense.fromJson(Map<String, dynamic> json) =>
      _$ExpenseFromJson(json);

  /// Identifiant unique UUID v4.
  @override
  final String id;

  /// Date de la dépense.
  @override
  final DateOnly date;

  /// Client rattaché (ou aucun).
  @override
  final String clientId;

  /// Chantier concerné.
  @override
  final String? projectId;

  /// Catégorie comptable (matériaux, outillage, sous-traitance, etc.).
  @override
  final ExpenseCategory category;

  /// Montant Hors Taxes investi (stocké en centimes via [Money]).
  @override
  final Money amountHT;

  /// Description claire de la dépense (ex: "Peinture murale 10L").
  @override
  final String description;
// Optional details
  /// Magasin ou fournisseur.
  @override
  final String? vendor;

  /// Sous-catégorie si c'est du matériel.
  @override
  final MaterialCategory? materialCategory;

  /// Type de transport utilisé si lié au déplacement.
  @override
  final TravelMode? travelMode;

  /// Kilomètres associés si frais de transport externe (péage, essence).
  @override
  final double? travelDistanceKm;

  /// Vrai si la dépense doit être refacturée au client au moment du bilan.
  @override
  @JsonKey()
  final bool isBillable;

  /// Photos des reçus ou factures d'achat.
  final List<Attachment> _attachments;

  /// Photos des reçus ou factures d'achat.
  @override
  @JsonKey()
  List<Attachment> get attachments {
    if (_attachments is EqualUnmodifiableListView) return _attachments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_attachments);
  }

  /// Date de création de l'enregistrement.
  @override
  final DateTime createdAt;

  /// Dernière modification de l'enregistrement.
  @override
  final DateTime updatedAt;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExpenseCopyWith<_Expense> get copyWith =>
      __$ExpenseCopyWithImpl<_Expense>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExpenseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Expense &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.amountHT, amountHT) ||
                other.amountHT == amountHT) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.vendor, vendor) || other.vendor == vendor) &&
            (identical(other.materialCategory, materialCategory) ||
                other.materialCategory == materialCategory) &&
            (identical(other.travelMode, travelMode) ||
                other.travelMode == travelMode) &&
            (identical(other.travelDistanceKm, travelDistanceKm) ||
                other.travelDistanceKm == travelDistanceKm) &&
            (identical(other.isBillable, isBillable) ||
                other.isBillable == isBillable) &&
            const DeepCollectionEquality()
                .equals(other._attachments, _attachments) &&
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
      date,
      clientId,
      projectId,
      category,
      amountHT,
      description,
      vendor,
      materialCategory,
      travelMode,
      travelDistanceKm,
      isBillable,
      const DeepCollectionEquality().hash(_attachments),
      createdAt,
      updatedAt);

  @override
  String toString() {
    return 'Expense(id: $id, date: $date, clientId: $clientId, projectId: $projectId, category: $category, amountHT: $amountHT, description: $description, vendor: $vendor, materialCategory: $materialCategory, travelMode: $travelMode, travelDistanceKm: $travelDistanceKm, isBillable: $isBillable, attachments: $attachments, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) =
      __$ExpenseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      DateOnly date,
      String clientId,
      String? projectId,
      ExpenseCategory category,
      Money amountHT,
      String description,
      String? vendor,
      MaterialCategory? materialCategory,
      TravelMode? travelMode,
      double? travelDistanceKm,
      bool isBillable,
      List<Attachment> attachments,
      DateTime createdAt,
      DateTime updatedAt});
}

/// @nodoc
class __$ExpenseCopyWithImpl<$Res> implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

  /// Create a copy of Expense
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? date = null,
    Object? clientId = null,
    Object? projectId = freezed,
    Object? category = null,
    Object? amountHT = null,
    Object? description = null,
    Object? vendor = freezed,
    Object? materialCategory = freezed,
    Object? travelMode = freezed,
    Object? travelDistanceKm = freezed,
    Object? isBillable = null,
    Object? attachments = null,
    Object? createdAt = null,
    Object? updatedAt = null,
  }) {
    return _then(_Expense(
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
      category: null == category
          ? _self.category
          : category // ignore: cast_nullable_to_non_nullable
              as ExpenseCategory,
      amountHT: null == amountHT
          ? _self.amountHT
          : amountHT // ignore: cast_nullable_to_non_nullable
              as Money,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      vendor: freezed == vendor
          ? _self.vendor
          : vendor // ignore: cast_nullable_to_non_nullable
              as String?,
      materialCategory: freezed == materialCategory
          ? _self.materialCategory
          : materialCategory // ignore: cast_nullable_to_non_nullable
              as MaterialCategory?,
      travelMode: freezed == travelMode
          ? _self.travelMode
          : travelMode // ignore: cast_nullable_to_non_nullable
              as TravelMode?,
      travelDistanceKm: freezed == travelDistanceKm
          ? _self.travelDistanceKm
          : travelDistanceKm // ignore: cast_nullable_to_non_nullable
              as double?,
      isBillable: null == isBillable
          ? _self.isBillable
          : isBillable // ignore: cast_nullable_to_non_nullable
              as bool,
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
