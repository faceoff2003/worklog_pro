// Caractérisation de ClientPortalProvisioningService — le séquencement des
// 3 étapes (compte Auth, profil clientPortals, lien Client.portalUid) + une
// 4e (email d'accès), et leur compensation, validée avec William avant
// d'écrire ce test :
// - étape 1 : compensable (suppression du compte, null-safe, un seul retry).
//   invalidEmail et emailAlreadyInUse sont deux issues dédiées, jamais
//   confondues avec une panne générique.
// - étape 2 : NON compensable (clientPortals n'a pas de allow delete) — un
//   échec ici compense l'étape 1, jamais l'inverse.
// - étape 3 : non bloquante — un échec ne compense rien, le balayage de
//   réconciliation répare au prochain lancement.
// - étape 4 (email d'accès) : envoyée que l'étape 3 ait réussi ou non ;
//   remplace l'issue de l'étape 3 par inviteEmailFailed si ELLE échoue.
// - dispose() de l'app secondaire : en finally sur TOUTE la séquence,
//   jamais avant — sinon la compensation de l'étape 2 n'aurait plus de
//   session à supprimer.
// - le mot de passe généré ne doit JAMAIS apparaître nulle part hors de
//   l'appel à createAccount() — ni dans le résultat, ni via print().

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_provisioning_service.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

class _FakeProvisioner implements PortalAccountProvisioner {
  Object? throwOnCreateAccount;
  String uidToReturn = 'new-portal-uid';

  /// Capture ce qui a réellement été transmis — c'est ce qui permet de
  /// prouver, dans les tests, que ce mot de passe ne fuit nulle part
  /// ailleurs (voir le groupe dédié plus bas).
  String? lastPasswordUsed;

  /// Nombre de tentatives de deleteJustCreatedAccount() qui doivent échouer
  /// avant qu'une tentative ne réussisse enfin (0 = réussit du premier coup).
  int deleteFailuresBeforeSuccess = 0;
  int deleteAttemptCount = 0;
  int disposeCallCount = 0;

  @override
  Future<String> createAccount({required String email, required String password}) async {
    lastPasswordUsed = password;
    if (throwOnCreateAccount != null) throw throwOnCreateAccount!;
    return uidToReturn;
  }

  @override
  Future<void> deleteJustCreatedAccount() async {
    deleteAttemptCount++;
    if (deleteAttemptCount <= deleteFailuresBeforeSuccess) {
      throw Exception('échec suppression compte');
    }
  }

  @override
  Future<void> dispose() async {
    disposeCallCount++;
  }
}

class _FakeClientPortalRepository implements ClientPortalRepository {
  Object? throwOnCreatePortal;
  int createPortalCallCount = 0;
  String? lastCreatedPortalUid;

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) async {
    if (throwOnCreatePortal != null) throw throwOnCreatePortal!;
    createPortalCallCount++;
    lastCreatedPortalUid = portalUid;
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
  Future<BackfillOutcome?> getBackfillStatus(String portalUid, String artisanUid) => throw UnimplementedError();
}

class _FakeClientRepository implements ClientRepository {
  final Map<String, Client> clients;
  Object? throwOnUpdateClient;
  final List<Client> updatedClients = [];

  _FakeClientRepository(this.clients);

  @override
  Future<Client?> getClient(String clientId) async => clients[clientId];

  @override
  Future<void> updateClient(Client client) async {
    if (throwOnUpdateClient != null) throw throwOnUpdateClient!;
    updatedClients.add(client);
    clients[client.id] = client;
  }

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
  String? lastEmail;

  @override
  Future<void> sendInvite({required String email}) async {
    sendInviteCallCount++;
    lastEmail = email;
    if (throwOnSendInvite != null) throw throwOnSendInvite!;
  }
}

Client _client({required String id, String? portalUid}) => Client(
      id: id,
      name: 'Jean Dupont',
      type: ClientType.patron,
      defaultRates: const DefaultRates(),
      tags: const [],
      portalUid: portalUid,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeProvisioner provisioner;
  late _FakeClientPortalRepository portalRepository;
  late _FakeClientRepository clientRepository;
  late _FakeInviteEmailSender inviteEmailSender;
  late ClientPortalProvisioningService service;

  setUp(() {
    provisioner = _FakeProvisioner();
    portalRepository = _FakeClientPortalRepository();
    clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
    inviteEmailSender = _FakeInviteEmailSender();
    service = ClientPortalProvisioningService(
      provisionerFactory: () => provisioner,
      clientPortalRepository: portalRepository,
      clientRepository: clientRepository,
      inviteEmailSender: inviteEmailSender,
    );
  });

  Future<ClientPortalProvisioningResult> run() => service.createPortalAccount(
        artisanUid: 'artisan-1',
        clientId: 'client-1',
        email: 'client@example.com',
      );

  group('chemin heureux', () {
    test(
      'les 3 étapes + l\'envoi de l\'email réussissent → success, Client.portalUid lié, '
      'email envoyé, dispose() appelé une fois',
      () async {
        final result = await run();

        expect(result.outcome, ClientPortalProvisioningOutcome.success);
        expect(result.portalUid, 'new-portal-uid');
        expect(clientRepository.clients['client-1']!.portalUid, 'new-portal-uid');
        expect(inviteEmailSender.sendInviteCallCount, 1);
        expect(inviteEmailSender.lastEmail, 'client@example.com');
        expect(provisioner.disposeCallCount, 1);
      },
    );
  });

  group('étape 1 — email déjà utilisé', () {
    test('chemin explicite, aucun profil créé, aucun email envoyé, dispose() quand même appelé', () async {
      provisioner.throwOnCreateAccount = const PortalEmailAlreadyInUseException();

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.emailAlreadyInUse);
      expect(portalRepository.createPortalCallCount, 0);
      expect(provisioner.deleteAttemptCount, 0); // pas de compte créé, rien à compenser
      expect(inviteEmailSender.sendInviteCallCount, 0);
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('étape 1 — email invalide', () {
    test('issue DÉDIÉE, pas confondue avec authCreationFailed — le plus fréquent après emailAlreadyInUse', () async {
      provisioner.throwOnCreateAccount = const PortalInvalidEmailException();

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.invalidEmail);
      expect(portalRepository.createPortalCallCount, 0);
      expect(inviteEmailSender.sendInviteCallCount, 0);
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('étape 1 — autre échec', () {
    test('surfacé tel quel, aucune compensation, dispose() quand même appelé', () async {
      provisioner.throwOnCreateAccount = Exception('réseau indisponible');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.authCreationFailed);
      expect(portalRepository.createPortalCallCount, 0);
      expect(provisioner.deleteAttemptCount, 0);
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('étape 2 échoue — compensation de l\'étape 1', () {
    test('suppression réussie du premier coup → profileCreationFailedAndCompensated, portalUid absent du résultat', () async {
      portalRepository.throwOnCreatePortal = Exception('permission-denied');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.profileCreationFailedAndCompensated);
      expect(result.portalUid, isNull); // compensé : rien à signaler pour un nettoyage manuel
      expect(provisioner.deleteAttemptCount, 1);
      expect(clientRepository.updatedClients, isEmpty); // étape 3 jamais atteinte
      expect(inviteEmailSender.sendInviteCallCount, 0); // étape 4 jamais atteinte non plus
      expect(provisioner.disposeCallCount, 1);
    });

    test('échoue une fois puis réussit au retry → toujours compensé (un seul retry suffit)', () async {
      portalRepository.throwOnCreatePortal = Exception('permission-denied');
      provisioner.deleteFailuresBeforeSuccess = 1;

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.profileCreationFailedAndCompensated);
      expect(provisioner.deleteAttemptCount, 2); // 1 échec + 1 réussite = 2 tentatives, jamais 3
    });

    test('échoue deux fois de suite (le retry aussi) → profileCreationFailedOrphaned, portalUid ET email fournis', () async {
      portalRepository.throwOnCreatePortal = Exception('permission-denied');
      provisioner.deleteFailuresBeforeSuccess = 2; // échoue aux 2 tentatives disponibles

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.profileCreationFailedOrphaned);
      expect(result.portalUid, 'new-portal-uid'); // nécessaire pour le nettoyage manuel
      expect(result.email, 'client@example.com');
      expect(provisioner.deleteAttemptCount, 2); // jamais un 3e essai
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('étape 3 échoue — non bloquant, pas de compensation en cascade, email envoyé quand même', () {
    test('updateClient échoue → linkPendingAutomaticRepair, email envoyé quand même, pas de suppression compte/profil', () async {
      clientRepository.throwOnUpdateClient = Exception('réseau indisponible');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.linkPendingAutomaticRepair);
      expect(result.portalUid, 'new-portal-uid');
      expect(portalRepository.createPortalCallCount, 1); // le profil créé à l'étape 2 reste en place
      expect(provisioner.deleteAttemptCount, 0); // jamais de compensation en cascade depuis l'étape 3
      expect(inviteEmailSender.sendInviteCallCount, 1); // envoyé MALGRÉ l'échec de l'étape 3
      expect(provisioner.disposeCallCount, 1);
    });

    test('le Client a disparu entre-temps (getClient renvoie null) → même issue non bloquante, email envoyé quand même', () async {
      clientRepository.clients.remove('client-1');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.linkPendingAutomaticRepair);
      expect(provisioner.deleteAttemptCount, 0);
      expect(inviteEmailSender.sendInviteCallCount, 1);
    });
  });

  group('étape 4 (email d\'accès) échoue — remplace l\'issue de l\'étape 3, quelle qu\'elle soit', () {
    test('étape 3 aurait réussi (success) mais l\'email échoue → inviteEmailFailed, PAS success', () async {
      inviteEmailSender.throwOnSendInvite = Exception('service email indisponible');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.inviteEmailFailed);
      expect(result.portalUid, 'new-portal-uid'); // nécessaire pour proposer un renvoi
      expect(result.email, 'client@example.com');
      expect(clientRepository.clients['client-1']!.portalUid, 'new-portal-uid'); // le lien, lui, a bien été fait
      expect(provisioner.disposeCallCount, 1);
    });

    test('étape 3 avait déjà échoué (linkPendingAutomaticRepair) ET l\'email échoue → inviteEmailFailed prime', () async {
      clientRepository.throwOnUpdateClient = Exception('réseau indisponible');
      inviteEmailSender.throwOnSendInvite = Exception('service email indisponible');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.inviteEmailFailed);
      expect(result.portalUid, 'new-portal-uid');
    });
  });

  group('resendInvite — renvoi indépendant, sans repasser par toute la séquence', () {
    test('réussit → true, aucune interaction avec le provisioner ni les repositories', () async {
      final sent = await service.resendInvite(email: 'client@example.com');

      expect(sent, isTrue);
      expect(inviteEmailSender.sendInviteCallCount, 1);
      expect(inviteEmailSender.lastEmail, 'client@example.com');
      expect(provisioner.disposeCallCount, 0); // aucune séquence de création déclenchée
    });

    test('échoue → false, jamais d\'exception relancée à l\'appelant', () async {
      inviteEmailSender.throwOnSendInvite = Exception('service email indisponible');

      final sent = await service.resendInvite(email: 'client@example.com');

      expect(sent, isFalse);
    });
  });

  group('dispose() en finally sur TOUTE la séquence, jamais avant', () {
    test('appelé exactement une fois sur le chemin heureux', () async {
      expect((await run()).outcome, ClientPortalProvisioningOutcome.success);
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('le mot de passe généré ne fuit nulle part', () {
    test(
      'n\'apparaît ni dans le résultat retourné, ni dans le profil écrit, ni via print() — '
      'casse si quelqu\'un l\'ajoute plus tard "pour debug"',
      () async {
        final printedLines = <String>[];

        final result = await runZoned<Future<ClientPortalProvisioningResult>>(
          () => run(),
          zoneSpecification: ZoneSpecification(
            print: (self, parent, zone, line) => printedLines.add(line),
          ),
        );

        final password = provisioner.lastPasswordUsed;
        expect(password, isNotNull);
        expect(password!.length, greaterThanOrEqualTo(20)); // mot de passe fort, pas un placeholder court

        // Ni dans le résultat retourné à l'appelant...
        expect(result.outcome.toString(), isNot(contains(password)));
        expect(result.portalUid, isNot(password));
        expect(result.email, isNot(password));

        // ...ni dans les données écrites dans le profil clientPortals...
        expect(portalRepository.lastCreatedPortalUid, isNot(password));

        // ...ni dans quoi que ce soit imprimé pendant toute la séquence.
        expect(
          printedLines.any((line) => line.contains(password)),
          isFalse,
          reason: 'Le mot de passe généré est apparu dans une sortie print() : $printedLines',
        );
      },
    );

    test('deux appels consécutifs génèrent deux mots de passe différents (vraie source aléatoire, pas un placeholder fixe)', () async {
      await run();
      final first = provisioner.lastPasswordUsed;

      clientRepository.clients['client-2'] = _client(id: 'client-2', portalUid: null);
      await service.createPortalAccount(artisanUid: 'artisan-1', clientId: 'client-2', email: 'autre@example.com');
      final second = provisioner.lastPasswordUsed;

      expect(first, isNot(second));
    });
  });
}
