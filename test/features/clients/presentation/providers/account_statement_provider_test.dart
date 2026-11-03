import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/clients/presentation/providers/account_statement_provider.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

const _c = 'c1';

WorkEntry _work(String id, int cents, DateTime at) => WorkEntry(
      id: id,
      date: DateOnly.fromDateTime(at),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: _c,
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(cents),
      laborAmountHT: Money.fromCents(cents),
      createdAt: at,
      updatedAt: at,
    );

Payment _payment(String id, int cents, DateTime at) => Payment(
      id: id,
      date: DateOnly.fromDateTime(at),
      clientId: _c,
      amount: Money.fromCents(cents),
      method: PaymentMethod.cash,
      createdAt: at,
      updatedAt: at,
    );

ClientSettlement _settlement(String id, DateTime at) => ClientSettlement(
      id: id,
      clientId: _c,
      date: DateOnly.fromDateTime(at),
      balanceAtSettlement: Money.zero,
      createdAt: at,
    );

ProviderContainer _container({
  required Stream<List<WorkEntry>> Function() work,
  List<Payment> payments = const [],
  List<ClientSettlement> settlements = const [],
}) {
  final sorted = [...settlements]..sort((a, b) => b.date.compareTo(a.date));
  final container = ProviderContainer(overrides: [
    workEntriesByClientStreamProvider(_c).overrideWith((ref) => work()),
    expensesByClientStreamProvider(_c).overrideWith((ref) => Stream<List<Expense>>.value(const [])),
    paymentsStreamProvider(_c).overrideWith((ref) => Stream.value(payments)),
    allSettlementsProvider(_c).overrideWith((ref) => Stream.value(sorted)),
    lastSettlementProvider(_c).overrideWith((ref) => Stream.value(sorted.isEmpty ? null : sorted.first)),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<AccountStatement>> _settle(ProviderContainer container) async {
  final sub = container.listen(accountStatementProvider(_c), (_, __) {});
  expect(sub.read().isLoading, isTrue);
  while (sub.read().isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read();
}

void main() {
  test('combine les flux, soldes successifs compris', () async {
    final s = (await _settle(_container(
      work: () => Stream.value([_work('a', 100, DateTime(2026, 3, 1)), _work('b', 200, DateTime(2026, 3, 6))]),
      settlements: [_settlement('s1', DateTime(2026, 3, 5)), _settlement('s0', DateTime(2026, 3, 2))],
    )))
        .requireValue;
    expect(s.lines.map((l) => l.id), ['a', 's0', 's1', 'b']);
    expect(s.balance.amountCents, 200);
  });

  test('même solde que clientBalanceProvider, au centime', () async {
    final container = _container(
      work: () => Stream.value([_work('a', 12345, DateTime(2026, 3, 1)), _work('b', 6789, DateTime(2026, 3, 6))]),
      payments: [_payment('p', 1111, DateTime(2026, 3, 7))],
      settlements: [_settlement('s1', DateTime(2026, 3, 5))],
    );
    final statement = (await _settle(container)).requireValue;
    final balanceSub = container.listen(clientBalanceProvider(_c), (_, __) {});
    while (balanceSub.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(statement.balance, balanceSub.read().requireValue.balance);
    expect(statement.balance.amountCents, 5678);
  });

  test('une erreur de flux est propagée', () async {
    final result = await _settle(_container(work: () => Stream.error(StateError('boom'))));
    expect(result.error, isA<StateError>());
  });

  test('recalculé quand un flux émet à nouveau', () async {
    final container = _container(
      work: () => Stream.fromIterable([
        [_work('a', 100, DateTime(2026, 3, 1))],
        [_work('a', 100, DateTime(2026, 3, 1)), _work('b', 200, DateTime(2026, 3, 2))],
      ]),
    );
    final sub = container.listen(accountStatementProvider(_c), (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(sub.read().requireValue.balance.amountCents, 300);
  });
}
