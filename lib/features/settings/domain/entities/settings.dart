import 'package:freezed_annotation/freezed_annotation.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

@freezed
abstract class Settings with _$Settings {
  const factory Settings({
    @Default(8) int dayHours,
    @Default(4) int halfDayHours,
    @Default(0) int defaultPauseMinutes,
    @Default(15) int roundingMinutes,
    @Default(2.0) double minBillingHours,
    @Default(2500) int minBillingAmountCents,  // 25€
    @Default('EUR') String currency,
    @Default('BE') String country,
    @Default(50) int travelRatePerKmCents,  // 0.50€
    @Default([
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
      'Contrôle Vinçotte',
    ]) List<String> quickTasks,
    @Default([
      'Brico',
      'Cebeo',
      'Rexel',
      'Elec 44',
      'Van Marcke',
      'Autre',
    ]) List<String> quickVendors,
    @Default(PdfHeader()) PdfHeader pdfHeader,
    @Default(false) bool autoBackupEnabled,
    DateTime? lastBackupAt,
    @Default(1) int schemaVersion,
  }) = _Settings;

  factory Settings.fromJson(Map<String, dynamic> json) => _$SettingsFromJson(json);
}

@freezed
abstract class PdfHeader with _$PdfHeader {
  const factory PdfHeader({
    @Default('') String name,
    @Default('') String phone,
    String? email,
    String? address,
    String? tvaNumber,
    @Default('Prix HT') String mentionHT,
  }) = _PdfHeader;

  factory PdfHeader.fromJson(Map<String, dynamic> json) => _$PdfHeaderFromJson(json);
}
