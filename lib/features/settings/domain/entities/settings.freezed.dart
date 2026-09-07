// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Settings {
  int get dayHours;
  int get halfDayHours;
  int get defaultPauseMinutes;
  int get roundingMinutes;
  double get minBillingHours;
  int get minBillingAmountCents; // 25€
  String get currency;
  String get country;
  int get travelRatePerKmCents; // 0.50€
  List<String> get quickTasks;
  List<String> get quickVendors;
  PdfHeader get pdfHeader;
  bool get autoBackupEnabled;
  DateTime? get lastBackupAt;
  int get schemaVersion; // Nullable, pas de @Default : un JSON local existant écrit avant
// F-SETTINGS.4 n'a pas ce champ, il doit rester lisible (null = "aussi
// vieux que possible", cf. la logique de conflit last-write-wins).
  DateTime? get updatedAt;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SettingsCopyWith<Settings> get copyWith =>
      _$SettingsCopyWithImpl<Settings>(this as Settings, _$identity);

  /// Serializes this Settings to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Settings &&
            (identical(other.dayHours, dayHours) ||
                other.dayHours == dayHours) &&
            (identical(other.halfDayHours, halfDayHours) ||
                other.halfDayHours == halfDayHours) &&
            (identical(other.defaultPauseMinutes, defaultPauseMinutes) ||
                other.defaultPauseMinutes == defaultPauseMinutes) &&
            (identical(other.roundingMinutes, roundingMinutes) ||
                other.roundingMinutes == roundingMinutes) &&
            (identical(other.minBillingHours, minBillingHours) ||
                other.minBillingHours == minBillingHours) &&
            (identical(other.minBillingAmountCents, minBillingAmountCents) ||
                other.minBillingAmountCents == minBillingAmountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.travelRatePerKmCents, travelRatePerKmCents) ||
                other.travelRatePerKmCents == travelRatePerKmCents) &&
            const DeepCollectionEquality()
                .equals(other.quickTasks, quickTasks) &&
            const DeepCollectionEquality()
                .equals(other.quickVendors, quickVendors) &&
            (identical(other.pdfHeader, pdfHeader) ||
                other.pdfHeader == pdfHeader) &&
            (identical(other.autoBackupEnabled, autoBackupEnabled) ||
                other.autoBackupEnabled == autoBackupEnabled) &&
            (identical(other.lastBackupAt, lastBackupAt) ||
                other.lastBackupAt == lastBackupAt) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayHours,
      halfDayHours,
      defaultPauseMinutes,
      roundingMinutes,
      minBillingHours,
      minBillingAmountCents,
      currency,
      country,
      travelRatePerKmCents,
      const DeepCollectionEquality().hash(quickTasks),
      const DeepCollectionEquality().hash(quickVendors),
      pdfHeader,
      autoBackupEnabled,
      lastBackupAt,
      schemaVersion,
      updatedAt);

  @override
  String toString() {
    return 'Settings(dayHours: $dayHours, halfDayHours: $halfDayHours, defaultPauseMinutes: $defaultPauseMinutes, roundingMinutes: $roundingMinutes, minBillingHours: $minBillingHours, minBillingAmountCents: $minBillingAmountCents, currency: $currency, country: $country, travelRatePerKmCents: $travelRatePerKmCents, quickTasks: $quickTasks, quickVendors: $quickVendors, pdfHeader: $pdfHeader, autoBackupEnabled: $autoBackupEnabled, lastBackupAt: $lastBackupAt, schemaVersion: $schemaVersion, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $SettingsCopyWith<$Res> {
  factory $SettingsCopyWith(Settings value, $Res Function(Settings) _then) =
      _$SettingsCopyWithImpl;
  @useResult
  $Res call(
      {int dayHours,
      int halfDayHours,
      int defaultPauseMinutes,
      int roundingMinutes,
      double minBillingHours,
      int minBillingAmountCents,
      String currency,
      String country,
      int travelRatePerKmCents,
      List<String> quickTasks,
      List<String> quickVendors,
      PdfHeader pdfHeader,
      bool autoBackupEnabled,
      DateTime? lastBackupAt,
      int schemaVersion,
      DateTime? updatedAt});

  $PdfHeaderCopyWith<$Res> get pdfHeader;
}

/// @nodoc
class _$SettingsCopyWithImpl<$Res> implements $SettingsCopyWith<$Res> {
  _$SettingsCopyWithImpl(this._self, this._then);

  final Settings _self;
  final $Res Function(Settings) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayHours = null,
    Object? halfDayHours = null,
    Object? defaultPauseMinutes = null,
    Object? roundingMinutes = null,
    Object? minBillingHours = null,
    Object? minBillingAmountCents = null,
    Object? currency = null,
    Object? country = null,
    Object? travelRatePerKmCents = null,
    Object? quickTasks = null,
    Object? quickVendors = null,
    Object? pdfHeader = null,
    Object? autoBackupEnabled = null,
    Object? lastBackupAt = freezed,
    Object? schemaVersion = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_self.copyWith(
      dayHours: null == dayHours
          ? _self.dayHours
          : dayHours // ignore: cast_nullable_to_non_nullable
              as int,
      halfDayHours: null == halfDayHours
          ? _self.halfDayHours
          : halfDayHours // ignore: cast_nullable_to_non_nullable
              as int,
      defaultPauseMinutes: null == defaultPauseMinutes
          ? _self.defaultPauseMinutes
          : defaultPauseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      roundingMinutes: null == roundingMinutes
          ? _self.roundingMinutes
          : roundingMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      minBillingHours: null == minBillingHours
          ? _self.minBillingHours
          : minBillingHours // ignore: cast_nullable_to_non_nullable
              as double,
      minBillingAmountCents: null == minBillingAmountCents
          ? _self.minBillingAmountCents
          : minBillingAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      travelRatePerKmCents: null == travelRatePerKmCents
          ? _self.travelRatePerKmCents
          : travelRatePerKmCents // ignore: cast_nullable_to_non_nullable
              as int,
      quickTasks: null == quickTasks
          ? _self.quickTasks
          : quickTasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      quickVendors: null == quickVendors
          ? _self.quickVendors
          : quickVendors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pdfHeader: null == pdfHeader
          ? _self.pdfHeader
          : pdfHeader // ignore: cast_nullable_to_non_nullable
              as PdfHeader,
      autoBackupEnabled: null == autoBackupEnabled
          ? _self.autoBackupEnabled
          : autoBackupEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      lastBackupAt: freezed == lastBackupAt
          ? _self.lastBackupAt
          : lastBackupAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfHeaderCopyWith<$Res> get pdfHeader {
    return $PdfHeaderCopyWith<$Res>(_self.pdfHeader, (value) {
      return _then(_self.copyWith(pdfHeader: value));
    });
  }
}

/// Adds pattern-matching-related methods to [Settings].
extension SettingsPatterns on Settings {
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
    TResult Function(_Settings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Settings() when $default != null:
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
    TResult Function(_Settings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Settings():
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
    TResult? Function(_Settings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Settings() when $default != null:
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
            int dayHours,
            int halfDayHours,
            int defaultPauseMinutes,
            int roundingMinutes,
            double minBillingHours,
            int minBillingAmountCents,
            String currency,
            String country,
            int travelRatePerKmCents,
            List<String> quickTasks,
            List<String> quickVendors,
            PdfHeader pdfHeader,
            bool autoBackupEnabled,
            DateTime? lastBackupAt,
            int schemaVersion,
            DateTime? updatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Settings() when $default != null:
        return $default(
            _that.dayHours,
            _that.halfDayHours,
            _that.defaultPauseMinutes,
            _that.roundingMinutes,
            _that.minBillingHours,
            _that.minBillingAmountCents,
            _that.currency,
            _that.country,
            _that.travelRatePerKmCents,
            _that.quickTasks,
            _that.quickVendors,
            _that.pdfHeader,
            _that.autoBackupEnabled,
            _that.lastBackupAt,
            _that.schemaVersion,
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
            int dayHours,
            int halfDayHours,
            int defaultPauseMinutes,
            int roundingMinutes,
            double minBillingHours,
            int minBillingAmountCents,
            String currency,
            String country,
            int travelRatePerKmCents,
            List<String> quickTasks,
            List<String> quickVendors,
            PdfHeader pdfHeader,
            bool autoBackupEnabled,
            DateTime? lastBackupAt,
            int schemaVersion,
            DateTime? updatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Settings():
        return $default(
            _that.dayHours,
            _that.halfDayHours,
            _that.defaultPauseMinutes,
            _that.roundingMinutes,
            _that.minBillingHours,
            _that.minBillingAmountCents,
            _that.currency,
            _that.country,
            _that.travelRatePerKmCents,
            _that.quickTasks,
            _that.quickVendors,
            _that.pdfHeader,
            _that.autoBackupEnabled,
            _that.lastBackupAt,
            _that.schemaVersion,
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
            int dayHours,
            int halfDayHours,
            int defaultPauseMinutes,
            int roundingMinutes,
            double minBillingHours,
            int minBillingAmountCents,
            String currency,
            String country,
            int travelRatePerKmCents,
            List<String> quickTasks,
            List<String> quickVendors,
            PdfHeader pdfHeader,
            bool autoBackupEnabled,
            DateTime? lastBackupAt,
            int schemaVersion,
            DateTime? updatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Settings() when $default != null:
        return $default(
            _that.dayHours,
            _that.halfDayHours,
            _that.defaultPauseMinutes,
            _that.roundingMinutes,
            _that.minBillingHours,
            _that.minBillingAmountCents,
            _that.currency,
            _that.country,
            _that.travelRatePerKmCents,
            _that.quickTasks,
            _that.quickVendors,
            _that.pdfHeader,
            _that.autoBackupEnabled,
            _that.lastBackupAt,
            _that.schemaVersion,
            _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Settings implements Settings {
  const _Settings(
      {this.dayHours = 8,
      this.halfDayHours = 4,
      this.defaultPauseMinutes = 0,
      this.roundingMinutes = 15,
      this.minBillingHours = 2.0,
      this.minBillingAmountCents = 2500,
      this.currency = 'EUR',
      this.country = 'BE',
      this.travelRatePerKmCents = 50,
      final List<String> quickTasks = const [
        'Tirage câble',
        'Saignées',
        'Coffret / Tableau',
        'Raccordement',
        'Tests / Mesures',
        'Schéma unifilaire',
        'Schéma de position',
        'Pose prises',
        'Pose interrupteurs',
        'Pose luminaires',
        'Pose goulottes / chemins de câbles',
        'Domotique',
        'Parlophone / Vidéophone',
        'Alarme',
        'Mise en conformité',
        'Dépannage',
        'Contrôle Vinçotte'
      ],
      final List<String> quickVendors = const [
        'Brico',
        'Cebeo',
        'Rexel',
        'Elec 44',
        'Van Marcke',
        'Autre'
      ],
      this.pdfHeader = const PdfHeader(),
      this.autoBackupEnabled = false,
      this.lastBackupAt,
      this.schemaVersion = 1,
      this.updatedAt})
      : _quickTasks = quickTasks,
        _quickVendors = quickVendors;
  factory _Settings.fromJson(Map<String, dynamic> json) =>
      _$SettingsFromJson(json);

  @override
  @JsonKey()
  final int dayHours;
  @override
  @JsonKey()
  final int halfDayHours;
  @override
  @JsonKey()
  final int defaultPauseMinutes;
  @override
  @JsonKey()
  final int roundingMinutes;
  @override
  @JsonKey()
  final double minBillingHours;
  @override
  @JsonKey()
  final int minBillingAmountCents;
// 25€
  @override
  @JsonKey()
  final String currency;
  @override
  @JsonKey()
  final String country;
  @override
  @JsonKey()
  final int travelRatePerKmCents;
// 0.50€
  final List<String> _quickTasks;
// 0.50€
  @override
  @JsonKey()
  List<String> get quickTasks {
    if (_quickTasks is EqualUnmodifiableListView) return _quickTasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quickTasks);
  }

  final List<String> _quickVendors;
  @override
  @JsonKey()
  List<String> get quickVendors {
    if (_quickVendors is EqualUnmodifiableListView) return _quickVendors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_quickVendors);
  }

  @override
  @JsonKey()
  final PdfHeader pdfHeader;
  @override
  @JsonKey()
  final bool autoBackupEnabled;
  @override
  final DateTime? lastBackupAt;
  @override
  @JsonKey()
  final int schemaVersion;
// Nullable, pas de @Default : un JSON local existant écrit avant
// F-SETTINGS.4 n'a pas ce champ, il doit rester lisible (null = "aussi
// vieux que possible", cf. la logique de conflit last-write-wins).
  @override
  final DateTime? updatedAt;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SettingsCopyWith<_Settings> get copyWith =>
      __$SettingsCopyWithImpl<_Settings>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SettingsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Settings &&
            (identical(other.dayHours, dayHours) ||
                other.dayHours == dayHours) &&
            (identical(other.halfDayHours, halfDayHours) ||
                other.halfDayHours == halfDayHours) &&
            (identical(other.defaultPauseMinutes, defaultPauseMinutes) ||
                other.defaultPauseMinutes == defaultPauseMinutes) &&
            (identical(other.roundingMinutes, roundingMinutes) ||
                other.roundingMinutes == roundingMinutes) &&
            (identical(other.minBillingHours, minBillingHours) ||
                other.minBillingHours == minBillingHours) &&
            (identical(other.minBillingAmountCents, minBillingAmountCents) ||
                other.minBillingAmountCents == minBillingAmountCents) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.country, country) || other.country == country) &&
            (identical(other.travelRatePerKmCents, travelRatePerKmCents) ||
                other.travelRatePerKmCents == travelRatePerKmCents) &&
            const DeepCollectionEquality()
                .equals(other._quickTasks, _quickTasks) &&
            const DeepCollectionEquality()
                .equals(other._quickVendors, _quickVendors) &&
            (identical(other.pdfHeader, pdfHeader) ||
                other.pdfHeader == pdfHeader) &&
            (identical(other.autoBackupEnabled, autoBackupEnabled) ||
                other.autoBackupEnabled == autoBackupEnabled) &&
            (identical(other.lastBackupAt, lastBackupAt) ||
                other.lastBackupAt == lastBackupAt) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dayHours,
      halfDayHours,
      defaultPauseMinutes,
      roundingMinutes,
      minBillingHours,
      minBillingAmountCents,
      currency,
      country,
      travelRatePerKmCents,
      const DeepCollectionEquality().hash(_quickTasks),
      const DeepCollectionEquality().hash(_quickVendors),
      pdfHeader,
      autoBackupEnabled,
      lastBackupAt,
      schemaVersion,
      updatedAt);

  @override
  String toString() {
    return 'Settings(dayHours: $dayHours, halfDayHours: $halfDayHours, defaultPauseMinutes: $defaultPauseMinutes, roundingMinutes: $roundingMinutes, minBillingHours: $minBillingHours, minBillingAmountCents: $minBillingAmountCents, currency: $currency, country: $country, travelRatePerKmCents: $travelRatePerKmCents, quickTasks: $quickTasks, quickVendors: $quickVendors, pdfHeader: $pdfHeader, autoBackupEnabled: $autoBackupEnabled, lastBackupAt: $lastBackupAt, schemaVersion: $schemaVersion, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$SettingsCopyWith<$Res>
    implements $SettingsCopyWith<$Res> {
  factory _$SettingsCopyWith(_Settings value, $Res Function(_Settings) _then) =
      __$SettingsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int dayHours,
      int halfDayHours,
      int defaultPauseMinutes,
      int roundingMinutes,
      double minBillingHours,
      int minBillingAmountCents,
      String currency,
      String country,
      int travelRatePerKmCents,
      List<String> quickTasks,
      List<String> quickVendors,
      PdfHeader pdfHeader,
      bool autoBackupEnabled,
      DateTime? lastBackupAt,
      int schemaVersion,
      DateTime? updatedAt});

  @override
  $PdfHeaderCopyWith<$Res> get pdfHeader;
}

/// @nodoc
class __$SettingsCopyWithImpl<$Res> implements _$SettingsCopyWith<$Res> {
  __$SettingsCopyWithImpl(this._self, this._then);

  final _Settings _self;
  final $Res Function(_Settings) _then;

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayHours = null,
    Object? halfDayHours = null,
    Object? defaultPauseMinutes = null,
    Object? roundingMinutes = null,
    Object? minBillingHours = null,
    Object? minBillingAmountCents = null,
    Object? currency = null,
    Object? country = null,
    Object? travelRatePerKmCents = null,
    Object? quickTasks = null,
    Object? quickVendors = null,
    Object? pdfHeader = null,
    Object? autoBackupEnabled = null,
    Object? lastBackupAt = freezed,
    Object? schemaVersion = null,
    Object? updatedAt = freezed,
  }) {
    return _then(_Settings(
      dayHours: null == dayHours
          ? _self.dayHours
          : dayHours // ignore: cast_nullable_to_non_nullable
              as int,
      halfDayHours: null == halfDayHours
          ? _self.halfDayHours
          : halfDayHours // ignore: cast_nullable_to_non_nullable
              as int,
      defaultPauseMinutes: null == defaultPauseMinutes
          ? _self.defaultPauseMinutes
          : defaultPauseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      roundingMinutes: null == roundingMinutes
          ? _self.roundingMinutes
          : roundingMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      minBillingHours: null == minBillingHours
          ? _self.minBillingHours
          : minBillingHours // ignore: cast_nullable_to_non_nullable
              as double,
      minBillingAmountCents: null == minBillingAmountCents
          ? _self.minBillingAmountCents
          : minBillingAmountCents // ignore: cast_nullable_to_non_nullable
              as int,
      currency: null == currency
          ? _self.currency
          : currency // ignore: cast_nullable_to_non_nullable
              as String,
      country: null == country
          ? _self.country
          : country // ignore: cast_nullable_to_non_nullable
              as String,
      travelRatePerKmCents: null == travelRatePerKmCents
          ? _self.travelRatePerKmCents
          : travelRatePerKmCents // ignore: cast_nullable_to_non_nullable
              as int,
      quickTasks: null == quickTasks
          ? _self._quickTasks
          : quickTasks // ignore: cast_nullable_to_non_nullable
              as List<String>,
      quickVendors: null == quickVendors
          ? _self._quickVendors
          : quickVendors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      pdfHeader: null == pdfHeader
          ? _self.pdfHeader
          : pdfHeader // ignore: cast_nullable_to_non_nullable
              as PdfHeader,
      autoBackupEnabled: null == autoBackupEnabled
          ? _self.autoBackupEnabled
          : autoBackupEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      lastBackupAt: freezed == lastBackupAt
          ? _self.lastBackupAt
          : lastBackupAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      schemaVersion: null == schemaVersion
          ? _self.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
      updatedAt: freezed == updatedAt
          ? _self.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }

  /// Create a copy of Settings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $PdfHeaderCopyWith<$Res> get pdfHeader {
    return $PdfHeaderCopyWith<$Res>(_self.pdfHeader, (value) {
      return _then(_self.copyWith(pdfHeader: value));
    });
  }
}

/// @nodoc
mixin _$PdfHeader {
  String get name;
  String get phone;
  String? get email;
  String? get address;
  String? get tvaNumber;
  String get mentionHT;

  /// Create a copy of PdfHeader
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PdfHeaderCopyWith<PdfHeader> get copyWith =>
      _$PdfHeaderCopyWithImpl<PdfHeader>(this as PdfHeader, _$identity);

  /// Serializes this PdfHeader to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PdfHeader &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.tvaNumber, tvaNumber) ||
                other.tvaNumber == tvaNumber) &&
            (identical(other.mentionHT, mentionHT) ||
                other.mentionHT == mentionHT));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, phone, email, address, tvaNumber, mentionHT);

  @override
  String toString() {
    return 'PdfHeader(name: $name, phone: $phone, email: $email, address: $address, tvaNumber: $tvaNumber, mentionHT: $mentionHT)';
  }
}

/// @nodoc
abstract mixin class $PdfHeaderCopyWith<$Res> {
  factory $PdfHeaderCopyWith(PdfHeader value, $Res Function(PdfHeader) _then) =
      _$PdfHeaderCopyWithImpl;
  @useResult
  $Res call(
      {String name,
      String phone,
      String? email,
      String? address,
      String? tvaNumber,
      String mentionHT});
}

/// @nodoc
class _$PdfHeaderCopyWithImpl<$Res> implements $PdfHeaderCopyWith<$Res> {
  _$PdfHeaderCopyWithImpl(this._self, this._then);

  final PdfHeader _self;
  final $Res Function(PdfHeader) _then;

  /// Create a copy of PdfHeader
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? tvaNumber = freezed,
    Object? mentionHT = null,
  }) {
    return _then(_self.copyWith(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      tvaNumber: freezed == tvaNumber
          ? _self.tvaNumber
          : tvaNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionHT: null == mentionHT
          ? _self.mentionHT
          : mentionHT // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [PdfHeader].
extension PdfHeaderPatterns on PdfHeader {
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
    TResult Function(_PdfHeader value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PdfHeader() when $default != null:
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
    TResult Function(_PdfHeader value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfHeader():
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
    TResult? Function(_PdfHeader value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfHeader() when $default != null:
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
    TResult Function(String name, String phone, String? email, String? address,
            String? tvaNumber, String mentionHT)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PdfHeader() when $default != null:
        return $default(_that.name, _that.phone, _that.email, _that.address,
            _that.tvaNumber, _that.mentionHT);
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
    TResult Function(String name, String phone, String? email, String? address,
            String? tvaNumber, String mentionHT)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfHeader():
        return $default(_that.name, _that.phone, _that.email, _that.address,
            _that.tvaNumber, _that.mentionHT);
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
    TResult? Function(String name, String phone, String? email, String? address,
            String? tvaNumber, String mentionHT)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PdfHeader() when $default != null:
        return $default(_that.name, _that.phone, _that.email, _that.address,
            _that.tvaNumber, _that.mentionHT);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PdfHeader implements PdfHeader {
  const _PdfHeader(
      {this.name = '',
      this.phone = '',
      this.email,
      this.address,
      this.tvaNumber,
      this.mentionHT = 'Prix HT'});
  factory _PdfHeader.fromJson(Map<String, dynamic> json) =>
      _$PdfHeaderFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  @JsonKey()
  final String phone;
  @override
  final String? email;
  @override
  final String? address;
  @override
  final String? tvaNumber;
  @override
  @JsonKey()
  final String mentionHT;

  /// Create a copy of PdfHeader
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PdfHeaderCopyWith<_PdfHeader> get copyWith =>
      __$PdfHeaderCopyWithImpl<_PdfHeader>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PdfHeaderToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PdfHeader &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.phone, phone) || other.phone == phone) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.tvaNumber, tvaNumber) ||
                other.tvaNumber == tvaNumber) &&
            (identical(other.mentionHT, mentionHT) ||
                other.mentionHT == mentionHT));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, name, phone, email, address, tvaNumber, mentionHT);

  @override
  String toString() {
    return 'PdfHeader(name: $name, phone: $phone, email: $email, address: $address, tvaNumber: $tvaNumber, mentionHT: $mentionHT)';
  }
}

/// @nodoc
abstract mixin class _$PdfHeaderCopyWith<$Res>
    implements $PdfHeaderCopyWith<$Res> {
  factory _$PdfHeaderCopyWith(
          _PdfHeader value, $Res Function(_PdfHeader) _then) =
      __$PdfHeaderCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String name,
      String phone,
      String? email,
      String? address,
      String? tvaNumber,
      String mentionHT});
}

/// @nodoc
class __$PdfHeaderCopyWithImpl<$Res> implements _$PdfHeaderCopyWith<$Res> {
  __$PdfHeaderCopyWithImpl(this._self, this._then);

  final _PdfHeader _self;
  final $Res Function(_PdfHeader) _then;

  /// Create a copy of PdfHeader
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? name = null,
    Object? phone = null,
    Object? email = freezed,
    Object? address = freezed,
    Object? tvaNumber = freezed,
    Object? mentionHT = null,
  }) {
    return _then(_PdfHeader(
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      phone: null == phone
          ? _self.phone
          : phone // ignore: cast_nullable_to_non_nullable
              as String,
      email: freezed == email
          ? _self.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      address: freezed == address
          ? _self.address
          : address // ignore: cast_nullable_to_non_nullable
              as String?,
      tvaNumber: freezed == tvaNumber
          ? _self.tvaNumber
          : tvaNumber // ignore: cast_nullable_to_non_nullable
              as String?,
      mentionHT: null == mentionHT
          ? _self.mentionHT
          : mentionHT // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
