import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_calculator_service.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_entry_builder_service.dart';

void main() {
  final builder = WorkEntryBuilderService(WorkCalculatorService());

  final rates = DefaultRates(
    hour: Money.fromCents(2000),
    halfDay: Money.fromCents(15000),
    day: Money.fromCents(30000),
    fixedJob: Money.fromCents(50000),
  );

  DateTime fixedDate() => DateTime(2026, 1, 15);

  group('build — champs transmis tels quels', () {
    test('id, date, clientId, projectId, notes, createdAt, updatedAt', () {
      final entry = builder.build(
        id: 'entry-1',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'client-1',
        projectId: 'project-1',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.fromCents(16000),
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: 'RAS',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );

      expect(entry.id, 'entry-1');
      expect(entry.date, DateOnly.fromString('2026-01-15'));
      expect(entry.clientId, 'client-1');
      expect(entry.projectId, 'project-1');
      expect(entry.notes, 'RAS');
      expect(entry.createdAt, fixedDate());
      expect(entry.updatedAt, fixedDate());
      expect(entry.laborAmountHT, Money.fromCents(16000));
      // Champs non fournis par le formulaire : valeurs par défaut de WorkEntry.
      expect(entry.tags, isEmpty);
      expect(entry.tasks, isEmpty);
      expect(entry.attachments, isEmpty);
      expect(entry.timerUsed, isFalse);
    });

    test('projectId absent (null) reste null', () {
      final entry = builder.build(
        id: 'entry-1',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'client-1',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );

      expect(entry.projectId, isNull);
    });
  });

  group('build — durationMinutes délégué à WorkCalculatorService', () {
    test('calcule la durée à partir de start/end/pause', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );

      expect(entry.durationMinutes, 480);
    });

    test('lève ArgumentError si endTime <= startTime (même erreur que le service sous-jacent)', () {
      expect(
        () => builder.build(
          id: 'e',
          date: DateOnly.fromString('2026-01-15'),
          startTime: 1020,
          endTime: 480,
          pauseMinutes: 0,
          clientId: 'c',
          billingMode: BillingMode.hourly,
          laborAmountHT: Money.zero,
          clientDefaultRates: rates,
          travelDistanceKm: 0.0,
          travelRatePerKm: 0.20,
          notes: '',
          createdAt: fixedDate(),
          updatedAt: fixedDate(),
        ),
        throwsArgumentError,
      );
    });
  });

  group('build — rateApplied (taux unitaire selon le mode)', () {
    test('hourly → rates.hour', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.rateApplied, Money.fromCents(2000));
    });

    test('half_day → rates.halfDay', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.half_day,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.rateApplied, Money.fromCents(15000));
    });

    test('day → rates.day', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.day,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.rateApplied, Money.fromCents(30000));
    });

    test('fixed_job → rates.fixedJob', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.fixed_job,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.rateApplied, Money.fromCents(50000));
    });

    test('tarif non défini (null) pour le mode choisi → Money.zero', () {
      const emptyRates = DefaultRates();
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: emptyRates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.rateApplied, Money.zero);
    });
  });

  group('build — travelAmountHT = (distance * 2) * taux', () {
    test('sans déplacement (0 km) → zéro', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 0.0,
        travelRatePerKm: 0.20,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.travelAmountHT, Money.zero);
    });

    test('10 km à 0,50 €/km → 10,00 € (aller-retour)', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 10.0,
        travelRatePerKm: 0.5,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.travelAmountHT, Money.fromCents(1000));
    });

    test('travelDistanceKm et travelRatePerKm transmis tels quels sur l\'entrée', () {
      final entry = builder.build(
        id: 'e',
        date: DateOnly.fromString('2026-01-15'),
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 60,
        clientId: 'c',
        billingMode: BillingMode.hourly,
        laborAmountHT: Money.zero,
        clientDefaultRates: rates,
        travelDistanceKm: 12.5,
        travelRatePerKm: 0.35,
        notes: '',
        createdAt: fixedDate(),
        updatedAt: fixedDate(),
      );
      expect(entry.travelDistanceKm, 12.5);
      expect(entry.travelRatePerKm, 0.35);
    });
  });
}
