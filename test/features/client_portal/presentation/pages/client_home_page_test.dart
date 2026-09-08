// C-PORTAL.8, étape 2 — vérifie, ne déduit pas, le risque de boucle soulevé
// par William : si le flux de prestations échoue plusieurs fois de suite
// avec permission-denied alors que le portail reste réellement enabled,
// est-ce que chaque échec redéclenche une réinvalidation de
// userPortalProvider (donc un nouvel appel à getPortal()), sans borne ?

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_mirror_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_disabled_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_home_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/post_auth_role_router.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_mirror_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

const _uid = 'client-uid-1';

WorkEntry _entry({required String id, required String date}) => WorkEntry(
      id: id,
      date: DateOnly.fromString(date),
      startTime: 480,
      endTime: 720,
      durationMinutes: 240,
      clientId: 'client-doc-1',
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(2000),
      laborAmountHT: Money.fromCents(8000),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

class _FakeClientPortalRepository implements ClientPortalRepository {
  int getPortalCallCount = 0;

  @override
  Future<ClientPortal?> getPortal(String portalUid) async {
    getPortalCallCount++;
    return ClientPortal(
      portalUid: _uid,
      artisanUid: 'artisan-uid-1',
      clientId: 'client-doc-1',
      enabled: true, // reste enabled — c'est exactement l'anomalie testée.
      createdAt: DateTime(2026, 1, 1),
    );
  }

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) =>
      throw UnimplementedError();
  @override
  Future<void> setEnabled(String portalUid, bool enabled) => throw UnimplementedError();
  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) => throw UnimplementedError();
  @override
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId) => throw UnimplementedError();
  @override
  Future<void> mirrorExpense(String portalUid, Expense expense) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredExpense(String portalUid, String expenseId) => throw UnimplementedError();
  @override
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) => throw UnimplementedError();
  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) => throw UnimplementedError();
  @override
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome) => throw UnimplementedError();
  @override
  Future<BackfillOutcome?> getBackfillStatus(String portalUid) => throw UnimplementedError();
}

class _FakeClientMirrorRepository implements ClientMirrorRepository {
  final StreamController<List<WorkEntry>> controller;
  _FakeClientMirrorRepository(this.controller);

  @override
  Stream<List<WorkEntry>> watchMyWorkEntries() => controller.stream;
}

Future<_FakeClientPortalRepository> _pump(
  WidgetTester tester,
  StreamController<List<WorkEntry>> controller,
) async {
  final fakePortalRepo = _FakeClientPortalRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          AppUser(uid: _uid, email: 'client@example.com', createdAt: DateTime(2026, 1, 1)),
        ),
        clientPortalRepositoryProvider.overrideWithValue(fakePortalRepo),
        clientMirrorRepositoryProvider.overrideWithValue(_FakeClientMirrorRepository(controller)),
      ],
      child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
    ),
  );
  // Sort du spinner initial (animation continue, pumpAndSettle ne convergerait
  // jamais) avant de passer aux injections d'erreurs du test lui-même.
  controller.add(const []);
  await tester.pumpAndSettle();
  return fakePortalRepo;
}

void main() {
  testWidgets(
    'plusieurs permission-denied d\'affilée sur le flux, portail resté enabled — '
    'compte les appels à getPortal(), ne déduit rien',
    (tester) async {
      final controller = StreamController<List<WorkEntry>>();
      final fakePortalRepo = await _pump(tester, controller);

      expect(fakePortalRepo.getPortalCallCount, 1, reason: 'le check de rôle initial du routeur');
      expect(find.byType(ClientHomePage), findsOneWidget);

      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await tester.pumpAndSettle();
      final countAfterFirstError = fakePortalRepo.getPortalCallCount;

      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await tester.pumpAndSettle();
      final countAfterSecondError = fakePortalRepo.getPortalCallCount;

      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await tester.pumpAndSettle();
      final countAfterThirdError = fakePortalRepo.getPortalCallCount;

      // Garde anti-boucle : UNE seule réinvalidation tant que l'erreur
      // persiste — 1 (check initial) + 1 (le premier permission-denied),
      // jamais plus, quel que soit le nombre d'échecs consécutifs ensuite.
      // Sans la garde, ce test échoue avec 2/3/4 (vérifié avant de l'ajouter).
      expect(countAfterFirstError, 2);
      expect(countAfterSecondError, 2);
      expect(countAfterThirdError, 2);

      // Le portail est resté enabled tout du long : ClientHomePage doit
      // rester affiché (jamais rebasculé vers ClientDisabledPage), quel que
      // soit le nombre d'appels à getPortal() déclenchés en coulisses.
      expect(find.byType(ClientHomePage), findsOneWidget);
      expect(find.byType(ClientDisabledPage), findsNothing);

      await controller.close();
    },
  );

  testWidgets(
    'la garde se réarme après une reprise — un permission-denied qui revient plus tard redéclenche bien une réinvalidation',
    (tester) async {
      final controller = StreamController<List<WorkEntry>>();
      final fakePortalRepo = await _pump(tester, controller);
      expect(fakePortalRepo.getPortalCallCount, 1);

      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await tester.pumpAndSettle();
      expect(fakePortalRepo.getPortalCallCount, 2, reason: 'premier échec — une réinvalidation');

      // Le flux se rétablit (ex. l'artisan réactive, ou une vraie reprise réseau).
      controller.add(const []);
      await tester.pumpAndSettle();
      expect(fakePortalRepo.getPortalCallCount, 2, reason: 'une reprise ne déclenche pas de réinvalidation à elle seule');

      // Un NOUVEL échec, plus tard — doit redéclencher, pas rester bloqué
      // par la garde du premier épisode.
      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
      await tester.pumpAndSettle();
      expect(fakePortalRepo.getPortalCallCount, 3, reason: 'un nouvel épisode doit redéclencher la réinvalidation');

      await controller.close();
    },
  );

  testWidgets('données — affiche les prestations reçues', (tester) async {
    final controller = StreamController<List<WorkEntry>>();
    await _pump(tester, controller);

    controller.add([_entry(id: 'e1', date: '2026-03-10')]);
    await tester.pumpAndSettle();

    expect(find.text('10/03/2026'), findsOneWidget);
    expect(find.text('Horaire'), findsOneWidget);
    expect(find.text('80,00 €'), findsOneWidget);

    await controller.close();
  });

  testWidgets('liste vide — message dédié, pas une erreur', (tester) async {
    final controller = StreamController<List<WorkEntry>>();
    await _pump(tester, controller);
    // _pump émet déjà une liste vide pour sortir du spinner initial.

    expect(find.text('Aucune prestation pour le moment.'), findsOneWidget);

    await controller.close();
  });

  testWidgets(
    'unavailable (erreur réseau) — affiche le message neutre mais NE déclenche PAS de réinvalidation',
    (tester) async {
      final controller = StreamController<List<WorkEntry>>();
      final fakePortalRepo = await _pump(tester, controller);
      expect(fakePortalRepo.getPortalCallCount, 1);

      controller.addError(FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
      await tester.pumpAndSettle();

      expect(
        fakePortalRepo.getPortalCallCount,
        1,
        reason: 'une erreur réseau sur CE flux ne doit jamais rebasculer vers artisan',
      );
      expect(find.textContaining('unavailable'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);

      await controller.close();
    },
  );
}
