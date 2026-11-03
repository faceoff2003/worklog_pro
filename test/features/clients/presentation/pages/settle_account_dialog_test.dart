import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/repositories/settlement_repository.dart';
import 'package:worklog_pro/features/clients/presentation/pages/settle_account_dialog.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';

class _FakeRepo implements SettlementRepository {
  final created = <ClientSettlement>[];

  @override
  Future<void> createSettlement(ClientSettlement settlement) async => created.add(settlement);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ClientBalance _balance({int work = 0, int payments = 0, int carried = 0}) => ClientBalance(
      carriedOver: Money.fromCents(carried),
      totalWork: Money.fromCents(work),
      totalExpenses: Money.zero,
      totalPayments: Money.fromCents(payments),
    );

Future<_FakeRepo> _open(WidgetTester tester, ClientBalance balance) async {
  final repo = _FakeRepo();
  await tester.pumpWidget(ProviderScope(
    overrides: [settlementRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      home: Scaffold(
        body: Consumer(
          builder: (context, ref, _) => TextButton(
            onPressed: () => showSettleAccountDialog(
              context: context,
              ref: ref,
              clientId: 'c1',
              clientName: 'Dupont',
              balance: balance,
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return repo;
}

bool _confirmEnabled(WidgetTester tester) =>
    tester.widget<ButtonStyleButton>(find.byKey(const ValueKey('settle_confirm'))).onPressed != null;

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('solde dû : deux choix, aucun présélectionné, bouton inactif', (tester) async {
    await _open(tester, _balance(work: 2000, payments: 500));

    expect(find.text('Solder à zéro'), findsOneWidget);
    expect(find.text('Solder avec report de 15,00 €'), findsOneWidget);
    final radios = tester.widgetList<RadioGroup<bool>>(find.byType(RadioGroup<bool>));
    expect(radios.single.groupValue, isNull);
    expect(_confirmEnabled(tester), isFalse);
    expect(find.textContaining('Choisissez ce que devient le reste.'), findsOneWidget);
  });

  testWidgets('solder à zéro : report 0, solde archivé exact', (tester) async {
    final repo = await _open(tester, _balance(work: 2000, payments: 500));

    await _tap(tester, find.byKey(const ValueKey('settle_choice_zero')));
    expect(_confirmEnabled(tester), isTrue);
    expect(find.textContaining('la balance repart de 0€.'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('settle_confirm')));

    final s = repo.created.single;
    expect(s.balanceAtSettlement.amountCents, 1500);
    expect(s.carriedOverAmount, Money.zero);
    expect(find.text('Compte de Dupont soldé. Balance remise à 0€.'), findsOneWidget);
  });

  testWidgets('solder avec report : X = le solde exact', (tester) async {
    final repo = await _open(tester, _balance(work: 2000, payments: 500));

    await _tap(tester, find.byKey(const ValueKey('settle_choice_carry')));
    expect(find.textContaining('la balance repart de 15,00 €.'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('settle_confirm')));

    final s = repo.created.single;
    expect(s.balanceAtSettlement.amountCents, 1500);
    expect(s.carriedOverAmount.amountCents, 1500);
    expect(find.text('Compte de Dupont soldé. Report de 15,00 € sur la période suivante.'), findsOneWidget);
  });

  testWidgets("avance : « report de l'avance de X € », report négatif", (tester) async {
    final repo = await _open(tester, _balance(work: 300, payments: 1500));

    expect(find.text("Solder avec report de l'avance de 12,00 €"), findsOneWidget);
    expect(find.text("L'avance est abandonnée."), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('settle_choice_carry')));
    await _tap(tester, find.byKey(const ValueKey('settle_confirm')));

    expect(repo.created.single.carriedOverAmount.amountCents, -1200);
  });

  testWidgets('solde nul : pas de choix, bouton actif, report 0', (tester) async {
    final repo = await _open(tester, _balance(work: 500, payments: 500));

    expect(find.byType(RadioGroup<bool>), findsNothing);
    expect(_confirmEnabled(tester), isTrue);
    expect(find.textContaining('la balance repart de 0€.'), findsOneWidget);
    await _tap(tester, find.byKey(const ValueKey('settle_confirm')));

    expect(repo.created.single.carriedOverAmount, Money.zero);
  });

  testWidgets('report précédent affiché et compris dans le reste à solder', (tester) async {
    await _open(tester, _balance(work: 1000, carried: 700));

    expect(find.text('Report du solde précédent'), findsOneWidget);
    expect(find.text('7,00 €'), findsOneWidget);
    expect(find.text('Solder avec report de 17,00 €'), findsOneWidget);
  });
}
