import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/money.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // Constructeurs
  // ─────────────────────────────────────────────────────────────
  group('Money.fromCents', () {
    test('stocke exactement le montant en centimes', () {
      expect(Money.fromCents(1500).amountCents, 1500);
    });

    test('accepte zéro', () {
      expect(Money.fromCents(0).amountCents, 0);
    });

    test('accepte un montant négatif', () {
      expect(Money.fromCents(-500).amountCents, -500);
    });

    test('accepte un grand montant', () {
      expect(Money.fromCents(99999999).amountCents, 99999999);
    });
  });

  group('Money.fromEuros', () {
    test('convertit 25.50 € en 2550 centimes', () {
      expect(Money.fromEuros(25.50).amountCents, 2550);
    });

    test('convertit 1.0 € en 100 centimes', () {
      expect(Money.fromEuros(1.0).amountCents, 100);
    });

    test('arrondit au centime le plus proche (0.995 → 100)', () {
      expect(Money.fromEuros(0.995).amountCents, 100);
    });

    test('arrondit au centime le plus proche (0.994 → 99)', () {
      expect(Money.fromEuros(0.994).amountCents, 99);
    });

    test('accepte zéro euro', () {
      expect(Money.fromEuros(0.0).amountCents, 0);
    });

    test('accepte un montant négatif', () {
      expect(Money.fromEuros(-10.0).amountCents, -1000);
    });
  });

  group('Money.zero', () {
    test('vaut exactement 0 centime', () {
      expect(Money.zero.amountCents, 0);
    });

    test('est égal à fromCents(0)', () {
      expect(Money.zero, equals(Money.fromCents(0)));
    });
  });

  group('Money.fromJson', () {
    test('désérialise depuis un int', () {
      expect(Money.fromJson(2550).amountCents, 2550);
    });

    test('désérialise zéro', () {
      expect(Money.fromJson(0).amountCents, 0);
    });

    test('désérialise un montant négatif', () {
      expect(Money.fromJson(-300).amountCents, -300);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Sérialisation
  // ─────────────────────────────────────────────────────────────
  group('toJson', () {
    test('retourne le montant en centimes (int)', () {
      expect(Money.fromCents(1234).toJson(), 1234);
    });

    test('toJson / fromJson est un aller-retour parfait', () {
      final original = Money.fromCents(5678);
      final restored = Money.fromJson(original.toJson());
      expect(restored, equals(original));
    });

    test('aller-retour sur zéro', () {
      final restored = Money.fromJson(Money.zero.toJson());
      expect(restored, equals(Money.zero));
    });

    test('aller-retour sur montant négatif', () {
      final original = Money.fromCents(-999);
      expect(Money.fromJson(original.toJson()), equals(original));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Conversion inEuros
  // ─────────────────────────────────────────────────────────────
  group('inEuros', () {
    test('2550 centimes = 25.5 euros', () {
      expect(Money.fromCents(2550).inEuros, 25.5);
    });

    test('0 centime = 0.0 euros', () {
      expect(Money.fromCents(0).inEuros, 0.0);
    });

    test('1 centime = 0.01 euros', () {
      expect(Money.fromCents(1).inEuros, closeTo(0.01, 1e-10));
    });

    test('montant négatif : -100 centimes = -1.0 euros', () {
      expect(Money.fromCents(-100).inEuros, -1.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Formatage toEurosString
  // ─────────────────────────────────────────────────────────────
  group('toEurosString', () {
    test('formate 0 en "0,00 €"', () {
      expect(Money.zero.toEurosString(), '0,00 €');
    });

    test('formate 100 centimes en "1,00 €"', () {
      expect(Money.fromCents(100).toEurosString(), '1,00 €');
    });

    test('formate 2550 centimes en "25,50 €"', () {
      expect(Money.fromCents(2550).toEurosString(), '25,50 €');
    });

    test('formate 125000 centimes en "1 250,00 €" (séparateur milliers)', () {
      expect(Money.fromCents(125000).toEurosString(), '1 250,00 €');
    });

    test('formate 1234567 centimes en "12 345,67 €"', () {
      expect(Money.fromCents(1234567).toEurosString(), '12 345,67 €');
    });

    test('formate un montant négatif avec signe "-"', () {
      expect(Money.fromCents(-500).toEurosString(), '-5,00 €');
    });

    test('formate 5 centimes en "0,05 €" (padding deux chiffres)', () {
      expect(Money.fromCents(5).toEurosString(), '0,05 €');
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Opérateurs arithmétiques
  // ─────────────────────────────────────────────────────────────
  group('opérateur +', () {
    test('additionne deux montants positifs', () {
      expect(Money.fromCents(1000) + Money.fromCents(500), Money.fromCents(1500));
    });

    test('additionne zéro → identité', () {
      final m = Money.fromCents(800);
      expect(m + Money.zero, m);
    });

    test('additionne un montant négatif (soustraction nette)', () {
      expect(Money.fromCents(1000) + Money.fromCents(-300), Money.fromCents(700));
    });

    test('additionne deux négatifs', () {
      expect(Money.fromCents(-200) + Money.fromCents(-300), Money.fromCents(-500));
    });
  });

  group('opérateur -', () {
    test('soustrait deux montants', () {
      expect(Money.fromCents(1000) - Money.fromCents(400), Money.fromCents(600));
    });

    test('soustrait pour obtenir zéro', () {
      final m = Money.fromCents(500);
      expect(m - m, Money.zero);
    });

    test('soustrait pour obtenir un négatif', () {
      expect(Money.fromCents(200) - Money.fromCents(500), Money.fromCents(-300));
    });

    test('soustraire zéro → identité', () {
      final m = Money.fromCents(750);
      expect(m - Money.zero, m);
    });
  });

  group('opérateur * (factor)', () {
    test('multiplie par 2 (entier)', () {
      expect(Money.fromCents(1000) * 2, Money.fromCents(2000));
    });

    test('multiplie par 1.5 (double)', () {
      expect(Money.fromCents(1000) * 1.5, Money.fromCents(1500));
    });

    test('multiplie par 0 → zéro', () {
      expect(Money.fromCents(9999) * 0, Money.zero);
    });

    test('multiplie par 1 → identité', () {
      final m = Money.fromCents(450);
      expect(m * 1, m);
    });

    test('arrondit au centime le plus proche (ex: 1 centime * 1.5 → 2)', () {
      expect(Money.fromCents(1) * 1.5, Money.fromCents(2));
    });

    test('multiplie un montant négatif', () {
      expect(Money.fromCents(-500) * 2, Money.fromCents(-1000));
    });

    test('multiplie par un taux TVA (1.21)', () {
      // 100.00 € * 1.21 = 121.00 €
      expect(Money.fromCents(10000) * 1.21, Money.fromCents(12100));
    });
  });

  group('opérateur / (divisor)', () {
    test('divise en deux parts égales', () {
      expect(Money.fromCents(1000) / 2, Money.fromCents(500));
    });

    test('divise et arrondit au centime le plus proche', () {
      // 100 centimes / 3 = 33.333... → 33
      expect(Money.fromCents(100) / 3, Money.fromCents(33));
    });

    test('divise par 1 → identité', () {
      final m = Money.fromCents(999);
      expect(m / 1, m);
    });

    test('divise un montant négatif', () {
      expect(Money.fromCents(-600) / 3, Money.fromCents(-200));
    });

    test('lève ArgumentError si diviseur = 0 (int)', () {
      expect(() => Money.fromCents(100) / 0, throwsA(isA<ArgumentError>()));
    });

    test('lève ArgumentError si diviseur = 0.0 (double)', () {
      expect(() => Money.fromCents(100) / 0.0, throwsA(isA<ArgumentError>()));
    });
  });

  group('opérateur unaire - (négation)', () {
    test('inverse le signe d\'un montant positif', () {
      expect(-Money.fromCents(500), Money.fromCents(-500));
    });

    test('inverse le signe d\'un montant négatif', () {
      expect(-Money.fromCents(-300), Money.fromCents(300));
    });

    test('nul reste nul', () {
      expect(-Money.zero, Money.zero);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Comparaisons
  // ─────────────────────────────────────────────────────────────
  group('opérateur ==', () {
    test('deux fromCents identiques sont égaux', () {
      expect(Money.fromCents(500), equals(Money.fromCents(500)));
    });

    test('deux valeurs différentes ne sont pas égales', () {
      expect(Money.fromCents(100), isNot(equals(Money.fromCents(101))));
    });

    test('zero == fromCents(0)', () {
      expect(Money.zero, equals(Money.fromCents(0)));
    });

    test('hashCode cohérent avec ==', () {
      expect(Money.fromCents(777).hashCode, Money.fromCents(777).hashCode);
    });

    test('pas égal à un non-Money', () {
      // Comparaison volontaire entre types différents : on vérifie que
      // operator== renvoie bien false plutôt que de planter ou de renvoyer
      // true par erreur. Ne pas "corriger" en retirant cette ligne.
      // ignore: unrelated_type_equality_checks
      expect(Money.fromCents(100) == 100, isFalse);
    });
  });

  group('opérateurs de comparaison (< <= > >=)', () {
    final small = Money.fromCents(100);
    final large = Money.fromCents(500);

    test('small < large', () => expect(small < large, isTrue));
    test('large < small → false', () => expect(large < small, isFalse));
    test('small <= small', () => expect(small <= small, isTrue));
    test('small <= large', () => expect(small <= large, isTrue));
    test('large > small', () => expect(large > small, isTrue));
    test('small > large → false', () => expect(small > large, isFalse));
    test('large >= large', () => expect(large >= large, isTrue));
    test('large >= small', () => expect(large >= small, isTrue));
  });

  group('compareTo', () {
    test('retourne négatif si this < other', () {
      expect(Money.fromCents(100).compareTo(Money.fromCents(200)), isNegative);
    });

    test('retourne zéro si this == other', () {
      expect(Money.fromCents(300).compareTo(Money.fromCents(300)), isZero);
    });

    test('retourne positif si this > other', () {
      expect(Money.fromCents(500).compareTo(Money.fromCents(100)), isPositive);
    });

    test('utilisable pour trier une liste', () {
      final list = [
        Money.fromCents(300),
        Money.fromCents(100),
        Money.fromCents(200),
      ]..sort();
      expect(list.map((m) => m.amountCents).toList(), [100, 200, 300]);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // toString
  // ─────────────────────────────────────────────────────────────
  group('toString', () {
    test('délègue à toEurosString', () {
      final m = Money.fromCents(2550);
      expect(m.toString(), m.toEurosString());
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Edge cases métier
  // ─────────────────────────────────────────────────────────────
  group('edge cases métier', () {
    test('0.1 + 0.2 en euros ne produit pas d\'erreur de virgule flottante', () {
      final a = Money.fromEuros(0.1);
      final b = Money.fromEuros(0.2);
      // En Float natif : 0.1 + 0.2 = 0.30000000000000004 → FAUX
      // En Money (centimes) : 10 + 20 = 30 centimes → CORRECT
      expect((a + b).amountCents, 30);
    });

    test('grand montant : 999 999.99 € reste exact', () {
      final m = Money.fromCents(99999999);
      expect(m.amountCents, 99999999);
      expect(m.inEuros, 999999.99);
    });

    test('chaînage d\'opérations reste cohérent', () {
      // (1000 + 500) * 2 - 300 = 2700
      final result = (Money.fromCents(1000) + Money.fromCents(500)) * 2 - Money.fromCents(300);
      expect(result.amountCents, 2700);
    });

    test('calcul TVA belge 21%', () {
      // 100.00 € HT * 1.21 = 121.00 € TTC
      final ht = Money.fromCents(10000);
      final ttc = ht * 1.21;
      expect(ttc.amountCents, 12100);
    });

    test('déduction partielle de paiement', () {
      final totalDu = Money.fromCents(5000);   // 50.00 €
      final acompte = Money.fromCents(2000);   // 20.00 €
      final reste = totalDu - acompte;
      expect(reste.amountCents, 3000);         // 30.00 €
    });
  });
}
