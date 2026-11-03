import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/clients/presentation/pages/account_statement_page.dart';
import 'package:worklog_pro/features/clients/presentation/providers/account_statement_provider.dart';

StatementLine _line(StatementLineType type, String id, String date, int cents, int running,
        {bool archived = false, WorkEntryPaymentStatus? status, String? description}) =>
    StatementLine(
      type: type,
      id: id,
      date: DateOnly.fromString(date),
      amount: Money.fromCents(cents),
      runningBalance: Money.fromCents(running),
      isArchived: archived,
      status: status,
      description: description,
    );

Future<void> _pump(WidgetTester tester, AsyncValue<AccountStatement> value) => tester.pumpWidget(ProviderScope(
      overrides: [accountStatementProvider('c1').overrideWithValue(value)],
      child: const MaterialApp(home: AccountStatementPage(clientId: 'c1', clientName: 'Dupont')),
    ));

AccountStatement _statement(List<StatementLine> lines, {int work = 0, int payments = 0}) => AccountStatement(
      lines: lines,
      totalWork: Money.fromCents(work),
      totalExpenses: Money.zero,
      totalPayments: Money.fromCents(payments),
    );

void main() {
  testWidgets('chargement, erreur, relevé vide', (tester) async {
    await _pump(tester, const AsyncValue.loading());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _pump(tester, const AsyncValue.error('boom', StackTrace.empty));
    await tester.pump();
    expect(find.text('Erreur: boom'), findsOneWidget);

    await _pump(tester, AsyncValue.data(_statement(const [])));
    await tester.pump();
    expect(find.text('Aucune opération'), findsOneWidget);
  });

  testWidgets('lignes, solde courant, séparateur JJ/MM, archives grisées, badges', (tester) async {
    await _pump(
      tester,
      AsyncValue.data(_statement(
        [
          _line(StatementLineType.workEntry, 'old', '2026-03-01', 10000, 10000,
              archived: true,
              status: const WorkEntryPaymentStatus(WorkEntryPaymentState.settled, Money.zero),
              description: 'Tableau'),
          _line(StatementLineType.settlement, 's1', '2026-03-05', 10000, 0, archived: true),
          _line(StatementLineType.workEntry, 'new', '2026-03-06', 700, 700,
              status: WorkEntryPaymentStatus(WorkEntryPaymentState.partial, Money.fromCents(500))),
          _line(StatementLineType.expense, 'exp', '2026-03-06', 100, 800),
          _line(StatementLineType.payment, 'pay', '2026-03-07', -200, 600),
        ],
        work: 800,
        payments: 200,
      )),
    );

    expect(find.text('── COMPTE SOLDÉ le 05/03 ──'), findsOneWidget);
    expect(find.text('Solde archivé : 100,00 €'), findsOneWidget);
    expect(find.text('01/03/2026 · Prestation'), findsOneWidget);
    expect(find.text('Tableau'), findsOneWidget);
    expect(find.text('06/03/2026 · Dépense'), findsOneWidget);
    expect(find.text('07/03/2026 · Paiement'), findsOneWidget);
    expect(find.text('-2,00 €'), findsOneWidget);
    expect(find.text('Solde : 6,00 €'), findsOneWidget);
    expect(find.text('Soldée'), findsOneWidget);
    expect(find.text('Partielle (reste 5,00 €)'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('statement_balance'))).data, '6,00 €');
    expect(find.text('Solde actuel'), findsOneWidget);

    Opacity opacityOf(String id) => tester.widget<Opacity>(find.byKey(ValueKey('statement_line_$id')));
    expect(opacityOf('old').opacity, lessThan(1));
    expect(opacityOf('new').opacity, 1);
  });

  testWidgets('mention "saisie le JJ/MM" seulement sur la ligne saisie en retard', (tester) async {
    await _pump(
      tester,
      AsyncValue.data(_statement([
        _line(StatementLineType.settlement, 's1', '2026-03-05', 0, 0, archived: true),
        StatementLine(
          type: StatementLineType.workEntry,
          id: 'late',
          date: DateOnly.fromString('2026-03-01'),
          amount: Money.fromCents(700),
          runningBalance: Money.fromCents(700),
          isArchived: false,
          enteredOn: DateOnly.fromString('2026-03-09'),
        ),
        _line(StatementLineType.workEntry, 'normal', '2026-03-06', 100, 800),
      ], work: 800)),
    );
    expect(find.text('saisie le 09/03'), findsOneWidget);
    expect(find.textContaining('saisie le'), findsOneWidget);
    expect(
      find.descendant(of: find.byKey(const ValueKey('statement_line_late')), matching: find.text('saisie le 09/03')),
      findsOneWidget,
    );
  });

  testWidgets('solde négatif affiché comme une avance', (tester) async {
    await _pump(
      tester,
      AsyncValue.data(_statement([_line(StatementLineType.payment, 'p', '2026-03-07', -500, -500)], payments: 500)),
    );
    expect(find.text('Avance du client'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const ValueKey('statement_balance'))).data, '-5,00 €');
  });

  testWidgets('report : « Reporté : X € » au séparateur, ligne « Report à nouveau »', (tester) async {
    await _pump(
      tester,
      AsyncValue.data(_statement(
        [
          StatementLine(
            type: StatementLineType.settlement,
            id: 's1',
            date: DateOnly.fromString('2026-03-05'),
            amount: Money.fromCents(1500),
            runningBalance: Money.zero,
            isArchived: true,
            carriedOver: Money.fromCents(1500),
          ),
          _line(StatementLineType.carryOver, 's1', '2026-03-05', 1500, 1500),
          _line(StatementLineType.workEntry, 'w', '2026-03-06', 700, 2200),
        ],
        work: 700,
      )),
    );

    expect(find.text('Reporté : 15,00 €'), findsOneWidget);
    expect(find.text('05/03/2026 · Report à nouveau'), findsOneWidget);
    expect(find.byKey(const ValueKey('statement_carry_s1')), findsOneWidget);
    expect(find.text('Solde : 22,00 €'), findsOneWidget);
  });

  testWidgets('sans report : pas de mention « Reporté »', (tester) async {
    await _pump(
      tester,
      AsyncValue.data(_statement([_line(StatementLineType.settlement, 's1', '2026-03-05', 0, 0, archived: true)])),
    );
    expect(find.textContaining('Reporté'), findsNothing);
  });
}
