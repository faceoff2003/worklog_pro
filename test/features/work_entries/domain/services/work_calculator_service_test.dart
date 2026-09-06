import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_calculator_service.dart';

void main() {
  final service = WorkCalculatorService();

  // ─────────────────────────────────────────────────────────────
  // calculateDuration
  // ─────────────────────────────────────────────────────────────
  group('calculateDuration', () {
    test('calcule une durée simple sans pause', () {
      expect(service.calculateDuration(480, 1020), 540);
    });

    test('soustrait la pause', () {
      expect(service.calculateDuration(480, 1020, pauseMinutes: 30), 510);
    });

    test('lève ArgumentError si endTime < startTime (jour suivant non géré)', () {
      expect(() => service.calculateDuration(1020, 480), throwsArgumentError);
    });

    test('lève ArgumentError si endTime == startTime (fix M1)', () {
      expect(() => service.calculateDuration(480, 480), throwsArgumentError);
    });

    test(
      'fix M1 : endTime == startTime avec une pause lève ArgumentError '
      '(au lieu de renvoyer une durée négative)',
      () {
        expect(
          () => service.calculateDuration(480, 480, pauseMinutes: 10),
          throwsArgumentError,
        );
      },
    );

    test(
      'fix M1 : une pause strictement supérieure à la durée brute lève '
      'ArgumentError (au lieu de renvoyer une durée négative)',
      () {
        expect(
          () => service.calculateDuration(480, 540, pauseMinutes: 90),
          throwsArgumentError,
        );
      },
    );

    test('pauseMinutes exactement égal à la durée brute → durée nulle, pas une erreur', () {
      expect(service.calculateDuration(480, 540, pauseMinutes: 60), 0);
    });

    test('accepte pauseMinutes = 0 explicite', () {
      expect(service.calculateDuration(0, 60, pauseMinutes: 0), 60);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // roundDuration
  // ─────────────────────────────────────────────────────────────
  group('roundDuration', () {
    test('ne change rien si step <= 1', () {
      expect(service.roundDuration(37, 1), 37);
      expect(service.roundDuration(37, 0), 37);
    });

    test('roundUp: arrondit toujours au palier supérieur', () {
      expect(service.roundDuration(1, 15, roundUp: true), 15);
      expect(service.roundDuration(15, 15, roundUp: true), 15);
      expect(service.roundDuration(16, 15, roundUp: true), 30);
    });

    test('roundUp=false: arrondit au palier le plus proche', () {
      expect(service.roundDuration(37, 15), 30);
      expect(service.roundDuration(38, 15), 45);
    });

    test('durée nulle reste nulle', () {
      expect(service.roundDuration(0, 15, roundUp: true), 0);
      expect(service.roundDuration(0, 15), 0);
    });

    test('durée déjà pile sur le palier ne bouge pas', () {
      expect(service.roundDuration(60, 15, roundUp: true), 60);
      expect(service.roundDuration(60, 15), 60);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // calculateLaborCost
  // ─────────────────────────────────────────────────────────────
  group('calculateLaborCost — hourly', () {
    test('calcule le coût horaire avec arrondi au ¼h supérieur', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 90,
        mode: BillingMode.hourly,
        rates: DefaultRates(hour: Money.fromCents(2000)),
        roundingStep: 15,
      );
      expect(cost, Money.fromCents(3000));
    });

    test('arrondit la durée vers le haut avant de facturer', () {
      // 61 min -> arrondi à 75 min (¼h sup) -> 1.25h * 2000c = 2500c
      final cost = service.calculateLaborCost(
        durationMinutes: 61,
        mode: BillingMode.hourly,
        rates: DefaultRates(hour: Money.fromCents(2000)),
        roundingStep: 15,
      );
      expect(cost, Money.fromCents(2500));
    });

    test('renvoie zéro si aucun tarif horaire défini', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 90,
        mode: BillingMode.hourly,
        rates: const DefaultRates(),
        roundingStep: 15,
      );
      expect(cost, Money.zero);
    });

    test('renvoie zéro si le tarif horaire est explicitement zéro', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 90,
        mode: BillingMode.hourly,
        rates: DefaultRates(hour: Money.fromCents(0)),
        roundingStep: 15,
      );
      expect(cost, Money.zero);
    });
  });

  group('calculateLaborCost — half_day / day / fixed_job', () {
    test('half_day utilise le tarif forfaitaire, ignore la durée', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 5,
        mode: BillingMode.half_day,
        rates: DefaultRates(halfDay: Money.fromCents(15000)),
        roundingStep: 15,
      );
      expect(cost, Money.fromCents(15000));
    });

    test('day utilise le tarif journalier', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 480,
        mode: BillingMode.day,
        rates: DefaultRates(day: Money.fromCents(30000)),
        roundingStep: 15,
      );
      expect(cost, Money.fromCents(30000));
    });

    test('fixed_job utilise le tarif forfaitaire', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 60,
        mode: BillingMode.fixed_job,
        rates: DefaultRates(fixedJob: Money.fromCents(50000)),
        roundingStep: 15,
      );
      expect(cost, Money.fromCents(50000));
    });

    test('half_day sans tarif défini renvoie zéro', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 240,
        mode: BillingMode.half_day,
        rates: const DefaultRates(),
        roundingStep: 15,
      );
      expect(cost, Money.zero);
    });

    test('day sans tarif défini renvoie zéro', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 480,
        mode: BillingMode.day,
        rates: const DefaultRates(),
        roundingStep: 15,
      );
      expect(cost, Money.zero);
    });

    test('fixed_job sans tarif défini renvoie zéro', () {
      final cost = service.calculateLaborCost(
        durationMinutes: 60,
        mode: BillingMode.fixed_job,
        rates: const DefaultRates(),
        roundingStep: 15,
      );
      expect(cost, Money.zero);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // formatTime
  // ─────────────────────────────────────────────────────────────
  group('formatTime', () {
    test('formate 480 minutes en "08:00"', () {
      expect(service.formatTime(480), '08:00');
    });

    test('formate 0 minute en "00:00"', () {
      expect(service.formatTime(0), '00:00');
    });

    test('formate 1439 minutes (23:59) en "23:59"', () {
      expect(service.formatTime(1439), '23:59');
    });

    test('pad les heures et minutes < 10', () {
      expect(service.formatTime(65), '01:05');
    });

    test('un nombre négatif retombe sur "00:00"', () {
      expect(service.formatTime(-10), '00:00');
    });

    test(
      'BUG connu : aucune validation haute — 1500 min (>23:59) donne "25:00" '
      'au lieu d\'être rejeté ou wrappé',
      () {
        expect(service.formatTime(1500), '25:00');
      },
    );
  });

  // ─────────────────────────────────────────────────────────────
  // parseTime
  // ─────────────────────────────────────────────────────────────
  group('parseTime', () {
    test('parse "08:30" en 510 minutes', () {
      expect(service.parseTime('08:30'), 510);
    });

    test('parse "00:00" en 0', () {
      expect(service.parseTime('00:00'), 0);
    });

    test('parse "23:59" en 1439', () {
      expect(service.parseTime('23:59'), 1439);
    });

    test('renvoie 0 pour un format sans ":"', () {
      expect(service.parseTime('0830'), 0);
    });

    test('renvoie 0 pour une chaîne vide', () {
      expect(service.parseTime(''), 0);
    });

    test('renvoie 0 pour des composants non numériques', () {
      expect(service.parseTime('ab:cd'), 0);
    });

    test(
      'BUG connu : aucune validation de plage — "24:00" est accepté et '
      'renvoie 1440 au lieu d\'être rejeté',
      () {
        expect(service.parseTime('24:00'), 1440);
      },
    );

    test('round-trip formatTime/parseTime préserve la valeur', () {
      expect(service.parseTime(service.formatTime(510)), 510);
    });
  });
}
