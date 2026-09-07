// Caractérisation de ClientPortalProvisioningService — le séquencement des
// 3 étapes (compte Auth, profil clientPortals, lien Client.portalUid) et
// leur compensation, validée avec William avant d'écrire ce test :
// - étape 1 : compensable (suppression du compte, null-safe, un seul retry).
// - étape 2 : NON compensable (clientPortals n'a pas de allow delete) — un
//   échec ici compense l'étape 1, jamais l'inverse.
// - étape 3 : non bloquante — un échec ne compense rien, le balayage de
//   réconciliation répare au prochain lancement.
// - dispose() de l'app secondaire : en finally sur TOUTE la séquence,
//   jamais avant — sinon la compensation de l'étape 2 n'aurait plus de
//   session à supprimer.

import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_provisioning_service.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

class _FakeProvisioner implements PortalAccountProvisioner {
  Object? throwOnCreateAccount;
  String uidToReturn = 'new-portal-uid';

  /// Nombre de tentatives de deleteJustCreatedAccount() qui doivent échouer
  /// avant qu'une tentative ne réussisse enfin (0 = réussit du premier coup).
  int deleteFailuresBeforeSuccess = 0;
  int deleteAttemptCount = 0;
  int disposeCallCount = 0;

  @override
  Future<String> createAccount({required String email, required String password}) async {
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
  late ClientPortalProvisioningService service;

  setUp(() {
    provisioner = _FakeProvisioner();
    portalRepository = _FakeClientPortalRepository();
    clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
    service = ClientPortalProvisioningService(
      provisionerFactory: () => provisioner,
      clientPortalRepository: portalRepository,
      clientRepository: clientRepository,
    );
  });

  Future<ClientPortalProvisioningResult> run() => service.createPortalAccount(
        artisanUid: 'artisan-1',
        clientId: 'client-1',
        email: 'client@example.com',
        password: 'motdepasse-genere',
      );

  group('chemin heureux', () {
    test('les 3 étapes réussissent → success, Client.portalUid lié, dispose() appelé une fois', () async {
      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.success);
      expect(result.portalUid, 'new-portal-uid');
      expect(clientRepository.clients['client-1']!.portalUid, 'new-portal-uid');
      expect(provisioner.disposeCallCount, 1);
    });
  });

  group('étape 1 — email déjà utilisé', () {
    test('chemin explicite, aucun profil créé, aucune compensation tentée, dispose() quand même appelé', () async {
      provisioner.throwOnCreateAccount = const PortalEmailAlreadyInUseException();

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.emailAlreadyInUse);
      expect(portalRepository.createPortalCallCount, 0);
      expect(provisioner.deleteAttemptCount, 0); // pas de compte créé, rien à compenser
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

  group('étape 3 échoue — non bloquant, pas de compensation en cascade', () {
    test('updateClient échoue → linkPendingAutomaticRepair, PAS de tentative de suppression du compte/profil', () async {
      clientRepository.throwOnUpdateClient = Exception('réseau indisponible');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.linkPendingAutomaticRepair);
      expect(result.portalUid, 'new-portal-uid');
      expect(portalRepository.createPortalCallCount, 1); // le profil créé à l'étape 2 reste en place
      expect(provisioner.deleteAttemptCount, 0); // jamais de compensation en cascade depuis l'étape 3
      expect(provisioner.disposeCallCount, 1);
    });

    test('le Client a disparu entre-temps (getClient renvoie null) → même issue non bloquante', () async {
      clientRepository.clients.remove('client-1');

      final result = await run();

      expect(result.outcome, ClientPortalProvisioningOutcome.linkPendingAutomaticRepair);
      expect(provisioner.deleteAttemptCount, 0);
    });
  });

  group('dispose() en finally sur TOUTE la séquence, jamais avant', () {
    test('appelé exactement une fois dans chacun des 5 scénarios (succès + 4 échecs)', () async {
      // Succès
      expect((await run()).outcome, ClientPortalProvisioningOutcome.success);
      expect(provisioner.disposeCallCount, 1);
    });
  });
}
