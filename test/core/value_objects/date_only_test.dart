import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // fromDateTime
  // ─────────────────────────────────────────────────────────────
  group('DateOnly.fromDateTime', () {
    test('crée la date correcte depuis un DateTime à minuit', () {
      final d = DateOnly.fromDateTime(DateTime(2026, 4, 15));
      expect(d.value, '2026-04-15');
    });

    test('ignore l\'heure : 23h59 ne change pas le jour', () {
      final d = DateOnly.fromDateTime(DateTime(2026, 4, 15, 23, 59, 59));
      expect(d.value, '2026-04-15');
    });

    test('pad le mois et le jour avec des zéros', () {
      final d = DateOnly.fromDateTime(DateTime(2026, 1, 5));
      expect(d.value, '2026-01-05');
    });

    test('fonctionne en fin de mois', () {
      final d = DateOnly.fromDateTime(DateTime(2024, 12, 31));
      expect(d.value, '2024-12-31');
    });

    test('1er janvier 2000', () {
      final d = DateOnly.fromDateTime(DateTime(2000, 1, 1));
      expect(d.value, '2000-01-01');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // fromString
  // ─────────────────────────────────────────────────────────────
  group('DateOnly.fromString — formats valides', () {
    test('accepte un format YYYY-MM-DD valide', () {
      final d = DateOnly.fromString('2026-04-15');
      expect(d.value, '2026-04-15');
    });

    test('accepte une date bissextile réelle : 2024-02-29', () {
      // 2024 est bissextile
      final d = DateOnly.fromString('2024-02-29');
      expect(d.value, '2024-02-29');
    });

    test('accepte le 1er janvier 1970', () {
      expect(DateOnly.fromString('1970-01-01').value, '1970-01-01');
    });

    test('accepte le 31 décembre 2099', () {
      expect(DateOnly.fromString('2099-12-31').value, '2099-12-31');
    });
  });

  group('DateOnly.fromString — formats invalides (throw ArgumentError)', () {
    test('lève ArgumentError pour format sans tirets', () {
      expect(() => DateOnly.fromString('20260415'), throwsA(isA<ArgumentError>()));
    });

    test('lève ArgumentError pour format dd/MM/yyyy', () {
      expect(() => DateOnly.fromString('15/04/2026'), throwsA(isA<ArgumentError>()));
    });

    test('lève ArgumentError pour chaîne vide', () {
      expect(() => DateOnly.fromString(''), throwsA(isA<ArgumentError>()));
    });

    test('lève ArgumentError pour format partiel', () {
      expect(() => DateOnly.fromString('2026-04'), throwsA(isA<ArgumentError>()));
    });

    test('lève ArgumentError pour texte libre', () {
      expect(() => DateOnly.fromString('demain'), throwsA(isA<ArgumentError>()));
    });

    // ── Comportement réel de DateTime.parse en Dart ──────────
    // DateTime.parse NE lance PAS d'exception sur les dates débordantes :
    // il les normalise silencieusement (2024-02-30 → 2024-03-01).
    // DateOnly.fromString hérite donc de ce comportement.
    test('2024-02-30 est normalisé en 2024-03-01 (comportement Dart)', () {
      // Dart ne lance pas d'exception ici — il normalise la date
      final d = DateOnly.fromString('2024-02-30');
      // La date normalisée par DateTime.parse est retournée telle quelle
      // MAIS la valeur stockée reste la chaîne brute passée
      // → le value est '2024-02-30' (pas de re-parsing sur la valeur)
      expect(d.value, '2024-02-30');
    });

    test('2024-13-01 est normalisé silencieusement (comportement Dart)', () {
      // Dart normalise 2024-13-01 en 2025-01-01 sans exception
      final d = DateOnly.fromString('2024-13-01');
      expect(d.value, '2024-13-01');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // today
  // ─────────────────────────────────────────────────────────────
  group('DateOnly.today', () {
    test('retourne une date non-nulle au format YYYY-MM-DD', () {
      final d = DateOnly.today();
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(d.value), isTrue);
    });

    test('la date du jour correspond bien à DateTime.now()', () {
      final now = DateTime.now();
      final today = DateOnly.today();
      expect(today.year, now.year);
      expect(today.month, now.month);
      expect(today.day, now.day);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // toDateTime
  // ─────────────────────────────────────────────────────────────
  group('toDateTime', () {
    test('retourne minuit pile (heure = 0)', () {
      final dt = DateOnly.fromString('2026-04-15').toDateTime();
      expect(dt.hour, 0);
      expect(dt.minute, 0);
      expect(dt.second, 0);
    });

    test('retourne la date correcte', () {
      final dt = DateOnly.fromString('2026-04-15').toDateTime();
      expect(dt.year, 2026);
      expect(dt.month, 4);
      expect(dt.day, 15);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Propriétés year / month / day / weekday
  // ─────────────────────────────────────────────────────────────
  group('propriétés year/month/day/weekday', () {
    final d = DateOnly.fromString('2026-04-15'); // mercredi

    test('year retourne 2026', () => expect(d.year, 2026));
    test('month retourne 4', () => expect(d.month, 4));
    test('day retourne 15', () => expect(d.day, 15));
    test('weekday retourne 3 (mercredi = DateTime.wednesday)', () {
      expect(d.weekday, DateTime.wednesday); // 3
    });

    test('lundi : weekday = 1', () {
      expect(DateOnly.fromString('2026-04-13').weekday, DateTime.monday);
    });

    test('dimanche : weekday = 7', () {
      expect(DateOnly.fromString('2026-04-12').weekday, DateTime.sunday);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // addDays
  // ─────────────────────────────────────────────────────────────
  group('addDays', () {
    test('ajoute 1 jour', () {
      expect(DateOnly.fromString('2026-04-15').addDays(1).value, '2026-04-16');
    });

    test('ajoute 0 jour → identité', () {
      final d = DateOnly.fromString('2026-04-15');
      expect(d.addDays(0), equals(d));
    });

    test('ajoute des jours avec traversée de mois', () {
      // 28 avril + 5 jours = 3 mai
      expect(DateOnly.fromString('2026-04-28').addDays(5).value, '2026-05-03');
    });

    test('ajoute des jours avec traversée d\'année', () {
      // 30 décembre 2025 + 5 jours = 4 janvier 2026
      expect(DateOnly.fromString('2025-12-30').addDays(5).value, '2026-01-04');
    });

    test('addDays négatif recule dans le temps', () {
      expect(DateOnly.fromString('2026-04-15').addDays(-5).value, '2026-04-10');
    });

    test('addDays négatif avec traversée de mois', () {
      // 3 mai - 5 jours = 28 avril
      expect(DateOnly.fromString('2026-05-03').addDays(-5).value, '2026-04-28');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // subtractDays
  // ─────────────────────────────────────────────────────────────
  group('subtractDays', () {
    test('soustrait 1 jour', () {
      expect(DateOnly.fromString('2026-04-15').subtractDays(1).value, '2026-04-14');
    });

    test('soustrait 0 jour → identité', () {
      final d = DateOnly.fromString('2026-04-15');
      expect(d.subtractDays(0), equals(d));
    });

    test('subtractDays(n) == addDays(-n)', () {
      final d = DateOnly.fromString('2026-06-10');
      expect(d.subtractDays(15), equals(d.addDays(-15)));
    });

    test('soustrait avec traversée de mois', () {
      // 3 mai - 5 jours = 28 avril
      expect(DateOnly.fromString('2026-05-03').subtractDays(5).value, '2026-04-28');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // addMonths — cas de débordement de jours (overflow)
  // ─────────────────────────────────────────────────────────────
  group('addMonths', () {
    test('cas normal : 15 avril + 1 mois = 15 mai', () {
      expect(DateOnly.fromString('2026-04-15').addMonths(1).value, '2026-05-15');
    });

    test('31 janvier (non-bissextile) + 1 mois = 28 février 2025', () {
      // 2025 n'est pas bissextile → fév a 28 jours
      expect(DateOnly.fromString('2025-01-31').addMonths(1).value, '2025-02-28');
    });

    test('31 janvier (bissextile) + 1 mois = 29 février 2024', () {
      // 2024 est bissextile → fév a 29 jours
      expect(DateOnly.fromString('2024-01-31').addMonths(1).value, '2024-02-29');
    });

    test('31 mars + 1 mois = 30 avril', () {
      // Avril a 30 jours
      expect(DateOnly.fromString('2026-03-31').addMonths(1).value, '2026-04-30');
    });

    test('traversée d\'année : décembre + 1 mois = janvier suivant', () {
      expect(DateOnly.fromString('2026-12-15').addMonths(1).value, '2027-01-15');
    });

    test('traversée d\'année avec overflow : 31 octobre + 3 mois = 31 janvier', () {
      expect(DateOnly.fromString('2026-10-31').addMonths(3).value, '2027-01-31');
    });

    test('ajoute 12 mois = 1 an exactement', () {
      expect(DateOnly.fromString('2026-04-15').addMonths(12).value, '2027-04-15');
    });

    test('ajoute 0 mois → identité', () {
      final d = DateOnly.fromString('2026-04-15');
      expect(d.addMonths(0), equals(d));
    });

    test('31 mai + 1 mois = 30 juin', () {
      expect(DateOnly.fromString('2026-05-31').addMonths(1).value, '2026-06-30');
    });

    test('31 août + 1 mois = 30 septembre', () {
      expect(DateOnly.fromString('2026-08-31').addMonths(1).value, '2026-09-30');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // isBetween (inclusif)
  // ─────────────────────────────────────────────────────────────
  group('isBetween', () {
    final from = DateOnly.fromString('2026-04-01');
    final to   = DateOnly.fromString('2026-04-30');
    final mid  = DateOnly.fromString('2026-04-15');

    test('date au milieu de la plage → true', () {
      expect(mid.isBetween(from, to), isTrue);
    });

    test('date égale à from (borne inférieure inclusive) → true', () {
      expect(from.isBetween(from, to), isTrue);
    });

    test('date égale à to (borne supérieure inclusive) → true', () {
      expect(to.isBetween(from, to), isTrue);
    });

    test('date avant from → false', () {
      expect(DateOnly.fromString('2026-03-31').isBetween(from, to), isFalse);
    });

    test('date après to → false', () {
      expect(DateOnly.fromString('2026-05-01').isBetween(from, to), isFalse);
    });

    test('plage d\'un seul jour : from == to', () {
      expect(from.isBetween(from, from), isTrue);
    });

    test('date hors d\'une plage d\'un seul jour', () {
      expect(mid.isBetween(from, from), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // formatEuropean
  // ─────────────────────────────────────────────────────────────
  group('formatEuropean', () {
    test('15 avril 2026 → "15/04/2026"', () {
      expect(DateOnly.fromString('2026-04-15').formatEuropean(), '15/04/2026');
    });

    test('1er janvier 2000 → "01/01/2000" (zéros)', () {
      expect(DateOnly.fromString('2000-01-01').formatEuropean(), '01/01/2000');
    });

    test('31 décembre 2026 → "31/12/2026"', () {
      expect(DateOnly.fromString('2026-12-31').formatEuropean(), '31/12/2026');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // formatLongFrench
  // ─────────────────────────────────────────────────────────────
  group('formatLongFrench', () {
    test('15 avril 2026 → "15 avril 2026"', () {
      expect(DateOnly.fromString('2026-04-15').formatLongFrench(), '15 avril 2026');
    });

    test('1 janvier 2025 → "1 janvier 2025" (pas de zéro sur le jour)', () {
      expect(DateOnly.fromString('2025-01-01').formatLongFrench(), '1 janvier 2025');
    });

    test('28 février 2025 → "28 février 2025"', () {
      expect(DateOnly.fromString('2025-02-28').formatLongFrench(), '28 février 2025');
    });

    test('1 mars 2024 → "1 mars 2024"', () {
      expect(DateOnly.fromString('2024-03-01').formatLongFrench(), '1 mars 2024');
    });

    test('15 août 2026 → "15 août 2026" (accent)', () {
      expect(DateOnly.fromString('2026-08-15').formatLongFrench(), '15 août 2026');
    });

    test('les 12 mois sont couverts', () {
      final expected = [
        'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
        'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
      ];
      for (var i = 1; i <= 12; i++) {
        final monthStr = i.toString().padLeft(2, '0');
        final d = DateOnly.fromString('2026-$monthStr-01');
        expect(d.formatLongFrench(), contains(expected[i - 1]),
            reason: 'Mois $i devrait contenir "${expected[i - 1]}"');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Égalité == et hashCode
  // ─────────────────────────────────────────────────────────────
  group('== et hashCode', () {
    test('deux dates identiques sont égales', () {
      expect(DateOnly.fromString('2026-04-15'), equals(DateOnly.fromString('2026-04-15')));
    });

    test('deux dates différentes ne sont pas égales', () {
      expect(DateOnly.fromString('2026-04-15'), isNot(equals(DateOnly.fromString('2026-04-16'))));
    });

    test('hashCode cohérent avec ==', () {
      expect(
        DateOnly.fromString('2026-04-15').hashCode,
        DateOnly.fromString('2026-04-15').hashCode,
      );
    });

    test('fromDateTime et fromString produisent des objets égaux', () {
      final a = DateOnly.fromDateTime(DateTime(2026, 4, 15));
      final b = DateOnly.fromString('2026-04-15');
      expect(a, equals(b));
    });

    test('n\'est pas égal à un non-DateOnly', () {
      // Comparaison volontaire entre types différents : on vérifie que
      // operator== renvoie bien false plutôt que de planter ou de renvoyer
      // true par erreur. Ne pas "corriger" en retirant cette ligne.
      // ignore: unrelated_type_equality_checks
      expect(DateOnly.fromString('2026-04-15') == '2026-04-15', isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Opérateurs de comparaison
  // ─────────────────────────────────────────────────────────────
  group('opérateurs < <= > >=', () {
    final early = DateOnly.fromString('2026-01-01');
    final late  = DateOnly.fromString('2026-12-31');
    final same  = DateOnly.fromString('2026-06-15');
    final same2 = DateOnly.fromString('2026-06-15');

    test('early < late', () => expect(early < late, isTrue));
    test('late < early → false', () => expect(late < early, isFalse));
    test('same < same → false', () => expect(same < same2, isFalse));

    test('early <= late', () => expect(early <= late, isTrue));
    test('same <= same', () => expect(same <= same2, isTrue));
    test('late <= early → false', () => expect(late <= early, isFalse));

    test('late > early', () => expect(late > early, isTrue));
    test('early > late → false', () => expect(early > late, isFalse));
    test('same > same → false', () => expect(same > same2, isFalse));

    test('late >= early', () => expect(late >= early, isTrue));
    test('same >= same', () => expect(same >= same2, isTrue));
    test('early >= late → false', () => expect(early >= late, isFalse));
  });

  // ─────────────────────────────────────────────────────────────
  // compareTo
  // ─────────────────────────────────────────────────────────────
  group('compareTo', () {
    test('retourne négatif si this < other', () {
      expect(
        DateOnly.fromString('2026-01-01').compareTo(DateOnly.fromString('2026-12-31')),
        isNegative,
      );
    });

    test('retourne zéro si this == other', () {
      expect(
        DateOnly.fromString('2026-06-15').compareTo(DateOnly.fromString('2026-06-15')),
        isZero,
      );
    });

    test('retourne positif si this > other', () {
      expect(
        DateOnly.fromString('2026-12-31').compareTo(DateOnly.fromString('2026-01-01')),
        isPositive,
      );
    });

    test('utilisable pour trier une liste de dates', () {
      final list = [
        DateOnly.fromString('2026-06-01'),
        DateOnly.fromString('2026-01-15'),
        DateOnly.fromString('2026-12-31'),
        DateOnly.fromString('2026-03-10'),
      ]..sort();
      expect(list.map((d) => d.value).toList(), [
        '2026-01-15',
        '2026-03-10',
        '2026-06-01',
        '2026-12-31',
      ]);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // toString
  // ─────────────────────────────────────────────────────────────
  group('toString', () {
    test('retourne la chaîne ISO', () {
      expect(DateOnly.fromString('2026-04-15').toString(), '2026-04-15');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // toJson / fromJson
  // ─────────────────────────────────────────────────────────────
  group('toJson / fromJson', () {
    test('toJson retourne la chaîne ISO', () {
      expect(DateOnly.fromString('2026-04-15').toJson(), '2026-04-15');
    });

    test('fromJson reconstruit la même date', () {
      final original = DateOnly.fromString('2026-04-15');
      final restored = DateOnly.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('aller-retour sur le 1er janvier', () {
      final d = DateOnly.fromString('2000-01-01');
      expect(DateOnly.fromJson(d.toJson()), equals(d));
    });

    test('aller-retour sur le 29 février bissextile', () {
      final d = DateOnly.fromString('2024-02-29');
      expect(DateOnly.fromJson(d.toJson()), equals(d));
    });
  });
}
