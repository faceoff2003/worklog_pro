// Tests de caractérisation de WorkEntryFormPage._save() (R-SEC.3 étape 2),
// écrits AVANT toute extraction vers WorkEntryBuilderService. Ils doivent
// passer sur le code actuel tel quel. Après extraction, ils doivent passer
// à l'identique, au centime près — sinon c'est un changement de
// comportement, pas un refactoring.
//
// La page n'a aucun autre test widget : ceci ajoute aussi la couverture
// manquante sur la validation live du champ Pause.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_form_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

/// Repository fake : enregistre ce qui lui est passé, n'écrit nulle part.
class _RecordingWorkEntryRepository implements WorkEntryRepository {
  WorkEntry? created;
  WorkEntry? updated;

  @override
  Stream<List<WorkEntry>> watchWorkEntries({
    DateOnly? from,
    DateOnly? to,
    String? clientId,
    String? projectId,
  }) => const Stream.empty();

  @override
  Future<List<WorkEntry>> getWorkEntries({
    DateOnly? from,
    DateOnly? to,
    String? clientId,
    String? projectId,
  }) async => const [];

  @override
  Future<WorkEntry?> getWorkEntry(String id) async => null;

  @override
  Future<WorkEntry> createWorkEntry(WorkEntry workEntry) async {
    created = workEntry;
    return workEntry;
  }

  @override
  Future<WorkEntry> updateWorkEntry(WorkEntry workEntry) async {
    updated = workEntry;
    return workEntry;
  }

  @override
  Future<void> deleteWorkEntry(String id) async {}
}

Client _testClient() {
  return Client(
    id: 'client-1',
    name: 'Jean Dupont',
    type: ClientType.patron,
    defaultRates: DefaultRates(
      hour: Money.fromCents(2000), // 20,00 €/h
      halfDay: Money.fromCents(15000), // 150,00 €
      day: Money.fromCents(30000), // 300,00 €
      fixedJob: Money.fromCents(50000), // 500,00 €
    ),
    tags: const [],
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

WorkEntry _presetEntry({
  required String id,
  required BillingMode initialMode,
  required int startTime,
  required int endTime,
  required int pauseMinutes,
  double travelDistanceKm = 0.0,
  double travelRatePerKm = 0.20,
}) {
  return WorkEntry(
    id: id,
    date: DateOnly.fromString('2026-01-15'),
    startTime: startTime,
    endTime: endTime,
    pauseMinutes: pauseMinutes,
    durationMinutes: 0,
    clientId: 'client-1',
    billingMode: initialMode,
    rateApplied: Money.zero,
    laborAmountHT: Money.zero,
    travelDistanceKm: travelDistanceKm,
    travelRatePerKm: travelRatePerKm,
    travelAmountHT: Money.zero,
    notes: '',
    createdAt: DateTime(2025, 6, 1),
    updatedAt: DateTime(2025, 6, 1),
  );
}

Future<_RecordingWorkEntryRepository> _pumpForm(
  WidgetTester tester, {
  WorkEntry? workEntry,
  String? initialClientId,
}) async {
  final repo = _RecordingWorkEntryRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clientsStreamProvider.overrideWith((ref) => Stream.value([_testClient()])),
        projectsByClientStreamProvider.overrideWith((ref, clientId) => Stream.value(const [])),
        workEntryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorkEntryFormPage(
                    workEntry: workEntry,
                    initialClientId: initialClientId,
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return repo;
}

Future<void> _selectBillingMode(WidgetTester tester, BillingMode mode) async {
  await tester.tap(find.byType(DropdownButtonFormField<BillingMode>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode.displayName).last);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final saveButton = find.text('Enregistrer la prestation');
  await tester.ensureVisible(saveButton);
  await tester.pumpAndSettle();
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

void main() {
  // ─────────────────────────────────────────────────────────────
  // Validation live du champ Pause (aucun test widget n'existait avant)
  // ─────────────────────────────────────────────────────────────
  group('validation live — Pause', () {
    testWidgets('8h00/8h00/10min → "Heure de fin invalide" affiché', (tester) async {
      await _pumpForm(
        tester,
        workEntry: _presetEntry(
          id: 'entry-1',
          initialMode: BillingMode.hourly,
          startTime: 480,
          endTime: 480,
          pauseMinutes: 10,
        ),
      );

      expect(find.text('Heure de fin invalide (doit être après le début)'), findsOneWidget);
    });

    testWidgets('8h00/12h00/300min → "Pause supérieure à la durée travaillée" affiché', (tester) async {
      await _pumpForm(
        tester,
        workEntry: _presetEntry(
          id: 'entry-1',
          initialMode: BillingMode.hourly,
          startTime: 480,
          endTime: 720,
          pauseMinutes: 300,
        ),
      );

      expect(find.text('Pause supérieure à la durée travaillée'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Caractérisation _save() — 4 modes × avec/sans déplacement (édition)
  //
  // Le calcul (durée, laborAmountHT, rateApplied, travelAmountHT) ne
  // branche jamais sur _isEditing : caractérisé une seule fois, en
  // édition, où il est pratique de fixer heures/pause via l'entrée
  // préremplie plutôt que le time picker natif.
  // ─────────────────────────────────────────────────────────────
  group('caractérisation _save() — calcul des montants (édition)', () {
    final cases = <(BillingMode mode, Money expectedLabor, Money expectedRate)>[
      (BillingMode.hourly, Money.fromCents(16000), Money.fromCents(2000)), // 8h * 20,00€/h
      (BillingMode.half_day, Money.fromCents(15000), Money.fromCents(15000)),
      (BillingMode.day, Money.fromCents(30000), Money.fromCents(30000)),
      (BillingMode.fixed_job, Money.fromCents(50000), Money.fromCents(50000)),
    ];

    for (final (mode, expectedLabor, expectedRate) in cases) {
      // Mode de départ toujours différent du mode testé, pour garantir que
      // la sélection déclenche bien _recalculate(updatePrice: true).
      final initialMode = BillingMode.values.firstWhere((m) => m != mode);

      testWidgets('${mode.name} — sans déplacement', (tester) async {
        final repo = await _pumpForm(
          tester,
          workEntry: _presetEntry(
            id: 'entry-1',
            initialMode: initialMode,
            startTime: 480, // 08:00
            endTime: 1020, // 17:00
            pauseMinutes: 60,
          ),
        );

        await _selectBillingMode(tester, mode);
        await _tapSave(tester);

        final saved = repo.updated;
        expect(saved, isNotNull, reason: 'updateWorkEntry aurait dû être appelé');
        expect(saved!.durationMinutes, 480);
        expect(saved.laborAmountHT, expectedLabor);
        expect(saved.rateApplied, expectedRate);
        expect(saved.travelAmountHT, Money.zero);
        expect(repo.created, isNull);
      });

      testWidgets('${mode.name} — avec déplacement (10km, 0.50€/km)', (tester) async {
        final repo = await _pumpForm(
          tester,
          workEntry: _presetEntry(
            id: 'entry-1',
            initialMode: initialMode,
            startTime: 480,
            endTime: 1020,
            pauseMinutes: 60,
          ),
        );

        await tester.enterText(find.widgetWithText(TextFormField, 'Distance'), '10.0');
        await tester.enterText(find.widgetWithText(TextFormField, 'Taux (par km)'), '0.5');
        await _selectBillingMode(tester, mode);
        await _tapSave(tester);

        final saved = repo.updated;
        expect(saved, isNotNull, reason: 'updateWorkEntry aurait dû être appelé');
        expect(saved!.laborAmountHT, expectedLabor);
        expect(saved.rateApplied, expectedRate);
        // (10km * 2 aller-retour) * 0.50€ = 10,00€
        expect(saved.travelAmountHT, Money.fromCents(1000));
        expect(repo.created, isNull);
      });
    }
  });

  // ─────────────────────────────────────────────────────────────
  // Divergence création / édition (id, createdAt, méthode repository)
  // ─────────────────────────────────────────────────────────────
  group('caractérisation _save() — divergence création / édition', () {
    testWidgets('création (workEntry null) : id vide, createdAt frais, createWorkEntry appelé', (tester) async {
      final before = DateTime.now();
      final repo = await _pumpForm(tester, initialClientId: 'client-1');

      await _selectBillingMode(tester, BillingMode.day);
      await _tapSave(tester);
      final after = DateTime.now();

      expect(repo.updated, isNull);
      final saved = repo.created;
      expect(saved, isNotNull, reason: 'createWorkEntry aurait dû être appelé');
      expect(saved!.id, '');
      expect(
        saved.createdAt.isAfter(before.subtract(const Duration(seconds: 1))) &&
            saved.createdAt.isBefore(after.add(const Duration(seconds: 1))),
        isTrue,
        reason: 'createdAt doit être généré au moment de la sauvegarde, pas préservé',
      );
      expect(saved.laborAmountHT, Money.fromCents(30000));
      expect(saved.rateApplied, Money.fromCents(30000));
      expect(saved.clientId, 'client-1');
    });

    testWidgets('édition (workEntry non-null) : id et createdAt préservés, updateWorkEntry appelé', (tester) async {
      final originalCreatedAt = DateTime(2025, 6, 1);
      final repo = await _pumpForm(
        tester,
        workEntry: WorkEntry(
          id: 'entry-42',
          date: DateOnly.fromString('2026-01-15'),
          startTime: 480,
          endTime: 1020,
          pauseMinutes: 60,
          durationMinutes: 0,
          clientId: 'client-1',
          billingMode: BillingMode.half_day,
          rateApplied: Money.zero,
          laborAmountHT: Money.zero,
          travelDistanceKm: 0.0,
          travelRatePerKm: 0.20,
          travelAmountHT: Money.zero,
          notes: '',
          createdAt: originalCreatedAt,
          updatedAt: originalCreatedAt,
        ),
      );

      await _selectBillingMode(tester, BillingMode.day);
      await _tapSave(tester);

      expect(repo.created, isNull);
      final saved = repo.updated;
      expect(saved, isNotNull, reason: 'updateWorkEntry aurait dû être appelé');
      expect(saved!.id, 'entry-42');
      expect(saved.createdAt, originalCreatedAt);
    });
  });
}
