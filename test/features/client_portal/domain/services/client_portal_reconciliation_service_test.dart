// Caractérisation du balayage de réparation (C-PORTAL.4, point B du
// diagnostic). Couvre exactement les règles confirmées :
// - Client.portalUid == null  → réparation automatique (écriture).
// - Client.portalUid != celui du profil → JAMAIS d'écriture auto, remonté
//   comme conflit.
// - Client introuvable (clientId ne résout plus) → remonté, jamais d'écriture.
// - Déjà correctement lié → no-op silencieux, pas un "conflit".
// - Une seule exécution par session (le balayage est mis en cache), pas à
//   chaque appel.
//
// Ne couvre PAS, et ne peut PAS couvrir, le cas A (compte Auth créé sans
// écriture de profil clientPortals) — voir le commentaire de classe du
// service : aucun document Firestore n'existe alors pour ce compte, ce
// balayage (comme tout autre mécanisme actuel) ne peut rien détecter.

import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_reconciliation_service.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

class _FakeClientRepository implements ClientRepository {
  final Map<String, Client> clients;
  final List<Client> updatedClients = [];

  _FakeClientRepository(this.clients);

  @override
  Future<Client?> getClient(String clientId) async => clients[clientId];

  @override
  Future<void> updateClient(Client client) async {
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

class _FakeClientPortalRepository implements ClientPortalRepository {
  List<ClientPortal> portals;
  int listCallCount = 0;
  int failNextCalls = 0;

  _FakeClientPortalRepository(this.portals);

  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) async {
    listCallCount++;
    if (failNextCalls > 0) {
      failNextCalls--;
      throw Exception('réseau indisponible');
    }
    return portals.where((p) => p.artisanUid == artisanUid).toList();
  }

  @override
  Future<ClientPortal?> getPortal(String portalUid) => throw UnimplementedError();
  @override
  Future<void> setEnabled(String portalUid, bool enabled) => throw UnimplementedError();
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
  @override
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) => throw UnimplementedError();
  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) => throw UnimplementedError();
}

ClientPortal _portal({required String portalUid, required String clientId, String artisanUid = 'artisan-1'}) =>
    ClientPortal(
      portalUid: portalUid,
      artisanUid: artisanUid,
      clientId: clientId,
      enabled: true,
      createdAt: DateTime(2026, 1, 1),
    );

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
  group('null → réparation automatique', () {
    test('Client.portalUid == null → mis à jour avec le portalUid trouvé', () async {
      final clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-1')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      final report = await service.reconcileOnce();

      expect(report.repairedCount, 1);
      expect(report.issues, isEmpty);
      expect(clientRepository.updatedClients.single.portalUid, 'portal-1');
    });
  });

  group('différent → jamais d\'écriture auto, remonté comme conflit', () {
    test('Client.portalUid pointe déjà vers un AUTRE portail → aucune écriture, conflit rapporté', () async {
      final clientRepository = _FakeClientRepository({
        'client-1': _client(id: 'client-1', portalUid: 'portal-ANCIEN'),
      });
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-NOUVEAU', clientId: 'client-1')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      final report = await service.reconcileOnce();

      expect(report.repairedCount, 0);
      expect(clientRepository.updatedClients, isEmpty); // AUCUNE écriture, jamais
      expect(report.issues, hasLength(1));
      expect(report.issues.single.type, ReconciliationIssueType.conflictingLink);
      expect(report.issues.single.portalUid, 'portal-NOUVEAU');
      expect(report.issues.single.clientId, 'client-1');
      expect(report.issues.single.conflictingPortalUid, 'portal-ANCIEN');
    });
  });

  group('déjà correctement lié → no-op silencieux', () {
    test('Client.portalUid == le portalUid du profil → aucune écriture, aucun conflit rapporté', () async {
      final clientRepository = _FakeClientRepository({
        'client-1': _client(id: 'client-1', portalUid: 'portal-1'),
      });
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-1')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      final report = await service.reconcileOnce();

      expect(report.repairedCount, 0);
      expect(report.issues, isEmpty);
      expect(clientRepository.updatedClients, isEmpty);
    });
  });

  group('client introuvable', () {
    test('clientId du profil ne résout plus vers aucun Client → remonté, jamais d\'écriture', () async {
      final clientRepository = _FakeClientRepository({});
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-disparu')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      final report = await service.reconcileOnce();

      expect(report.repairedCount, 0);
      expect(clientRepository.updatedClients, isEmpty);
      expect(report.issues, hasLength(1));
      expect(report.issues.single.type, ReconciliationIssueType.clientNotFound);
      expect(report.issues.single.clientId, 'client-disparu');
    });
  });

  group('plusieurs portails mêlés — rapport agrégé correct', () {
    test('un réparé, un conflit, un déjà lié, un client introuvable', () async {
      final clientRepository = _FakeClientRepository({
        'client-a': _client(id: 'client-a', portalUid: null),
        'client-b': _client(id: 'client-b', portalUid: 'portal-ANCIEN'),
        'client-c': _client(id: 'client-c', portalUid: 'portal-c'),
      });
      final portalRepository = _FakeClientPortalRepository([
        _portal(portalUid: 'portal-a', clientId: 'client-a'),
        _portal(portalUid: 'portal-b', clientId: 'client-b'),
        _portal(portalUid: 'portal-c', clientId: 'client-c'),
        _portal(portalUid: 'portal-d', clientId: 'client-disparu'),
      ]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      final report = await service.reconcileOnce();

      expect(report.repairedCount, 1);
      expect(clientRepository.updatedClients.single.id, 'client-a');
      expect(report.issues, hasLength(2));
      expect(report.issues.map((i) => i.type), containsAll([
        ReconciliationIssueType.conflictingLink,
        ReconciliationIssueType.clientNotFound,
      ]));
    });
  });

  group('une seule exécution par session', () {
    test('deux appels à reconcileOnce() ne déclenchent qu\'un seul listPortalsForArtisan()', () async {
      final clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-1')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      await service.reconcileOnce();
      final secondReport = await service.reconcileOnce();

      expect(portalRepository.listCallCount, 1);
      // Le 2e appel renvoie le MÊME rapport mis en cache, pas un nouveau
      // balayage — donc toujours repairedCount == 1 de la 1re exécution,
      // pas ré-exécuté (ce qui aurait donné 0 la 2e fois, déjà lié).
      expect(secondReport.repairedCount, 1);
    });
  });

  group('un échec n\'est jamais mis en cache — retente au prochain appel', () {
    test('1er appel échoue (pas de réseau) → 2e appel retente réellement et peut réussir', () async {
      final clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-1')])
        ..failNextCalls = 1;
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      await expectLater(service.reconcileOnce(), throwsException);

      final report = await service.reconcileOnce();

      expect(portalRepository.listCallCount, 2); // vraiment retenté, pas juste rejoué depuis un cache
      expect(report.repairedCount, 1);
    });

    test('un succès, lui, reste bien mis en cache après coup (pas de sur-correction)', () async {
      final clientRepository = _FakeClientRepository({'client-1': _client(id: 'client-1', portalUid: null)});
      final portalRepository = _FakeClientPortalRepository([_portal(portalUid: 'portal-1', clientId: 'client-1')]);
      final service = ClientPortalReconciliationService(
        artisanUid: 'artisan-1',
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
      );

      await service.reconcileOnce();
      await service.reconcileOnce();

      expect(portalRepository.listCallCount, 1); // toujours mis en cache quand ça réussit
    });
  });
}
