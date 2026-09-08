// C-PORTAL.6 — écran de création de portail. Aucun mock : mêmes fakes que
// client_portal_provisioning_service_test.dart (dupliqués ici, privés au
// fichier, même convention que work_entry_form_page_test.dart) mais montés
// sous ProviderScope avec CHAQUE collaborateur overridé séparément, pour
// prouver le câblage UI — pas la logique de service, déjà prouvée ailleurs.
//
// Ce fichier ne re-prouve donc PAS le séquencement des 4 étapes (déjà fait),
// seulement : un texte distinct par issue, les deux cas orphelins en dialog
// persistant avec email/uid copiables, et le garde anti-double-tap.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/create_portal_dialog.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

class _FakeProvisioner implements PortalAccountProvisioner {
  Object? throwOnCreateAccount;
  String uidToReturn = 'new-portal-uid';
  Completer<String>? hangOnCreateAccount;
  int createAccountCallCount = 0;
  int deleteFailuresBeforeSuccess = 0;
  int _deleteAttemptCount = 0;

  @override
  Future<String> createAccount({required String email, required String password}) {
    createAccountCallCount++;
    if (hangOnCreateAccount != null) return hangOnCreateAccount!.future;
    if (throwOnCreateAccount != null) return Future.error(throwOnCreateAccount!);
    return Future.value(uidToReturn);
  }

  @override
  Future<void> deleteJustCreatedAccount() async {
    _deleteAttemptCount++;
    if (_deleteAttemptCount <= deleteFailuresBeforeSuccess) {
      throw Exception('échec suppression compte');
    }
  }

  @override
  Future<void> dispose() async {}
}

class _FakeClientPortalRepository implements ClientPortalRepository {
  Object? throwOnCreatePortal;

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) async {
    if (throwOnCreatePortal != null) throw throwOnCreatePortal!;
  }

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
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) => throw UnimplementedError();
  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) => throw UnimplementedError();
  @override
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome) => throw UnimplementedError();
  @override
  Future<BackfillOutcome?> getBackfillStatus(String portalUid) => throw UnimplementedError();
}

class _FakeClientRepository implements ClientRepository {
  final Map<String, Client> clients;
  _FakeClientRepository(this.clients);

  @override
  Future<Client?> getClient(String clientId) async => clients[clientId];
  @override
  Future<void> updateClient(Client client) async => clients[client.id] = client;

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

class _FakeInviteEmailSender implements PortalInviteEmailSender {
  Object? throwOnSendInvite;
  int sendInviteCallCount = 0;

  @override
  Future<void> sendInvite({required String email}) async {
    sendInviteCallCount++;
    if (throwOnSendInvite != null) throw throwOnSendInvite!;
  }
}

Client _testClient() => Client(
      id: 'client-1',
      name: 'Jean Dupont',
      email: 'jean@example.com',
      type: ClientType.patron,
      defaultRates: const DefaultRates(),
      tags: const [],
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

class _Fakes {
  final provisioner = _FakeProvisioner();
  final portalRepository = _FakeClientPortalRepository();
  late final _FakeClientRepository clientRepository;
  final inviteEmailSender = _FakeInviteEmailSender();

  _Fakes({Map<String, Client>? clients}) {
    clientRepository = _FakeClientRepository(clients ?? {'client-1': _testClient()});
  }
}

Future<_Fakes> _pumpDialog(WidgetTester tester, {Client? client, _Fakes? fakes}) async {
  final f = fakes ?? _Fakes();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(
          AppUser(uid: 'artisan-1', email: 'artisan@example.com', createdAt: DateTime(2026, 1, 1)),
        ),
        portalAccountProvisionerFactoryProvider.overrideWithValue(() => f.provisioner),
        clientPortalRepositoryProvider.overrideWithValue(f.portalRepository),
        clientRepositoryProvider.overrideWithValue(f.clientRepository),
        portalInviteEmailSenderProvider.overrideWithValue(f.inviteEmailSender),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showCreatePortalDialog(context: context, ref: ref, client: client ?? _testClient()),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('ouvrir'));
  await tester.pumpAndSettle();
  return f;
}

void main() {
  testWidgets('succès — email envoyé, dialog fermé, SnackBar verte', (tester) async {
    await _pumpDialog(tester);
    await tester.tap(find.text('Créer le portail'));
    await tester.pumpAndSettle();

    expect(find.text('Créer un accès portail'), findsNothing);
    expect(find.text('Portail créé pour jean@example.com. Email d\'accès envoyé.'), findsOneWidget);
  });

  testWidgets(
    'emailAlreadyInUse — message ré-orienté vers le renvoi, pas vers un changement d\'email, '
    'avec une action "Renvoyer l\'email" qui déclenche vraiment resendInvite',
    (tester) async {
      final fakes = _Fakes();
      fakes.provisioner.throwOnCreateAccount = const PortalEmailAlreadyInUseException();
      await _pumpDialog(tester, fakes: fakes);
      await tester.tap(find.text('Créer le portail'));
      await tester.pumpAndSettle();

      expect(
        find.text('Un compte existe déjà pour jean@example.com — c\'est probablement déjà le portail de ce client.'),
        findsOneWidget,
      );
      expect(find.text('Renvoyer l\'email'), findsOneWidget);

      await tester.tap(find.text('Renvoyer l\'email'));
      await tester.pumpAndSettle();
      expect(fakes.inviteEmailSender.sendInviteCallCount, 1);
    },
  );

  testWidgets('invalidEmail — message dédié', (tester) async {
    final fakes = _Fakes();
    fakes.provisioner.throwOnCreateAccount = const PortalInvalidEmailException();
    await _pumpDialog(tester, fakes: fakes);
    await tester.tap(find.text('Créer le portail'));
    await tester.pumpAndSettle();

    expect(find.text('Adresse email invalide.'), findsOneWidget);
  });

  testWidgets(
    'authCreationFailed — message générique distinct des deux précédents, avec le code technique brut '
    '(deux causes différentes ne doivent pas produire le même texte)',
    (tester) async {
      final fakes = _Fakes();
      fakes.provisioner.throwOnCreateAccount =
          FirebaseException(plugin: 'firebase_auth', code: 'network-request-failed');
      await _pumpDialog(tester, fakes: fakes);
      await tester.tap(find.text('Créer le portail'));
      await tester.pumpAndSettle();

      expect(find.text('Échec de la création du compte. Réessayez. (network-request-failed)'), findsOneWidget);
    },
  );

  testWidgets(
    'profileCreationFailedAndCompensated — dit que le compte a été supprimé, jamais qu\'il n\'a pas été créé, '
    'avec le code technique brut',
    (tester) async {
      final fakes = _Fakes();
      fakes.portalRepository.throwOnCreatePortal =
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      await _pumpDialog(tester, fakes: fakes);
      await tester.tap(find.text('Créer le portail'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Échec après création du compte — le compte créé a été supprimé automatiquement. '
          'Vous pouvez réessayer. (permission-denied)',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'profileCreationFailedOrphaned — dialog persistant (pas de SnackBar), email, uid ET code technique affichés et copiables',
    (tester) async {
      final fakes = _Fakes();
      fakes.portalRepository.throwOnCreatePortal =
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      fakes.provisioner.deleteFailuresBeforeSuccess = 2; // les 2 tentatives échouent
      await _pumpDialog(tester, fakes: fakes);
      await tester.tap(find.text('Créer le portail'));
      await tester.pumpAndSettle();

      expect(find.text('Intervention manuelle nécessaire'), findsOneWidget);
      expect(find.text('jean@example.com'), findsOneWidget);
      expect(find.text('new-portal-uid'), findsOneWidget);
      expect(find.text('permission-denied'), findsOneWidget);
      expect(find.byIcon(Icons.copy), findsNWidgets(3));

      // Le dialog reste ouvert tant qu'on ne le ferme pas explicitement.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('Intervention manuelle nécessaire'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.copy).first);
      await tester.pump();
      expect(find.text('Email copié'), findsOneWidget);

      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(find.text('Intervention manuelle nécessaire'), findsNothing);
    },
  );

  testWidgets(
    'inviteEmailFailed — même traitement persistant que profileCreationFailedOrphaned, avec le code technique',
    (tester) async {
      final fakes = _Fakes();
      fakes.inviteEmailSender.throwOnSendInvite = FirebaseException(plugin: 'firebase_auth', code: 'too-many-requests');
      await _pumpDialog(tester, fakes: fakes);
      await tester.tap(find.text('Créer le portail'));
      await tester.pumpAndSettle();

      expect(find.text('Intervention manuelle nécessaire'), findsOneWidget);
      expect(find.text('jean@example.com'), findsOneWidget);
      expect(find.text('new-portal-uid'), findsOneWidget);
      expect(find.text('too-many-requests'), findsOneWidget);
    },
  );

  testWidgets('linkPendingAutomaticRepair — non traité comme un échec (ambre), email envoyé quand même', (tester) async {
    final fakes = _Fakes(clients: {}); // getClient(clientId) renvoie null → étape 3 non bloquante
    await _pumpDialog(tester, fakes: fakes);
    await tester.tap(find.text('Créer le portail'));
    await tester.pumpAndSettle();

    expect(
      find.text('Portail créé, email envoyé. Le lien sera réparé automatiquement au prochain lancement.'),
      findsOneWidget,
    );
    expect(fakes.inviteEmailSender.sendInviteCallCount, 1);
  });

  testWidgets(
    'double-tap — deux taps avant tout rebuild ne déclenchent qu\'un seul appel réel',
    (tester) async {
      final fakes = _Fakes();
      fakes.provisioner.hangOnCreateAccount = Completer<String>();
      await _pumpDialog(tester, fakes: fakes);

      await tester.tap(find.text('Créer le portail'));
      await tester.tap(find.text('Créer le portail'));
      await tester.pump();

      expect(fakes.provisioner.createAccountCallCount, 1);
    },
  );
}
