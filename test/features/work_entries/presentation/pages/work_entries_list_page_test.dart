import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/clients/presentation/providers/account_statement_provider.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entries_list_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

final _entries = [
  for (final (id, cents) in [('w1', 1000), ('w2', 2000)])
    WorkEntry(
      id: id,
      date: DateOnly.fromString('2026-03-10'),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: 'c1',
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(cents),
      laborAmountHT: Money.fromCents(cents),
      createdAt: DateTime(2026, 3, 10),
      updatedAt: DateTime(2026, 3, 10),
    ),
];

Future<void> _pump(WidgetTester tester, Widget page, AsyncValue<AccountStatement> statement) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      workEntriesByClientStreamProvider('c1').overrideWith((ref) => Stream.value(_entries)),
      workEntriesByProjectStreamProvider('p1').overrideWith((ref) => Stream.value(_entries)),
      clientStreamProvider('c1').overrideWith((ref) => Stream<Client?>.value(null)),
      accountStatementProvider('c1').overrideWithValue(statement),
    ],
    child: MaterialApp(home: page),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // Le service réel, pour vérifier le câblage de bout en bout jusqu'au badge.
  final statement = const AccountStatementService().build(
    workEntries: _entries,
    expenses: const [],
    payments: [],
    settlements: const [],
  );

  testWidgets('liste du client : statut du service affiché sur chaque prestation', (tester) async {
    await _pump(tester, const WorkEntriesListPage(clientId: 'c1'), AsyncValue.data(statement));
    expect(find.text('Impayée'), findsNWidgets(2));
  });

  testWidgets('relevé en chargement : la liste reste affichée, sans badge', (tester) async {
    await _pump(tester, const WorkEntriesListPage(clientId: 'c1'), const AsyncValue.loading());
    expect(find.text('10,00 €'), findsOneWidget);
    expect(find.text('Impayée'), findsNothing);
  });

  testWidgets('liste par chantier : aucun badge', (tester) async {
    await _pump(tester, const WorkEntriesListPage(clientId: 'c1', projectId: 'p1'), AsyncValue.data(statement));
    expect(find.text('10,00 €'), findsOneWidget);
    expect(find.text('Impayée'), findsNothing);
  });
}
