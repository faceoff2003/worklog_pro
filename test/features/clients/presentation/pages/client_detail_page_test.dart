// C-PORTAL.6 — section "Portail client" de ClientDetailPage : état affiché
// (a un portail / n'en a pas), garde de validation de l'email AVANT
// ouverture du dialog (contrainte UI, jamais sur l'entité), et le bouton
// "Renvoyer l'email d'accès" (succès/échec/garde anti-double-tap).
//
// clientBalanceProvider est overridé directement en AsyncValue.data(...) :
// cette page n'a rien à voir avec le calcul de balance, pas besoin de
// remonter workEntries/expenses/payments/settlement pour ce test.
//
// La section est loin dans une ListView à enfants fixes : les slivers ne
// construisent que les enfants dans le viewport + cache extent, donc rien
// dans _PortalSection n'existe encore tant qu'on n'a pas scrollé jusqu'à
// elle (repéré via sa Key, dragUntilVisible gère le "pas encore construit").

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_detail_page.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class _FakeInviteEmailSender implements PortalInviteEmailSender {
  Object? throwOnSendInvite;
  Completer<void>? hang;
  int sendInviteCallCount = 0;
  String? lastEmail;

  @override
  Future<void> sendInvite({required String email}) {
    sendInviteCallCount++;
    lastEmail = email;
    if (hang != null) return hang!.future;
    if (throwOnSendInvite != null) return Future.error(throwOnSendInvite!);
    return Future.value();
  }
}

/// resendInvite() ne touche jamais ces trois collaborateurs — mais
/// ClientPortalProvisioningService les prend tous en construction, donc le
/// provider doit pouvoir les résoudre sans Firebase réel dès que
/// portalInviteResendControllerProvider est construit (client avec portail).
class _UnusedProvisioner implements PortalAccountProvisioner {
  @override
  Future<String> createAccount({required String email, required String password}) => throw UnimplementedError();
  @override
  Future<void> deleteJustCreatedAccount() => throw UnimplementedError();
  @override
  Future<void> dispose() => throw UnimplementedError();
}

/// Plus vraiment "Unused" depuis C-PORTAL.9 étape 3 : mirrorWorkEntriesBatch/
/// mirrorExpensesBatch/saveBackfillStatus/getBackfillStatus sont réellement
/// exercées par l'indicateur persistant et le bouton "Reprendre l'historique"
/// — gardé sous ce nom pour ses AUTRES méthodes (createPortal, getPortal...)
/// qui, elles, restent hors du périmètre de cette page.
class _UnusedClientPortalRepository implements ClientPortalRepository {
  /// null par défaut = "jamais lancé" (ex. le portail BGS, créé avant
  /// C-PORTAL.9) — c'est délibérément le défaut de CE fake : ça exerce le
  /// cas que William a explicitement demandé de garder visible.
  BackfillOutcome? backfillStatusToReturn;
  Object? throwOnGetBackfillStatus;
  int mirrorWorkEntriesBatchCallCount = 0;
  int mirrorExpensesBatchCallCount = 0;
  BackfillOutcome? lastSavedBackfillStatus;

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) =>
      throw UnimplementedError();
  @override
  Future<ClientPortal?> getPortal(String portalUid) => throw UnimplementedError();
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
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) async {
    mirrorWorkEntriesBatchCallCount++;
  }

  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) async {
    mirrorExpensesBatchCallCount++;
  }

  @override
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome) async {
    lastSavedBackfillStatus = outcome;
  }

  @override
  Future<BackfillOutcome?> getBackfillStatus(String portalUid, String artisanUid) async {
    if (throwOnGetBackfillStatus != null) throw throwOnGetBackfillStatus!;
    return backfillStatusToReturn;
  }
}

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

class _UnusedClientRepository implements ClientRepository {
  @override
  Future<Client?> getClient(String clientId) => throw UnimplementedError();
  @override
  Future<void> updateClient(Client client) => throw UnimplementedError();
  @override
  Future<Client> createClient(Client client) => throw UnimplementedError();
  @override
  Future<void> deleteClient(String clientId) => throw UnimplementedError();
  @override
  Future<List<Client>> getClients() => throw UnimplementedError();
  @override
  Future<List<Client>> searchClientsByName(String query) => throw UnimplementedError();
  @override
  Stream<Client?> watchClient(String clientId) => throw UnimplementedError();
  @override
  Stream<List<Client>> watchClients() => throw UnimplementedError();
}

Client _client({String? email, String? portalUid}) => Client(
      id: 'client-1',
      name: 'Jean Dupont',
      email: email,
      portalUid: portalUid,
      type: ClientType.patron,
      defaultRates: const DefaultRates(),
      tags: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Future<_FakeInviteEmailSender> _pumpPage(
  WidgetTester tester,
  Client client, {
  _FakeInviteEmailSender? inviteEmailSender,
  _UnusedClientPortalRepository? portalRepository,
  WorkEntryRepository? workEntryRepository,
  ExpenseRepository? expenseRepository,
}) async {
  final sender = inviteEmailSender ?? _FakeInviteEmailSender();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clientBalanceProvider(client.id).overrideWithValue(AsyncValue.data(ClientBalance.zero())),
        currentUserProvider.overrideWithValue(
          AppUser(uid: 'artisan-1', email: 'artisan@example.com', createdAt: DateTime(2026, 1, 1)),
        ),
        portalInviteEmailSenderProvider.overrideWithValue(sender),
        portalAccountProvisionerFactoryProvider.overrideWithValue(() => _UnusedProvisioner()),
        clientPortalRepositoryProvider.overrideWithValue(portalRepository ?? _UnusedClientPortalRepository()),
        clientRepositoryProvider.overrideWithValue(_UnusedClientRepository()),
        workEntryRepositoryProvider.overrideWithValue(workEntryRepository ?? _FakeWorkEntryRepository()),
        expenseRepositoryProvider.overrideWithValue(expenseRepository ?? _FakeExpenseRepository()),
      ],
      child: MaterialApp(home: ClientDetailPage(client: client)),
    ),
  );
  await tester.pumpAndSettle();

  await tester.dragUntilVisible(
    find.byKey(const ValueKey('portal_section')),
    find.byType(Scrollable),
    const Offset(0, -300),
  );
  await tester.pumpAndSettle();

  return sender;
}

void main() {
  testWidgets('pas de portail : bouton "Créer un accès portail" visible, pas de "Portail actif"', (tester) async {
    await _pumpPage(tester, _client(email: 'jean@example.com', portalUid: null));

    expect(find.text('Créer un accès portail'), findsOneWidget);
    expect(find.text('Portail actif'), findsNothing);
  });

  testWidgets(
    'email vide : le tap ne déclenche AUCUN provisioning, message clair, dialog jamais ouvert',
    (tester) async {
      await _pumpPage(tester, _client(email: null, portalUid: null));

      await tester.tap(find.text('Créer un accès portail'));
      await tester.pumpAndSettle();

      expect(find.text('Ajoutez un email au client avant de créer un portail.'), findsOneWidget);
      expect(find.text('Créer un portail'), findsNothing); // titre du bouton de confirmation du dialog
    },
  );

  testWidgets('email présent : le tap ouvre bien le dialog de création', (tester) async {
    await _pumpPage(tester, _client(email: 'jean@example.com', portalUid: null));

    await tester.tap(find.text('Créer un accès portail'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un accès portail'), findsWidgets); // bouton + titre du dialog
    expect(find.widgetWithText(FilledButton, 'Créer le portail'), findsOneWidget);
  });

  testWidgets('portail existant : "Portail actif" + bouton de renvoi, pas de bouton de création', (tester) async {
    await _pumpPage(tester, _client(email: 'jean@example.com', portalUid: 'portal-uid-1'));

    expect(find.text('Portail actif'), findsOneWidget);
    expect(find.text('Renvoyer l\'email d\'accès'), findsOneWidget);
    expect(find.text('Créer un accès portail'), findsNothing);
  });

  testWidgets('renvoi réussi : SnackBar verte avec l\'email', (tester) async {
    await _pumpPage(tester, _client(email: 'jean@example.com', portalUid: 'portal-uid-1'));

    await tester.tap(find.text('Renvoyer l\'email d\'accès'));
    await tester.pumpAndSettle();

    expect(find.text('Email d\'accès renvoyé à jean@example.com.'), findsOneWidget);
  });

  testWidgets('renvoi échoué : SnackBar rouge distincte du succès', (tester) async {
    final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
    await _pumpPage(tester, client, inviteEmailSender: _FakeInviteEmailSender()..throwOnSendInvite = Exception('boom'));

    await tester.tap(find.text('Renvoyer l\'email d\'accès'));
    await tester.pumpAndSettle();

    expect(find.text('Échec de l\'envoi. Réessayez.'), findsOneWidget);
  });

  testWidgets(
    'renvoi — double-tap : deux taps avant tout rebuild ne déclenchent qu\'un seul appel réel',
    (tester) async {
      final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
      final sender = _FakeInviteEmailSender()..hang = Completer<void>();
      await _pumpPage(tester, client, inviteEmailSender: sender);

      await tester.tap(find.text('Renvoyer l\'email d\'accès'));
      await tester.tap(find.text('Renvoyer l\'email d\'accès'));
      await tester.pump();

      expect(sender.sendInviteCallCount, 1);
    },
  );

  group('C-PORTAL.9 étape 3 — indicateur persistant + "Reprendre l\'historique"', () {
    testWidgets(
      'portail JAMAIS backfillé (ex. le portail BGS, créé avant C-PORTAL.9) → indicateur dédié ET '
      'le bouton "Reprendre l\'historique" reste visible (pas seulement quand incomplet)',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()..backfillStatusToReturn = null;
        await _pumpPage(tester, client, portalRepository: portalRepo);

        expect(find.text('Historique jamais repris pour ce client.'), findsOneWidget);
        expect(find.text('Reprendre l\'historique'), findsOneWidget);
      },
    );

    testWidgets(
      'backfill complet → les deux compteurs affichés SÉPARÉMENT, jamais un total agrégé',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()
          ..backfillStatusToReturn = const BackfillOutcome(
            totalWorkEntries: 20,
            mirroredWorkEntries: 20,
            totalExpenses: 5,
            mirroredExpenses: 5,
          );
        await _pumpPage(tester, client, portalRepository: portalRepo);

        expect(find.text('Historique à jour'), findsOneWidget);
        expect(find.text('Prestations : 20/20'), findsOneWidget);
        expect(find.text('Dépenses : 5/5'), findsOneWidget);
        expect(find.text('Reprendre l\'historique'), findsOneWidget, reason: 'toujours visible, même complet');
      },
    );

    testWidgets(
      'backfill incomplet → indicateur distinct, compteurs réels séparés (pas "complet" par erreur)',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()
          ..backfillStatusToReturn = const BackfillOutcome(
            totalWorkEntries: 20,
            mirroredWorkEntries: 3,
            totalExpenses: 5,
            mirroredExpenses: 5,
          );
        await _pumpPage(tester, client, portalRepository: portalRepo);

        expect(find.text('Historique incomplet'), findsOneWidget);
        expect(find.text('Prestations : 3/20'), findsOneWidget);
        expect(find.text('Dépenses : 5/5'), findsOneWidget);
      },
    );

    testWidgets(
      'tap "Reprendre l\'historique" avec un vrai historique → backfill exécuté, SnackBar avec les compteurs, '
      'indicateur persistant rafraîchi',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()..backfillStatusToReturn = null;
        final workEntryRepo = _FakeWorkEntryRepository()..entries = [_entry('e1'), _entry('e2')];
        await _pumpPage(tester, client, portalRepository: portalRepo, workEntryRepository: workEntryRepo);

        expect(find.text('Historique jamais repris pour ce client.'), findsOneWidget);

        await tester.tap(find.text('Reprendre l\'historique'));
        await tester.pumpAndSettle();

        expect(find.text('Historique repris : 2/2 prestations, 0/0 dépenses.'), findsOneWidget);
        // getBackfillStatus n'a jamais été reconfiguré manuellement : le
        // seul moyen que l'indicateur reflète le nouvel état est le
        // ref.invalidate déclenché par le listener après la reprise.
        expect(portalRepo.lastSavedBackfillStatus!.mirroredWorkEntries, 2);
      },
    );

    testWidgets(
      'tap "Reprendre l\'historique" SANS aucun historique → message "Aucun historique", pas de silence '
      '(question explicite de William)',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()..backfillStatusToReturn = null;
        await _pumpPage(tester, client, portalRepository: portalRepo);

        await tester.tap(find.text('Reprendre l\'historique'));
        await tester.pumpAndSettle();

        expect(
          find.text('Aucun historique à reprendre pour ce client (0 prestation, 0 dépense refacturable).'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'double-tap sur "Reprendre l\'historique" avant tout rebuild → un seul backfillHistory() réel',
      (tester) async {
        final client = _client(email: 'jean@example.com', portalUid: 'portal-uid-1');
        final portalRepo = _UnusedClientPortalRepository()..backfillStatusToReturn = null;
        final workEntryRepo = _HangingWorkEntryRepository();
        await _pumpPage(tester, client, portalRepository: portalRepo, workEntryRepository: workEntryRepo);

        await tester.tap(find.text('Reprendre l\'historique'));
        await tester.tap(find.text('Reprendre l\'historique'));
        await tester.pump();

        expect(workEntryRepo.callCount, 1);
      },
    );
  });
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

/// N'appelle jamais getWorkEntries() une 2e fois avant que le 1er appel ne
/// se résolve — sert à prouver la garde anti-double-tap sans dépendre d'un
/// timing précis (le Future du 1er appel ne se résout jamais pendant le test).
class _HangingWorkEntryRepository implements WorkEntryRepository {
  int callCount = 0;
  final Completer<List<WorkEntry>> _completer = Completer<List<WorkEntry>>();

  @override
  Future<List<WorkEntry>> getWorkEntries({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) {
    callCount++;
    return _completer.future;
  }

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
