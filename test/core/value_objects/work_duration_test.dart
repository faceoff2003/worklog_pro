import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/work_duration.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // WorkDuration.fromMinutes
  // ─────────────────────────────────────────────────────────────
  group('WorkDuration.fromMinutes', () {
    test('stocke exactement les minutes', () {
      expect(WorkDuration.fromMinutes(90).minutes, 90);
    });

    test('accepte zéro', () {
      expect(WorkDuration.fromMinutes(0).minutes, 0);
    });

    test('rejette une valeur négative', () {
      expect(() => WorkDuration.fromMinutes(-1), throwsArgumentError);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // WorkDuration.fromHours
  // ─────────────────────────────────────────────────────────────
  group('WorkDuration.fromHours', () {
    test('convertit 1.5h en 90 minutes', () {
      expect(WorkDuration.fromHours(1.5).minutes, 90);
    });

    test('convertit 8h en 480 minutes', () {
      expect(WorkDuration.fromHours(8.0).minutes, 480);
    });

    test('arrondit à la minute la plus proche', () {
      expect(WorkDuration.fromHours(1.008).minutes, 60);
    });

    test('accepte zéro heure', () {
      expect(WorkDuration.fromHours(0.0).minutes, 0);
    });

    test('rejette une valeur négative', () {
      expect(() => WorkDuration.fromHours(-1.0), throwsArgumentError);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // WorkDuration.fromTimeRange
  // ─────────────────────────────────────────────────────────────
  group('WorkDuration.fromTimeRange', () {
    test('calcule 8h30 pour 08:00-17:00 avec 30min de pause', () {
      final d = WorkDuration.fromTimeRange(
        startTime: 480,
        endTime: 1020,
        pauseMinutes: 30,
      );
      expect(d.minutes, 510);
    });

    test('fonctionne sans pause', () {
      final d = WorkDuration.fromTimeRange(
        startTime: 0,
        endTime: 60,
        pauseMinutes: 0,
      );
      expect(d.minutes, 60);
    });

    test('accepte une pause égale à la durée totale (résultat zéro)', () {
      final d = WorkDuration.fromTimeRange(
        startTime: 480,
        endTime: 540,
        pauseMinutes: 60,
      );
      expect(d.minutes, 0);
    });

    test('accepte startTime = 0 (minuit)', () {
      final d = WorkDuration.fromTimeRange(
        startTime: 0,
        endTime: 30,
        pauseMinutes: 0,
      );
      expect(d.minutes, 30);
    });

    test('accepte endTime = 1439 (23:59)', () {
      final d = WorkDuration.fromTimeRange(
        startTime: 1400,
        endTime: 1439,
        pauseMinutes: 0,
      );
      expect(d.minutes, 39);
    });

    test('rejette startTime négatif', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: -1, endTime: 60, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette startTime > 1439', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 1440, endTime: 1441, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette endTime négatif', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 0, endTime: -1, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette endTime > 1439', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 0, endTime: 1440, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette endTime == startTime', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 480, endTime: 480, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette endTime < startTime', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 600, endTime: 480, pauseMinutes: 0),
        throwsArgumentError,
      );
    });

    test('rejette une pause négative', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 0, endTime: 60, pauseMinutes: -1),
        throwsArgumentError,
      );
    });

    test('rejette une pause supérieure à la durée totale', () {
      expect(
        () => WorkDuration.fromTimeRange(startTime: 0, endTime: 60, pauseMinutes: 61),
        throwsArgumentError,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────
  // WorkDuration.zero
  // ─────────────────────────────────────────────────────────────
  group('WorkDuration.zero', () {
    test('vaut exactement 0 minute', () {
      expect(WorkDuration.zero.minutes, 0);
    });

    test('est égal à fromMinutes(0)', () {
      expect(WorkDuration.zero, equals(WorkDuration.fromMinutes(0)));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // inHours
  // ─────────────────────────────────────────────────────────────
  group('inHours', () {
    test('90 minutes = 1.5h', () {
      expect(WorkDuration.fromMinutes(90).inHours, 1.5);
    });

    test('0 minute = 0h', () {
      expect(WorkDuration.fromMinutes(0).inHours, 0.0);
    });

    test('45 minutes = 0.75h', () {
      expect(WorkDuration.fromMinutes(45).inHours, 0.75);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // round
  // ─────────────────────────────────────────────────────────────
  group('round', () {
    test('arrondit 37 minutes au ¼h le plus proche (15 → 30)', () {
      expect(WorkDuration.fromMinutes(37).round(15).minutes, 30);
    });

    test('arrondit 38 minutes au ¼h le plus proche (15 → 45)', () {
      expect(WorkDuration.fromMinutes(38).round(15).minutes, 45);
    });

    test('ne change rien si roundingMinutes = 0', () {
      expect(WorkDuration.fromMinutes(37).round(0).minutes, 37);
    });

    test('ne change rien si roundingMinutes négatif', () {
      expect(WorkDuration.fromMinutes(37).round(-5).minutes, 37);
    });

    test('arrondit exactement sur la limite (7.5 → 10 pour step 10, arrondi banquier Dart)', () {
      // (7.5).round() en Dart arrondit à 8 (half-up), donc 7 -> round(10)=10
      expect(WorkDuration.fromMinutes(7).round(10).minutes, 10);
    });

    test('zéro reste zéro', () {
      expect(WorkDuration.zero.round(15).minutes, 0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // format / formatHoursOnly
  // ─────────────────────────────────────────────────────────────
  group('format', () {
    test('formate 465 minutes en "7h 45min"', () {
      expect(WorkDuration.fromMinutes(465).format(), '7h 45min');
    });

    test('pad les minutes < 10 (480 -> "8h 00min")', () {
      expect(WorkDuration.fromMinutes(480).format(), '8h 00min');
    });

    test('formate zéro en "0h 00min"', () {
      expect(WorkDuration.zero.format(), '0h 00min');
    });

    test('formate une durée > 24h', () {
      expect(WorkDuration.fromMinutes(1500).format(), '25h 00min');
    });
  });

  group('formatHoursOnly', () {
    test('formate 90 minutes en "1.50h"', () {
      expect(WorkDuration.fromMinutes(90).formatHoursOnly(), '1.50h');
    });

    test('formate zéro en "0.00h"', () {
      expect(WorkDuration.zero.formatHoursOnly(), '0.00h');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Opérateurs arithmétiques
  // ─────────────────────────────────────────────────────────────
  group('operator +', () {
    test('additionne deux durées', () {
      final r = WorkDuration.fromMinutes(30) + WorkDuration.fromMinutes(45);
      expect(r.minutes, 75);
    });

    test('additionner zéro ne change rien', () {
      final r = WorkDuration.fromMinutes(30) + WorkDuration.zero;
      expect(r.minutes, 30);
    });
  });

  group('operator -', () {
    test('soustrait deux durées', () {
      final r = WorkDuration.fromMinutes(45) - WorkDuration.fromMinutes(30);
      expect(r.minutes, 15);
    });

    test('résultat exactement zéro est autorisé', () {
      final r = WorkDuration.fromMinutes(30) - WorkDuration.fromMinutes(30);
      expect(r.minutes, 0);
    });

    test('rejette un résultat négatif', () {
      expect(
        () => WorkDuration.fromMinutes(10) - WorkDuration.fromMinutes(20),
        throwsArgumentError,
      );
    });
  });

  group('operator *', () {
    test('multiplie par un facteur entier', () {
      expect((WorkDuration.fromMinutes(30) * 2).minutes, 60);
    });

    test('multiplie par un facteur décimal et arrondit', () {
      expect((WorkDuration.fromMinutes(10) * 1.5).minutes, 15);
    });

    test('multiplie par zéro donne zéro', () {
      expect((WorkDuration.fromMinutes(30) * 0).minutes, 0);
    });

    test('rejette un facteur négatif', () {
      expect(() => WorkDuration.fromMinutes(30) * -1, throwsArgumentError);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Égalité, hashCode, comparaisons
  // ─────────────────────────────────────────────────────────────
  group('operator ==', () {
    test('deux durées avec les mêmes minutes sont égales', () {
      expect(WorkDuration.fromMinutes(90), equals(WorkDuration.fromMinutes(90)));
    });

    test('deux durées différentes ne sont pas égales', () {
      expect(WorkDuration.fromMinutes(90), isNot(equals(WorkDuration.fromMinutes(91))));
    });

    test('même hashCode pour des valeurs égales', () {
      expect(WorkDuration.fromMinutes(90).hashCode, WorkDuration.fromMinutes(90).hashCode);
    });
  });

  group('comparaisons (< <= > >= compareTo)', () {
    test('< renvoie vrai si strictement inférieur', () {
      expect(WorkDuration.fromMinutes(10) < WorkDuration.fromMinutes(20), isTrue);
    });

    test('<= renvoie vrai si égal', () {
      expect(WorkDuration.fromMinutes(10) <= WorkDuration.fromMinutes(10), isTrue);
    });

    test('> renvoie vrai si strictement supérieur', () {
      expect(WorkDuration.fromMinutes(20) > WorkDuration.fromMinutes(10), isTrue);
    });

    test('>= renvoie vrai si égal', () {
      expect(WorkDuration.fromMinutes(10) >= WorkDuration.fromMinutes(10), isTrue);
    });

    test('compareTo trie correctement une liste', () {
      final list = [
        WorkDuration.fromMinutes(30),
        WorkDuration.fromMinutes(10),
        WorkDuration.fromMinutes(20),
      ]..sort();
      expect(list.map((d) => d.minutes).toList(), [10, 20, 30]);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // toString / JSON
  // ─────────────────────────────────────────────────────────────
  group('toString', () {
    test('délègue à format()', () {
      expect(WorkDuration.fromMinutes(465).toString(), '7h 45min');
    });
  });

  group('JSON', () {
    test('toJson renvoie les minutes brutes', () {
      expect(WorkDuration.fromMinutes(123).toJson(), 123);
    });

    test('fromJson reconstruit la durée exacte', () {
      expect(WorkDuration.fromJson(123).minutes, 123);
    });

    test('round-trip toJson/fromJson préserve la valeur', () {
      final original = WorkDuration.fromMinutes(275);
      final restored = WorkDuration.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });
}
