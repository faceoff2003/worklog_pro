// F-RELEVE.2 — caractérisation de clientBalanceProvider : ce que le code fait
// aujourd'hui, défauts compris (voir doc/F-RELEVE_PLAN.md). Ces tests ne
// doivent jamais changer quand le calcul passe par AccountStatementService.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

const _client = 'c1';
final _noon = DateTime(2026, 3, 10, 12);

WorkEntry _work(int cents, {String date = '2026-03-10', required DateTime at, int travelCents = 0}) => WorkEntry(
      id: 'w$cents',
      date: DateOnly.fromString(date),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: _client,
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(cents),
      laborAmountHT: Money.fromCents(cents),
      travelAmountHT: Money.fromCents(travelCents),
      createdAt: at,
      updatedAt: at,
    );

Expense _expense(int cents, {required DateTime at, bool billable = true}) => Expense(
      id: 'e$cents',
      date: DateOnly.fromString('2026-03-10'),
      clientId: _client,
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(cents),
      description: 'x',
      isBillable: billable,
      createdAt: at,
      updatedAt: at,
    );

Payment _payment(int cents, {String date = '2026-03-10', required DateTime at}) => Payment(
      id: 'p$cents',
      date: DateOnly.fromString(date),
      clientId: _client,
      amount: Money.fromCents(cents),
      method: PaymentMethod.cash,
      createdAt: at,
      updatedAt: at,
    );

ClientSettlement _settlement({required DateTime at, String date = '2026-03-10', int cents = 0}) => ClientSettlement(
      id: 's1',
      clientId: _client,
      date: DateOnly.fromString(date),
      balanceAtSettlement: Money.fromCents(cents),
      createdAt: at,
    );

Future<ClientBalance> _balance({
  List<WorkEntry> work = const [],
  List<Expense> expenses = const [],
  List<Payment> payments = const [],
  ClientSettlement? settlement,
}) async {
  final container = ProviderContainer(overrides: [
    workEntriesByClientStreamProvider(_client).overrideWith((ref) => Stream.value(work)),
    expensesByClientStreamProvider(_client).overrideWith((ref) => Stream.value(expenses)),
    paymentsStreamProvider(_client).overrideWith((ref) => Stream.value(payments)),
    lastSettlementProvider(_client).overrideWith((ref) => Stream.value(settlement)),
  ]);
  addTearDown(container.dispose);
  final sub = container.listen(clientBalanceProvider(_client), (_, __) {});
  while (sub.read().isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read().requireValue;
}

void main() {
  final before = _noon.subtract(const Duration(hours: 1));
  final after = _noon.add(const Duration(hours: 1));

  test('client vide : tout à zéro, jamais soldé', () async {
    final b = await _balance();
    expect(b.balance, Money.zero);
    expect(b.isPaid, isTrue);
    expect(b.isOverpaid, isFalse);
    expect(b.hasBeenSettled, isFalse);
    expect(b.balanceAtLastSettlement, isNull);
  });

  test('solde simple : prestations + dépenses facturables − paiements', () async {
    final b = await _balance(
      work: [_work(10000, at: before), _work(5050, at: before)],
      expenses: [_expense(2525, at: before)],
      payments: [_payment(3000, at: before)],
    );
    expect(b.totalWork.amountCents, 15050);
    expect(b.totalExpenses.amountCents, 2525);
    expect(b.totalPayments.amountCents, 3000);
    expect(b.totalDue.amountCents, 17575);
    expect(b.balance.amountCents, 14575);
  });

  test('dépense non facturable ignorée', () async {
    final b = await _balance(expenses: [_expense(999, at: before, billable: false)]);
    expect(b.totalExpenses, Money.zero);
  });

  // F-FIX-SOLDE.2 : changement volontaire, remplace "D1 : travelAmountHT ignoré
  // par le solde" (attendait 10000). Voir doc/F-FIX-SOLDE_SPRINT_REPORT.md.
  test('travelAmountHT inclus dans le solde, comme dans le PDF', () async {
    final b = await _balance(work: [_work(10000, at: before, travelCents: 1234)]);
    expect(b.totalWork.amountCents, 11234);
    expect(b.balance.amountCents, 11234);
  });

  test('paiement partiel : le reste dû est la différence', () async {
    final b = await _balance(work: [_work(10000, at: before)], payments: [_payment(2500, at: before)]);
    expect(b.balance.amountCents, 7500);
    expect(b.isPaid, isFalse);
  });

  test('sur-paiement : solde négatif', () async {
    final b = await _balance(work: [_work(100, at: before)], payments: [_payment(150, at: before)]);
    expect(b.balance.amountCents, -50);
    expect(b.isPaid, isTrue);
    expect(b.isOverpaid, isTrue);
  });

  group('après un solde', () {
    test('seules les lignes saisies après comptent, infos du solde exposées', () async {
      final b = await _balance(
        settlement: _settlement(at: _noon, cents: 4200),
        work: [_work(10000, at: before), _work(700, at: after)],
        expenses: [_expense(2000, at: before), _expense(30, at: after)],
        payments: [_payment(5000, at: before), _payment(200, at: after)],
      );
      expect(b.totalWork.amountCents, 700);
      expect(b.totalExpenses.amountCents, 30);
      expect(b.totalPayments.amountCents, 200);
      expect(b.balance.amountCents, 530);
      expect(b.hasBeenSettled, isTrue);
      expect(b.settlementDate, DateOnly.fromString('2026-03-10'));
      expect(b.balanceAtLastSettlement?.amountCents, 4200);
    });

    test('prestation le jour du solde, saisie APRÈS : comptée', () async {
      final b = await _balance(settlement: _settlement(at: _noon), work: [_work(700, at: after)]);
      expect(b.balance.amountCents, 700);
    });

    test('prestation le jour du solde, saisie AVANT : archivée', () async {
      final b = await _balance(settlement: _settlement(at: _noon), work: [_work(700, at: before)]);
      expect(b.balance, Money.zero);
    });

    test('createdAt égal au solde, à la milliseconde : archivée (isAfter strict)', () async {
      final b = await _balance(settlement: _settlement(at: _noon), work: [_work(700, at: _noon)]);
      expect(b.balance, Money.zero);
    });

    test('paiement daté avant le solde mais saisi après : compté', () async {
      final b = await _balance(
        settlement: _settlement(at: _noon),
        payments: [_payment(300, date: '2026-01-01', at: after)],
      );
      expect(b.balance.amountCents, -300);
    });

    test('prestation datée après le solde mais saisie avant : archivée', () async {
      final b = await _balance(
        settlement: _settlement(at: _noon),
        work: [_work(700, date: '2026-12-31', at: before)],
      );
      expect(b.balance, Money.zero);
    });

    test('soldes successifs : seul celui fourni par lastSettlementProvider coupe', () async {
      final later = _noon.add(const Duration(days: 30));
      final b = await _balance(
        settlement: _settlement(at: later, date: '2026-04-09'),
        work: [_work(100, at: before), _work(200, at: after), _work(400, at: later.add(const Duration(minutes: 1)))],
      );
      expect(b.balance.amountCents, 400);
    });
  });

  test('une erreur de flux est propagée', () async {
    final container = ProviderContainer(overrides: [
      workEntriesByClientStreamProvider(_client).overrideWith((ref) => Stream.error(StateError('boom'))),
      expensesByClientStreamProvider(_client).overrideWith((ref) => Stream.value(const [])),
      paymentsStreamProvider(_client).overrideWith((ref) => Stream.value(const [])),
      lastSettlementProvider(_client).overrideWith((ref) => Stream.value(null)),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(clientBalanceProvider(_client), (_, __) {});
    expect(sub.read().isLoading, isTrue);
    while (sub.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(sub.read().error, isA<StateError>());
  });
}
