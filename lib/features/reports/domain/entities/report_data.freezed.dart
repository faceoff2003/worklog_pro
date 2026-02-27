// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'report_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReportData {
  /// Total de la main d'ouvre accumulée.
  Money get totalLaborAmount;

  /// Total des frais de déplacements accumulés.
  Money get totalTravelAmount;

  /// Total des dépenses qui peuvent être refacturées au client.
  Money get totalBillableExpenses;

  /// Total des dépenses internes de fonctionnement (non refacturables).
  Money get totalNonBillableExpenses;

  /// Somme totale de tous les encaissements perçus.
  Money get totalPayments;

  /// Les entrées de travail détaillées intégrées dans le rapport.
  List<WorkEntry> get workEntries;

  /// Les dépenses détaillées intégrées.
  List<Expense> get expenses;

  /// Les paiements détaillés intégrés.
  List<Payment> get payments;

  /// Période de validité des filtres du rapport.
  DateTimeRange get dateRange;

  /// Create a copy of ReportData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReportDataCopyWith<ReportData> get copyWith =>
      _$ReportDataCopyWithImpl<ReportData>(this as ReportData, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReportData &&
            (identical(other.totalLaborAmount, totalLaborAmount) ||
                other.totalLaborAmount == totalLaborAmount) &&
            (identical(other.totalTravelAmount, totalTravelAmount) ||
                other.totalTravelAmount == totalTravelAmount) &&
            (identical(other.totalBillableExpenses, totalBillableExpenses) ||
                other.totalBillableExpenses == totalBillableExpenses) &&
            (identical(
                    other.totalNonBillableExpenses, totalNonBillableExpenses) ||
                other.totalNonBillableExpenses == totalNonBillableExpenses) &&
            (identical(other.totalPayments, totalPayments) ||
                other.totalPayments == totalPayments) &&
            const DeepCollectionEquality()
                .equals(other.workEntries, workEntries) &&
            const DeepCollectionEquality().equals(other.expenses, expenses) &&
            const DeepCollectionEquality().equals(other.payments, payments) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalLaborAmount,
      totalTravelAmount,
      totalBillableExpenses,
      totalNonBillableExpenses,
      totalPayments,
      const DeepCollectionEquality().hash(workEntries),
      const DeepCollectionEquality().hash(expenses),
      const DeepCollectionEquality().hash(payments),
      dateRange);

  @override
  String toString() {
    return 'ReportData(totalLaborAmount: $totalLaborAmount, totalTravelAmount: $totalTravelAmount, totalBillableExpenses: $totalBillableExpenses, totalNonBillableExpenses: $totalNonBillableExpenses, totalPayments: $totalPayments, workEntries: $workEntries, expenses: $expenses, payments: $payments, dateRange: $dateRange)';
  }
}

/// @nodoc
abstract mixin class $ReportDataCopyWith<$Res> {
  factory $ReportDataCopyWith(
          ReportData value, $Res Function(ReportData) _then) =
      _$ReportDataCopyWithImpl;
  @useResult
  $Res call(
      {Money totalLaborAmount,
      Money totalTravelAmount,
      Money totalBillableExpenses,
      Money totalNonBillableExpenses,
      Money totalPayments,
      List<WorkEntry> workEntries,
      List<Expense> expenses,
      List<Payment> payments,
      DateTimeRange dateRange});
}

/// @nodoc
class _$ReportDataCopyWithImpl<$Res> implements $ReportDataCopyWith<$Res> {
  _$ReportDataCopyWithImpl(this._self, this._then);

  final ReportData _self;
  final $Res Function(ReportData) _then;

  /// Create a copy of ReportData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalLaborAmount = null,
    Object? totalTravelAmount = null,
    Object? totalBillableExpenses = null,
    Object? totalNonBillableExpenses = null,
    Object? totalPayments = null,
    Object? workEntries = null,
    Object? expenses = null,
    Object? payments = null,
    Object? dateRange = null,
  }) {
    return _then(_self.copyWith(
      totalLaborAmount: null == totalLaborAmount
          ? _self.totalLaborAmount
          : totalLaborAmount // ignore: cast_nullable_to_non_nullable
              as Money,
      totalTravelAmount: null == totalTravelAmount
          ? _self.totalTravelAmount
          : totalTravelAmount // ignore: cast_nullable_to_non_nullable
              as Money,
      totalBillableExpenses: null == totalBillableExpenses
          ? _self.totalBillableExpenses
          : totalBillableExpenses // ignore: cast_nullable_to_non_nullable
              as Money,
      totalNonBillableExpenses: null == totalNonBillableExpenses
          ? _self.totalNonBillableExpenses
          : totalNonBillableExpenses // ignore: cast_nullable_to_non_nullable
              as Money,
      totalPayments: null == totalPayments
          ? _self.totalPayments
          : totalPayments // ignore: cast_nullable_to_non_nullable
              as Money,
      workEntries: null == workEntries
          ? _self.workEntries
          : workEntries // ignore: cast_nullable_to_non_nullable
              as List<WorkEntry>,
      expenses: null == expenses
          ? _self.expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<Expense>,
      payments: null == payments
          ? _self.payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
      dateRange: null == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange,
    ));
  }
}

/// Adds pattern-matching-related methods to [ReportData].
extension ReportDataPatterns on ReportData {
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
    TResult Function(_ReportData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReportData() when $default != null:
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
    TResult Function(_ReportData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReportData():
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
    TResult? Function(_ReportData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReportData() when $default != null:
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
            Money totalLaborAmount,
            Money totalTravelAmount,
            Money totalBillableExpenses,
            Money totalNonBillableExpenses,
            Money totalPayments,
            List<WorkEntry> workEntries,
            List<Expense> expenses,
            List<Payment> payments,
            DateTimeRange dateRange)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReportData() when $default != null:
        return $default(
            _that.totalLaborAmount,
            _that.totalTravelAmount,
            _that.totalBillableExpenses,
            _that.totalNonBillableExpenses,
            _that.totalPayments,
            _that.workEntries,
            _that.expenses,
            _that.payments,
            _that.dateRange);
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
            Money totalLaborAmount,
            Money totalTravelAmount,
            Money totalBillableExpenses,
            Money totalNonBillableExpenses,
            Money totalPayments,
            List<WorkEntry> workEntries,
            List<Expense> expenses,
            List<Payment> payments,
            DateTimeRange dateRange)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReportData():
        return $default(
            _that.totalLaborAmount,
            _that.totalTravelAmount,
            _that.totalBillableExpenses,
            _that.totalNonBillableExpenses,
            _that.totalPayments,
            _that.workEntries,
            _that.expenses,
            _that.payments,
            _that.dateRange);
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
            Money totalLaborAmount,
            Money totalTravelAmount,
            Money totalBillableExpenses,
            Money totalNonBillableExpenses,
            Money totalPayments,
            List<WorkEntry> workEntries,
            List<Expense> expenses,
            List<Payment> payments,
            DateTimeRange dateRange)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReportData() when $default != null:
        return $default(
            _that.totalLaborAmount,
            _that.totalTravelAmount,
            _that.totalBillableExpenses,
            _that.totalNonBillableExpenses,
            _that.totalPayments,
            _that.workEntries,
            _that.expenses,
            _that.payments,
            _that.dateRange);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ReportData extends ReportData {
  const _ReportData(
      {required this.totalLaborAmount,
      required this.totalTravelAmount,
      required this.totalBillableExpenses,
      required this.totalNonBillableExpenses,
      required this.totalPayments,
      required final List<WorkEntry> workEntries,
      required final List<Expense> expenses,
      required final List<Payment> payments,
      required this.dateRange})
      : _workEntries = workEntries,
        _expenses = expenses,
        _payments = payments,
        super._();

  /// Total de la main d'ouvre accumulée.
  @override
  final Money totalLaborAmount;

  /// Total des frais de déplacements accumulés.
  @override
  final Money totalTravelAmount;

  /// Total des dépenses qui peuvent être refacturées au client.
  @override
  final Money totalBillableExpenses;

  /// Total des dépenses internes de fonctionnement (non refacturables).
  @override
  final Money totalNonBillableExpenses;

  /// Somme totale de tous les encaissements perçus.
  @override
  final Money totalPayments;

  /// Les entrées de travail détaillées intégrées dans le rapport.
  final List<WorkEntry> _workEntries;

  /// Les entrées de travail détaillées intégrées dans le rapport.
  @override
  List<WorkEntry> get workEntries {
    if (_workEntries is EqualUnmodifiableListView) return _workEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workEntries);
  }

  /// Les dépenses détaillées intégrées.
  final List<Expense> _expenses;

  /// Les dépenses détaillées intégrées.
  @override
  List<Expense> get expenses {
    if (_expenses is EqualUnmodifiableListView) return _expenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_expenses);
  }

  /// Les paiements détaillés intégrés.
  final List<Payment> _payments;

  /// Les paiements détaillés intégrés.
  @override
  List<Payment> get payments {
    if (_payments is EqualUnmodifiableListView) return _payments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_payments);
  }

  /// Période de validité des filtres du rapport.
  @override
  final DateTimeRange dateRange;

  /// Create a copy of ReportData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReportDataCopyWith<_ReportData> get copyWith =>
      __$ReportDataCopyWithImpl<_ReportData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReportData &&
            (identical(other.totalLaborAmount, totalLaborAmount) ||
                other.totalLaborAmount == totalLaborAmount) &&
            (identical(other.totalTravelAmount, totalTravelAmount) ||
                other.totalTravelAmount == totalTravelAmount) &&
            (identical(other.totalBillableExpenses, totalBillableExpenses) ||
                other.totalBillableExpenses == totalBillableExpenses) &&
            (identical(
                    other.totalNonBillableExpenses, totalNonBillableExpenses) ||
                other.totalNonBillableExpenses == totalNonBillableExpenses) &&
            (identical(other.totalPayments, totalPayments) ||
                other.totalPayments == totalPayments) &&
            const DeepCollectionEquality()
                .equals(other._workEntries, _workEntries) &&
            const DeepCollectionEquality().equals(other._expenses, _expenses) &&
            const DeepCollectionEquality().equals(other._payments, _payments) &&
            (identical(other.dateRange, dateRange) ||
                other.dateRange == dateRange));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalLaborAmount,
      totalTravelAmount,
      totalBillableExpenses,
      totalNonBillableExpenses,
      totalPayments,
      const DeepCollectionEquality().hash(_workEntries),
      const DeepCollectionEquality().hash(_expenses),
      const DeepCollectionEquality().hash(_payments),
      dateRange);

  @override
  String toString() {
    return 'ReportData(totalLaborAmount: $totalLaborAmount, totalTravelAmount: $totalTravelAmount, totalBillableExpenses: $totalBillableExpenses, totalNonBillableExpenses: $totalNonBillableExpenses, totalPayments: $totalPayments, workEntries: $workEntries, expenses: $expenses, payments: $payments, dateRange: $dateRange)';
  }
}

/// @nodoc
abstract mixin class _$ReportDataCopyWith<$Res>
    implements $ReportDataCopyWith<$Res> {
  factory _$ReportDataCopyWith(
          _ReportData value, $Res Function(_ReportData) _then) =
      __$ReportDataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {Money totalLaborAmount,
      Money totalTravelAmount,
      Money totalBillableExpenses,
      Money totalNonBillableExpenses,
      Money totalPayments,
      List<WorkEntry> workEntries,
      List<Expense> expenses,
      List<Payment> payments,
      DateTimeRange dateRange});
}

/// @nodoc
class __$ReportDataCopyWithImpl<$Res> implements _$ReportDataCopyWith<$Res> {
  __$ReportDataCopyWithImpl(this._self, this._then);

  final _ReportData _self;
  final $Res Function(_ReportData) _then;

  /// Create a copy of ReportData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalLaborAmount = null,
    Object? totalTravelAmount = null,
    Object? totalBillableExpenses = null,
    Object? totalNonBillableExpenses = null,
    Object? totalPayments = null,
    Object? workEntries = null,
    Object? expenses = null,
    Object? payments = null,
    Object? dateRange = null,
  }) {
    return _then(_ReportData(
      totalLaborAmount: null == totalLaborAmount
          ? _self.totalLaborAmount
          : totalLaborAmount // ignore: cast_nullable_to_non_nullable
              as Money,
      totalTravelAmount: null == totalTravelAmount
          ? _self.totalTravelAmount
          : totalTravelAmount // ignore: cast_nullable_to_non_nullable
              as Money,
      totalBillableExpenses: null == totalBillableExpenses
          ? _self.totalBillableExpenses
          : totalBillableExpenses // ignore: cast_nullable_to_non_nullable
              as Money,
      totalNonBillableExpenses: null == totalNonBillableExpenses
          ? _self.totalNonBillableExpenses
          : totalNonBillableExpenses // ignore: cast_nullable_to_non_nullable
              as Money,
      totalPayments: null == totalPayments
          ? _self.totalPayments
          : totalPayments // ignore: cast_nullable_to_non_nullable
              as Money,
      workEntries: null == workEntries
          ? _self._workEntries
          : workEntries // ignore: cast_nullable_to_non_nullable
              as List<WorkEntry>,
      expenses: null == expenses
          ? _self._expenses
          : expenses // ignore: cast_nullable_to_non_nullable
              as List<Expense>,
      payments: null == payments
          ? _self._payments
          : payments // ignore: cast_nullable_to_non_nullable
              as List<Payment>,
      dateRange: null == dateRange
          ? _self.dateRange
          : dateRange // ignore: cast_nullable_to_non_nullable
              as DateTimeRange,
    ));
  }
}

// dart format on
