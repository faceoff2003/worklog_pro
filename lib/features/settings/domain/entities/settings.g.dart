// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Settings _$SettingsFromJson(Map<String, dynamic> json) => _Settings(
      dayHours: (json['dayHours'] as num?)?.toInt() ?? 8,
      halfDayHours: (json['halfDayHours'] as num?)?.toInt() ?? 4,
      defaultPauseMinutes: (json['defaultPauseMinutes'] as num?)?.toInt() ?? 0,
      roundingMinutes: (json['roundingMinutes'] as num?)?.toInt() ?? 15,
      minBillingHours: (json['minBillingHours'] as num?)?.toDouble() ?? 2.0,
      minBillingAmountCents:
          (json['minBillingAmountCents'] as num?)?.toInt() ?? 2500,
      currency: json['currency'] as String? ?? 'EUR',
      country: json['country'] as String? ?? 'BE',
      travelRatePerKmCents:
          (json['travelRatePerKmCents'] as num?)?.toInt() ?? 50,
      quickTasks: (json['quickTasks'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [
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
      quickVendors: (json['quickVendors'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['Brico', 'Cebeo', 'Rexel', 'Elec 44', 'Van Marcke', 'Autre'],
      pdfHeader: json['pdfHeader'] == null
          ? const PdfHeader()
          : PdfHeader.fromJson(json['pdfHeader'] as Map<String, dynamic>),
      autoBackupEnabled: json['autoBackupEnabled'] as bool? ?? false,
      lastBackupAt: json['lastBackupAt'] == null
          ? null
          : DateTime.parse(json['lastBackupAt'] as String),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SettingsToJson(_Settings instance) => <String, dynamic>{
      'dayHours': instance.dayHours,
      'halfDayHours': instance.halfDayHours,
      'defaultPauseMinutes': instance.defaultPauseMinutes,
      'roundingMinutes': instance.roundingMinutes,
      'minBillingHours': instance.minBillingHours,
      'minBillingAmountCents': instance.minBillingAmountCents,
      'currency': instance.currency,
      'country': instance.country,
      'travelRatePerKmCents': instance.travelRatePerKmCents,
      'quickTasks': instance.quickTasks,
      'quickVendors': instance.quickVendors,
      'pdfHeader': instance.pdfHeader.toJson(),
      'autoBackupEnabled': instance.autoBackupEnabled,
      'lastBackupAt': instance.lastBackupAt?.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

_PdfHeader _$PdfHeaderFromJson(Map<String, dynamic> json) => _PdfHeader(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String?,
      address: json['address'] as String?,
      tvaNumber: json['tvaNumber'] as String?,
      mentionHT: json['mentionHT'] as String? ?? 'Prix HT',
    );

Map<String, dynamic> _$PdfHeaderToJson(_PdfHeader instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
      'email': instance.email,
      'address': instance.address,
      'tvaNumber': instance.tvaNumber,
      'mentionHT': instance.mentionHT,
    };
