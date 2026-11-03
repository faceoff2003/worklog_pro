import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';

Map<String, dynamic> _json([Map<String, dynamic> extra = const {}]) => {
      'id': 's1',
      'clientId': 'c1',
      'date': '2026-11-03',
      'balanceAtSettlement': 1500,
      'note': null,
      'createdAt': '2026-11-03T10:00:00.000',
      ...extra,
    };

void main() {
  group('ClientSettlement.carriedOverAmount', () {
    test('champ absent (documents existants) : 0', () {
      expect(ClientSettlement.fromJson(_json()).carriedOverAmount, Money.zero);
    });

    test('null explicite : 0', () {
      expect(ClientSettlement.fromJson(_json({'carriedOverAmount': null})).carriedOverAmount, Money.zero);
    });

    test('positif et négatif lus au centime', () {
      expect(ClientSettlement.fromJson(_json({'carriedOverAmount': 1234})).carriedOverAmount.amountCents, 1234);
      expect(ClientSettlement.fromJson(_json({'carriedOverAmount': -500})).carriedOverAmount.amountCents, -500);
    });

    test('écrit comme un int, aller-retour identique', () {
      final s = ClientSettlement.fromJson(_json({'carriedOverAmount': -500}));
      expect(s.toJson()['carriedOverAmount'], -500);
      expect(ClientSettlement.fromJson(s.toJson()), s);
    });

    test('non renseigné à la création : écrit 0', () {
      final s = ClientSettlement(
        id: 's1',
        clientId: 'c1',
        date: DateOnly.fromJson('2026-11-03'),
        balanceAtSettlement: Money.fromCents(1500),
        createdAt: DateTime(2026, 11, 3, 10),
      );
      expect(s.toJson()['carriedOverAmount'], 0);
    });
  });
}
