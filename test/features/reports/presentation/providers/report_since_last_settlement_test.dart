import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

const _c = 'c1';
final _oldRange = DateTimeRange(start: DateTime(2020, 1, 1), end: DateTime(2020, 1, 31));

WorkEntry _work(String id, int cents, String date, DateTime at, {String? projectId}) => WorkEntry(
      id: id,
      date: DateOnly.fromString(date),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: _c,
      projectId: projectId,
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(cents),
      laborAmountHT: Money.fromCents(cents),
      createdAt: at,
      updatedAt: at,
    );

Expense _expense(String id, int cents, DateTime at) => Expense(
      id: id,
      date: DateOnly.fromDateTime(at),
      clientId: _c,
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(cents),
      description: 'x',
      createdAt: at,
      updatedAt: at,
    );

Payment _payment(String id, int cents, String date, DateTime at) => Payment(
      id: id,
      date: DateOnly.fromString(date),
      clientId: _c,
      amount: Money.fromCents(cents),
      method: PaymentMethod.cash,
      createdAt: at,
      updatedAt: at,
    );

final _settlement = ClientSettlement(
  id: 's1',
  clientId: _c,
  date: DateOnly.fromString('2026-03-10'),
  balanceAtSettlement: Money.zero,
  createdAt: DateTime(2026, 3, 10, 12),
);

final _before = DateTime(2026, 3, 10, 11);
final _after = DateTime(2026, 3, 10, 13);

ProviderContainer _container({
  required Stream<ClientSettlement?> Function() settlement,
  List<WorkEntry>? work,
}) {
  final entries = work ??
      [
        _work('old', 10000, '2026-03-10', _before),
        _work('new', 700, '2026-03-10', _after),
      ];
  final container = ProviderContainer(overrides: [
    workEntriesStreamProvider.overrideWith((ref) => Stream.value(entries)),
    expensesStreamProvider.overrideWith((ref) => Stream<List<Expense>>.value(const [])),
    paymentsStreamProvider(null).overrideWith((ref) => Stream<List<Payment>>.value(const [])),
    workEntriesByClientStreamProvider(_c).overrideWith((ref) => Stream.value(entries)),
    workEntriesByProjectStreamProvider('p1').overrideWith((ref) => Stream.value(entries)),
    expensesByClientStreamProvider(_c).overrideWith(
      (ref) => Stream.value([_expense('eOld', 500, _before), _expense('eNew', 30, _after)]),
    ),
    expensesByProjectStreamProvider('p1').overrideWith((ref) => Stream<List<Expense>>.value(const [])),
    paymentsStreamProvider(_c).overrideWith(
      (ref) => Stream.value([
        _payment('pOld', 2000, '2026-03-09', _before),
        _payment('pLate', 200, '2026-03-01', _after),
      ]),
    ),
    lastSettlementProvider(_c).overrideWith((ref) => settlement()),
  ]);
  addTearDown(container.dispose);
  return container;
}

Future<AsyncValue<ReportData>> _report(ProviderContainer container) async {
  final sub = container.listen(reportDataProvider, (_, __) {});
  while (sub.read().isLoading) {
    await Future<void>.delayed(Duration.zero);
  }
  return sub.read();
}

void main() {
  group('ReportFilterController.updateSinceLastSettlement', () {
    late ProviderContainer container;
    late ReportFilterController notifier;

    setUp(() {
      container = ProviderContainer();
      addTearDown(container.dispose);
      notifier = container.read(reportFilterProvider.notifier);
    });

    ReportFilter filter() => container.read(reportFilterProvider);

    test('désactivé par défaut, sans effet tant qu\'aucun client n\'est choisi', () {
      expect(filter().sinceLastSettlement, isFalse);
      notifier.updateSinceLastSettlement(true);
      expect(filter().sinceLastSettlement, isFalse);
    });

    test('activable avec un client, préserve la période et le chantier', () {
      notifier.updateDateRange(_oldRange);
      notifier.updateClient(_c);
      notifier.updateProject('p1');
      notifier.updateSinceLastSettlement(true);
      expect(filter().sinceLastSettlement, isTrue);
      expect(filter().dateRange, _oldRange);
      expect(filter().projectId, 'p1');
      notifier.updateSinceLastSettlement(false);
      expect(filter().sinceLastSettlement, isFalse);
    });

    test('conservé en changeant de client, retiré sur "Tous les clients"', () {
      notifier.updateClient(_c);
      notifier.updateSinceLastSettlement(true);
      notifier.updateClient('c2');
      expect(filter().sinceLastSettlement, isTrue);
      notifier.updateClient(null);
      expect(filter().sinceLastSettlement, isFalse);
    });

    test('conservé par updateDateRange et updateProject', () {
      notifier.updateClient(_c);
      notifier.updateSinceLastSettlement(true);
      notifier.updateDateRange(_oldRange);
      notifier.updateProject('p1');
      expect(filter().sinceLastSettlement, isTrue);
    });
  });

  group('reportDataProvider', () {
    test('filtre inactif : la période s\'applique, le solde ne compte pas', () async {
      final c = _container(settlement: () => Stream.value(_settlement));
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateDateRange(DateTimeRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 31)));
      final r = (await _report(c)).requireValue;
      expect(r.workEntries.map((e) => e.id), ['old', 'new']);
      expect(r.dateRange.start, DateTime(2026, 3, 1));
    });

    test('filtre actif : coupure createdAt comme le solde, période ignorée', () async {
      final c = _container(settlement: () => Stream.value(_settlement));
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateDateRange(_oldRange);
      n.updateSinceLastSettlement(true);
      final r = (await _report(c)).requireValue;
      expect(r.workEntries.map((e) => e.id), ['new']);
      expect(r.expenses.map((e) => e.id), ['eNew']);
      expect(r.payments.map((p) => p.id), ['pLate']);
      expect(r.totalLaborAmount.amountCents, 700);
      expect(r.theoreticalBalance.amountCents, 530);
    });

    test('dateRange couvre les lignes retenues, paiement en retard compris', () async {
      final c = _container(settlement: () => Stream.value(_settlement));
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateSinceLastSettlement(true);
      final r = (await _report(c)).requireValue;
      expect(r.dateRange.start, DateTime.parse('2026-03-01'));
      expect(r.dateRange.end, DateOnly.today().toDateTime());
    });

    test('jamais soldé : tout l\'historique, sans erreur', () async {
      final c = _container(settlement: () => Stream.value(null));
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateDateRange(_oldRange);
      n.updateSinceLastSettlement(true);
      final r = (await _report(c)).requireValue;
      expect(r.workEntries.map((e) => e.id), ['old', 'new']);
      expect(r.dateRange.start, DateTime.parse('2026-03-01'));
    });

    test('se combine avec le filtre chantier', () async {
      final c = _container(
        settlement: () => Stream.value(_settlement),
        work: [
          _work('in', 100, '2026-03-11', _after, projectId: 'p1'),
          _work('other', 200, '2026-03-11', _after, projectId: 'p2'),
          _work('old', 400, '2026-03-09', _before, projectId: 'p1'),
        ],
      );
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateProject('p1');
      n.updateSinceLastSettlement(true);
      final r = (await _report(c)).requireValue;
      expect(r.workEntries.map((e) => e.id), ['in']);
    });

    test('erreur du flux de solde propagée', () async {
      final c = _container(settlement: () => Stream.error(StateError('boom')));
      final n = c.read(reportFilterProvider.notifier);
      n.updateClient(_c);
      n.updateSinceLastSettlement(true);
      expect((await _report(c)).error, isA<StateError>());
    });
  });
}
