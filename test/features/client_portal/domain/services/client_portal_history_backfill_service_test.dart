// C-PORTAL.9, étapes 1 et 2 — le service de backfill seul, aucune UI.
//
// Points tranchés avec William avant de coder, tous vérifiés ici :
// - BackfillOutcome porte les deux compteurs séparément (jamais agrégés).
// - Le résultat est persisté (saveBackfillStatus) à la fin de
//   backfillHistory(), même incomplet — sans ça l'indicateur persistant
//   côté ClientDetailPage (étape 3) n'aurait jamais de source.
// - Le filtre isBillable sur les dépenses est appliqué AVANT toute
//   construction de batch — jamais laissé à la rule (un WriteBatch est tout
//   ou rien, une seule dépense non refacturable ferait échouer tout le
//   lot). La preuve que ça casserait réellement sans le filtre est un test
//   d'intégration séparé (émulateur, vraies rules) — un fake ne peut pas
//   la fournir.
// - Prestations et dépenses sont tentées indépendamment : l'échec de l'une
//   ne doit jamais empêcher la tentative de l'autre.
// - Idempotence : réutilise les mêmes IDs que le mirroring normal —
//   prouvée par un test d'intégration séparé (émulateur), pas ici.

import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_history_backfill_service.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';

class _FakeWorkEntryRepository implements WorkEntryRepository {
  List<WorkEntry> entries = [];

  @override
  Future<List<WorkEntry>> getWorkEntries({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) async =>
      entries;

  @override
  Stream<List<WorkEntry>> watchWorkEntries({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) =>
      throw UnimplementedError();
  @override
  Future<WorkEntry?> getWorkEntry(String id) => throw UnimplementedError();
  @override
  Future<WorkEntry> createWorkEntry(WorkEntry workEntry) => throw UnimplementedError();
  @override
  Future<WorkEntry> updateWorkEntry(WorkEntry workEntry) => throw UnimplementedError();
  @override
  Future<void> deleteWorkEntry(String id) => throw UnimplementedError();
}

class _FakeExpenseRepository implements ExpenseRepository {
  List<Expense> expenses = [];

  @override
  Future<List<Expense>> getExpenses({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) async =>
      expenses;

  @override
  Stream<List<Expense>> watchExpenses({String? clientId, String? projectId}) => throw UnimplementedError();
  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override
  Future<void> updateExpense(Expense expense) => throw UnimplementedError();
  @override
  Future<void> deleteExpense(String id) => throw UnimplementedError();
}

class _FakeClientPortalRepository implements ClientPortalRepository {
  final List<List<WorkEntry>> workEntryBatchCalls = [];
  final List<List<Expense>> expenseBatchCalls = [];

  /// Index (0-based) des appels à faire échouer, par type.
  Set<int> failWorkEntryBatchAt = {};
  Set<int> failExpenseBatchAt = {};

  int saveBackfillStatusCallCount = 0;
  BackfillOutcome? lastSavedBackfillStatus;

  @override
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) async {
    final callIndex = workEntryBatchCalls.length;
    workEntryBatchCalls.add(entries);
    if (failWorkEntryBatchAt.contains(callIndex)) throw Exception('échec simulé (prestations, batch $callIndex)');
  }

  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) async {
    final callIndex = expenseBatchCalls.length;
    expenseBatchCalls.add(expenses);
    if (failExpenseBatchAt.contains(callIndex)) throw Exception('échec simulé (dépenses, batch $callIndex)');
  }

  @override
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome) async {
    saveBackfillStatusCallCount++;
    lastSavedBackfillStatus = outcome;
  }

  @override
  Future<BackfillOutcome?> getBackfillStatus(String portalUid) => throw UnimplementedError();

  @override
  Future<ClientPortal?> getPortal(String portalUid) => throw UnimplementedError();
  @override
  Future<void> setEnabled(String portalUid, bool enabled) => throw UnimplementedError();
  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) => throw UnimplementedError();
  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) =>
      throw UnimplementedError();
  @override
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId) => throw UnimplementedError();
  @override
  Future<void> mirrorExpense(String portalUid, Expense expense) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredExpense(String portalUid, String expenseId) => throw UnimplementedError();
}

WorkEntry _entry(String id) => WorkEntry(
      id: id,
      date: DateOnly.fromString('2026-01-01'),
      startTime: 480,
      endTime: 720,
      durationMinutes: 240,
      clientId: 'client-1',
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(2000),
      laborAmountHT: Money.fromCents(8000),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Expense _expense(String id, {bool isBillable = true}) => Expense(
      id: id,
      date: DateOnly.fromString('2026-01-01'),
      clientId: 'client-1',
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(1000),
      description: 'Câble',
      isBillable: isBillable,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeWorkEntryRepository workEntryRepo;
  late _FakeExpenseRepository expenseRepo;
  late _FakeClientPortalRepository portalRepo;
  late ClientPortalHistoryBackfillService service;

  setUp(() {
    workEntryRepo = _FakeWorkEntryRepository();
    expenseRepo = _FakeExpenseRepository();
    portalRepo = _FakeClientPortalRepository();
    service = ClientPortalHistoryBackfillService(workEntryRepo, expenseRepo, portalRepo);
  });

  Future<BackfillOutcome> run() =>
      service.backfillHistory(portalUid: 'portal-uid-1', clientId: 'client-1');

  group('chemin heureux', () {
    test('tout l\'historique tient dans un seul batch — un seul appel, tout mirroré', () async {
      workEntryRepo.entries = List.generate(20, (i) => _entry('entry-$i'));
      expenseRepo.expenses = List.generate(5, (i) => _expense('expense-$i'));

      final outcome = await run();

      expect(outcome.totalWorkEntries, 20);
      expect(outcome.mirroredWorkEntries, 20);
      expect(outcome.totalExpenses, 5);
      expect(outcome.mirroredExpenses, 5);
      expect(outcome.isComplete, isTrue);
      expect(portalRepo.workEntryBatchCalls.length, 1);
      expect(portalRepo.expenseBatchCalls.length, 1);
    });

    test('le résultat est persisté via saveBackfillStatus, exactement ce que renvoie backfillHistory', () async {
      workEntryRepo.entries = List.generate(20, (i) => _entry('entry-$i'));
      expenseRepo.expenses = List.generate(5, (i) => _expense('expense-$i'));

      final outcome = await run();

      expect(portalRepo.saveBackfillStatusCallCount, 1);
      expect(portalRepo.lastSavedBackfillStatus, isNotNull);
      expect(portalRepo.lastSavedBackfillStatus!.totalWorkEntries, outcome.totalWorkEntries);
      expect(portalRepo.lastSavedBackfillStatus!.mirroredWorkEntries, outcome.mirroredWorkEntries);
      expect(portalRepo.lastSavedBackfillStatus!.totalExpenses, outcome.totalExpenses);
      expect(portalRepo.lastSavedBackfillStatus!.mirroredExpenses, outcome.mirroredExpenses);
    });

    test('découpage en plusieurs batchs au-delà de 500', () async {
      workEntryRepo.entries = List.generate(1200, (i) => _entry('entry-$i'));

      final outcome = await run();

      expect(outcome.mirroredWorkEntries, 1200);
      expect(portalRepo.workEntryBatchCalls.length, 3); // 500 + 500 + 200
      expect(portalRepo.workEntryBatchCalls[0].length, 500);
      expect(portalRepo.workEntryBatchCalls[1].length, 500);
      expect(portalRepo.workEntryBatchCalls[2].length, 200);
    });
  });

  group('filtre isBillable — appliqué AVANT construction du batch', () {
    test('une dépense non refacturable n\'est jamais transmise à mirrorExpensesBatch', () async {
      expenseRepo.expenses = [
        _expense('billable-1'),
        _expense('non-billable-1', isBillable: false),
        _expense('billable-2'),
      ];

      final outcome = await run();

      expect(outcome.totalExpenses, 2, reason: 'le total ne compte que les refacturables, filtrées avant tout');
      expect(outcome.mirroredExpenses, 2);
      expect(portalRepo.expenseBatchCalls.single.map((e) => e.id), ['billable-1', 'billable-2']);
    });
  });

  group('échec partiel — déterministe, compteurs séparés', () {
    test('le 2e batch de prestations échoue -> s\'arrête net, ne tente pas le 3e', () async {
      workEntryRepo.entries = List.generate(1200, (i) => _entry('entry-$i'));
      portalRepo.failWorkEntryBatchAt = {1}; // le 2e appel (index 1) échoue

      final outcome = await run();

      expect(outcome.mirroredWorkEntries, 500, reason: 'seul le 1er batch (500) a réussi avant l\'échec du 2e');
      expect(outcome.workEntriesComplete, isFalse);
      expect(portalRepo.workEntryBatchCalls.length, 2, reason: 'le 3e batch ne doit jamais être tenté');
    });

    test(
      'prestations ET dépenses portent leur échec séparément — jamais un compteur agrégé qui masquerait lequel a foiré',
      () async {
        workEntryRepo.entries = List.generate(20, (i) => _entry('entry-$i'));
        expenseRepo.expenses = List.generate(5, (i) => _expense('expense-$i'));
        portalRepo.failExpenseBatchAt = {0};

        final outcome = await run();

        expect(outcome.mirroredWorkEntries, 20);
        expect(outcome.workEntriesComplete, isTrue);
        expect(outcome.mirroredExpenses, 0);
        expect(outcome.expensesComplete, isFalse);
      },
    );

    test(
      'les prestations échouent ENTIÈREMENT — les dépenses sont quand même tentées et réussissent (indépendance, pas d\'arrêt en cascade)',
      () async {
        workEntryRepo.entries = List.generate(20, (i) => _entry('entry-$i'));
        expenseRepo.expenses = List.generate(5, (i) => _expense('expense-$i'));
        portalRepo.failWorkEntryBatchAt = {0};

        final outcome = await run();

        expect(outcome.mirroredWorkEntries, 0);
        expect(outcome.workEntriesComplete, isFalse);
        expect(outcome.mirroredExpenses, 5, reason: 'l\'échec des prestations ne doit jamais empêcher la tentative des dépenses');
        expect(outcome.expensesComplete, isTrue);
        expect(portalRepo.expenseBatchCalls.length, 1, reason: 'les dépenses ont bien été tentées malgré l\'échec des prestations');
      },
    );

    test(
      'un échec partiel est quand même persisté via saveBackfillStatus — c\'est précisément ce qui permet '
      'à l\'artisan de voir "3/20" plutôt que rien du tout',
      () async {
        workEntryRepo.entries = List.generate(20, (i) => _entry('entry-$i'));
        portalRepo.failWorkEntryBatchAt = {0};

        await run();

        expect(portalRepo.saveBackfillStatusCallCount, 1);
        expect(portalRepo.lastSavedBackfillStatus!.totalWorkEntries, 20);
        expect(portalRepo.lastSavedBackfillStatus!.mirroredWorkEntries, 0);
      },
    );
  });
}
