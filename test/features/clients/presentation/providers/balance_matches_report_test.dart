// F-FIX-SOLDE.2 — preuve que les trois chiffres n'en font qu'un : solde du
// compte, solde du relevé et "Reste à percevoir" du rapport filtré "Depuis le
// dernier solde". C'est ce filtre qui rend la comparaison valide : avec une
// période libre, le rapport porte sur un autre périmètre que le solde.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/presentation/providers/account_statement_provider.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

const _c = 'c1';
final _before = DateTime(2026, 3, 10, 11);
final _after = DateTime(2026, 3, 10, 13);

WorkEntry _work(String id, int labor, int travel, DateTime at) => WorkEntry(
      id: id,
      date: DateOnly.fromString('2026-03-10'),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: _c,
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(labor),
      laborAmountHT: Money.fromCents(labor),
      travelAmountHT: Money.fromCents(travel),
      createdAt: at,
      updatedAt: at,
    );

Expense _expense(String id, int cents, DateTime at, {bool billable = true}) => Expense(
      id: id,
      date: DateOnly.fromString('2026-03-10'),
      clientId: _c,
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(cents),
      description: 'x',
      isBillable: billable,
      createdAt: at,
      updatedAt: at,
    );

Payment _payment(String id, int cents, DateTime at) => Payment(
      id: id,
      date: DateOnly.fromString('2026-03-10'),
      clientId: _c,
      amount: Money.fromCents(cents),
      method: PaymentMethod.cash,
      createdAt: at,
      updatedAt: at,
    );

Future<void> _expectSameEverywhere(List<ClientSettlement> settlements, int expectedCents) async {
  final container = ProviderContainer(overrides: [
    workEntriesByClientStreamProvider(_c).overrideWith((ref) => Stream.value([
          _work('wOld', 50000, 4000, _before),
          _work('wNew', 12345, 1234, _after),
          _work('wNew2', 6789, 0, _after),
        ])),
    expensesByClientStreamProvider(_c).overrideWith((ref) => Stream.value([
          _expense('eOld', 7000, _before),
          _expense('eNew', 2525, _after),
          _expense('eInternal', 999, _after, billable: false),
        ])),
    paymentsStreamProvider(_c).overrideWith((ref) => Stream.value([
          _payment('pOld', 9000, _before),
          _payment('pNew', 3333, _after),
        ])),
    allSettlementsProvider(_c).overrideWith((ref) => Stream.value(settlements)),
    lastSettlementProvider(_c).overrideWith((ref) => Stream.value(settlements.isEmpty ? null : settlements.first)),
  ]);
  addTearDown(container.dispose);

  final filter = container.read(reportFilterProvider.notifier);
  filter.updateClient(_c);
  filter.updateSinceLastSettlement(true);

  final balance = container.listen(clientBalanceProvider(_c), (_, __) {});
  final statement = container.listen(accountStatementProvider(_c), (_, __) {});
  final report = container.listen(reportDataProvider, (_, __) {});
  while (balance.read().isLoading || statement.read().isLoading || report.read().isLoading) {
    await Future<void>.delayed(Duration.zero);
  }

  expect(report.read().requireValue.theoreticalBalance.amountCents, expectedCents);
  expect(statement.read().requireValue.balance.amountCents, expectedCents);
  expect(balance.read().requireValue.balance.amountCents, expectedCents);
  expect(statement.read().requireValue.lines.last.runningBalance.amountCents, expectedCents);
}

void main() {
  test('après un solde : Reste à percevoir = solde du relevé = solde du compte', () async {
    final settlement = ClientSettlement(
      id: 's1',
      clientId: _c,
      date: DateOnly.fromString('2026-03-10'),
      balanceAtSettlement: Money.zero,
      createdAt: DateTime(2026, 3, 10, 12),
    );
    await _expectSameEverywhere([settlement], 12345 + 1234 + 6789 + 2525 - 3333);
  });

  ClientSettlement withCarry(int cents) => ClientSettlement(
        id: 's1',
        clientId: _c,
        date: DateOnly.fromString('2026-03-10'),
        balanceAtSettlement: Money.fromCents(cents),
        carriedOverAmount: Money.fromCents(cents),
        createdAt: DateTime(2026, 3, 10, 12),
      );

  test('report positif : compté une fois, au même centime partout', () async {
    await _expectSameEverywhere([withCarry(4321)], 4321 + 12345 + 1234 + 6789 + 2525 - 3333);
  });

  test('report négatif (avance) : déduit au même centime partout', () async {
    await _expectSameEverywhere([withCarry(-50000)], -50000 + 12345 + 1234 + 6789 + 2525 - 3333);
  });

  test('jamais soldé : mêmes trois chiffres sur tout l\'historique', () async {
    await _expectSameEverywhere(
      const [],
      50000 + 4000 + 12345 + 1234 + 6789 + 7000 + 2525 - 9000 - 3333,
    );
  });
}
