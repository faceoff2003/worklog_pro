// Caractérisation de ClientPortalMirrorService — la logique QUOI/OÙ
// mirrorer, testée en isolation avec des fakes en mémoire pour
// ClientRepository et ClientPortalRepository (aucun Firestore réel, ce
// service ne fait que les coordonner). Couvre explicitement les trois
// comportements demandés : une prestation créée apparaît dans le miroir,
// une prestation modifiée le met à jour, une dépense isBillable == false
// n'apparaît jamais — plus le caractère best-effort (jamais bloquant).

import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_mirror_service.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

class _FakeClientRepository implements ClientRepository {
  final Map<String, Client> clients;
  Object? throwOnGetClient;

  _FakeClientRepository(this.clients);

  @override
  Future<Client?> getClient(String clientId) async {
    if (throwOnGetClient != null) throw throwOnGetClient!;
    return clients[clientId];
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
  Future<void> updateClient(Client client) => throw UnimplementedError();
  @override
  Stream<Client?> watchClient(String clientId) => throw UnimplementedError();
  @override
  Stream<List<Client>> watchClients() => throw UnimplementedError();
}

class _FakeClientPortalRepository implements ClientPortalRepository {
  Object? throwOnMirrorWorkEntry;
  Object? throwOnDeleteMirroredWorkEntry;
  Object? throwOnDeleteMirroredExpense;

  int mirrorWorkEntryCallCount = 0;
  String? lastMirroredWorkEntryPortalUid;
  WorkEntry? lastMirroredWorkEntry;

  int deleteMirroredWorkEntryCallCount = 0;
  String? lastDeletedWorkEntryId;

  int mirrorExpenseCallCount = 0;
  Expense? lastMirroredExpense;

  int deleteMirroredExpenseCallCount = 0;
  String? lastDeletedExpenseId;

  @override
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry) async {
    if (throwOnMirrorWorkEntry != null) throw throwOnMirrorWorkEntry!;
    mirrorWorkEntryCallCount++;
    lastMirroredWorkEntryPortalUid = portalUid;
    lastMirroredWorkEntry = entry;
  }

  @override
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId) async {
    if (throwOnDeleteMirroredWorkEntry != null) throw throwOnDeleteMirroredWorkEntry!;
    deleteMirroredWorkEntryCallCount++;
    lastDeletedWorkEntryId = entryId;
  }

  @override
  Future<void> mirrorExpense(String portalUid, Expense expense) async {
    mirrorExpenseCallCount++;
    lastMirroredExpense = expense;
  }

  @override
  Future<void> deleteMirroredExpense(String portalUid, String expenseId) async {
    if (throwOnDeleteMirroredExpense != null) throw throwOnDeleteMirroredExpense!;
    deleteMirroredExpenseCallCount++;
    lastDeletedExpenseId = expenseId;
  }

  @override
  Future<ClientPortal?> getPortal(String portalUid) => throw UnimplementedError();
  @override
  Future<void> setEnabled(String portalUid, bool enabled) => throw UnimplementedError();
  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) => throw UnimplementedError();
  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) =>
      throw UnimplementedError();
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

WorkEntry _workEntry({required String id, required String clientId, int laborCents = 5000}) => WorkEntry(
      id: id,
      date: DateOnly.today(),
      startTime: 480,
      endTime: 600,
      durationMinutes: 120,
      clientId: clientId,
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(2500),
      laborAmountHT: Money.fromCents(laborCents),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Expense _expense({required String id, required String clientId, required bool isBillable}) => Expense(
      id: id,
      date: DateOnly.today(),
      clientId: clientId,
      category: ExpenseCategory.materials,
      amountHT: Money.fromCents(1000),
      description: 'Câble',
      isBillable: isBillable,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  late _FakeClientRepository clientRepository;
  late _FakeClientPortalRepository portalRepository;
  late ClientPortalMirrorService service;

  setUp(() {
    clientRepository = _FakeClientRepository({});
    portalRepository = _FakeClientPortalRepository();
    service = ClientPortalMirrorService(
      clientRepository: clientRepository,
      clientPortalRepository: portalRepository,
    );
  });

  group('mirrorWorkEntry — une prestation créée apparaît dans le miroir', () {
    test('client avec un portail lié → mirrorWorkEntry appelé avec le bon portalUid et la bonne entrée', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      final entry = _workEntry(id: 'entry-1', clientId: 'client-1');

      await service.mirrorWorkEntry(entry);

      expect(portalRepository.mirrorWorkEntryCallCount, 1);
      expect(portalRepository.lastMirroredWorkEntryPortalUid, 'portal-1');
      expect(portalRepository.lastMirroredWorkEntry, entry);
    });

    test('client sans portail (portalUid null) → jamais mirroré', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: null);

      await service.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-1'));

      expect(portalRepository.mirrorWorkEntryCallCount, 0);
    });

    test('client introuvable → jamais mirroré, aucune exception', () async {
      await service.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-inconnu'));

      expect(portalRepository.mirrorWorkEntryCallCount, 0);
    });
  });

  group('mirrorWorkEntry — une prestation modifiée met à jour le miroir', () {
    test('rappeler mirrorWorkEntry avec les champs modifiés transmet la version à jour', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      await service.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-1', laborCents: 5000));

      final updated = _workEntry(id: 'entry-1', clientId: 'client-1', laborCents: 9000);
      await service.mirrorWorkEntry(updated);

      expect(portalRepository.mirrorWorkEntryCallCount, 2);
      expect(portalRepository.lastMirroredWorkEntry!.laborAmountHT, Money.fromCents(9000));
    });
  });

  group('mirrorExpense — une dépense isBillable == false n\'apparaît jamais', () {
    test('isBillable true, client avec portail → mirrorExpense appelé, jamais delete', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');

      await service.mirrorExpense(_expense(id: 'exp-1', clientId: 'client-1', isBillable: true));

      expect(portalRepository.mirrorExpenseCallCount, 1);
      expect(portalRepository.deleteMirroredExpenseCallCount, 0);
    });

    test('isBillable false, client avec portail → retirée du miroir, jamais écrite', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');

      await service.mirrorExpense(_expense(id: 'exp-1', clientId: 'client-1', isBillable: false));

      expect(portalRepository.mirrorExpenseCallCount, 0);
      expect(portalRepository.deleteMirroredExpenseCallCount, 1);
      expect(portalRepository.lastDeletedExpenseId, 'exp-1');
    });

    test('isBillable false, client sans portail → rien du tout (pas de portail à nettoyer)', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: null);

      await service.mirrorExpense(_expense(id: 'exp-1', clientId: 'client-1', isBillable: false));

      expect(portalRepository.mirrorExpenseCallCount, 0);
      expect(portalRepository.deleteMirroredExpenseCallCount, 0);
    });
  });

  group('removeMirroredWorkEntry / removeMirroredExpense', () {
    test('portail lié → suppression transmise avec le bon entryId', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');

      await service.removeMirroredWorkEntry(clientId: 'client-1', entryId: 'entry-1');

      expect(portalRepository.deleteMirroredWorkEntryCallCount, 1);
      expect(portalRepository.lastDeletedWorkEntryId, 'entry-1');
    });

    test('pas de portail → suppression jamais transmise', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: null);

      await service.removeMirroredExpense(clientId: 'client-1', expenseId: 'exp-1');

      expect(portalRepository.deleteMirroredExpenseCallCount, 0);
    });
  });

  group('best-effort — jamais bloquant', () {
    test('le repository de miroir échoue → le service ne relance pas l\'exception', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnMirrorWorkEntry = Exception('réseau indisponible');

      await service.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-1'));
      // Si on arrive ici sans exception, le best-effort est respecté.
    });

    test('la lecture du client échoue (ex: permission-denied) → le service ne relance pas l\'exception', () async {
      clientRepository.throwOnGetClient = Exception('lecture refusée');

      await service.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-1'));
    });
  });

  group('ajout raté vs retrait raté — un retrait raté laisse une donnée exposée, un ajout raté non', () {
    late List<String> loggedFailures;
    late ClientPortalMirrorService serviceWithLogging;

    setUp(() {
      loggedFailures = [];
      serviceWithLogging = ClientPortalMirrorService(
        clientRepository: clientRepository,
        clientPortalRepository: portalRepository,
        logRemovalFailure: loggedFailures.add,
      );
    });

    test('mirrorWorkEntry (ajout) échoue → aucun log (silencieux, pas d\'exposition de donnée)', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnMirrorWorkEntry = Exception('réseau indisponible');

      await serviceWithLogging.mirrorWorkEntry(_workEntry(id: 'entry-1', clientId: 'client-1'));

      expect(loggedFailures, isEmpty);
    });

    test('removeMirroredWorkEntry échoue → loggé (le document supprimé reste visible côté client)', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnDeleteMirroredWorkEntry = Exception('réseau indisponible');

      await serviceWithLogging.removeMirroredWorkEntry(clientId: 'client-1', entryId: 'entry-1');

      expect(loggedFailures, hasLength(1));
      expect(loggedFailures.single, contains('entry-1'));
    });

    test(
      'mirrorExpense avec isBillable == false (donc un retrait) échoue → loggé, '
      'pas silencieux : c\'est une dépense non refacturable qui resterait visible',
      () async {
        clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
        portalRepository.throwOnDeleteMirroredExpense = Exception('réseau indisponible');

        await serviceWithLogging.mirrorExpense(_expense(id: 'exp-1', clientId: 'client-1', isBillable: false));

        expect(loggedFailures, hasLength(1));
        expect(loggedFailures.single, contains('exp-1'));
      },
    );

    test('mirrorExpense avec isBillable == true (un ajout) échoue → aucun log', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnDeleteMirroredExpense = Exception('ne doit pas être appelé de toute façon');

      await serviceWithLogging.mirrorExpense(_expense(id: 'exp-1', clientId: 'client-1', isBillable: true));

      expect(loggedFailures, isEmpty);
    });

    test('removeMirroredExpense échoue → loggé', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnDeleteMirroredExpense = Exception('réseau indisponible');

      await serviceWithLogging.removeMirroredExpense(clientId: 'client-1', expenseId: 'exp-1');

      expect(loggedFailures, hasLength(1));
      expect(loggedFailures.single, contains('exp-1'));
    });

    test('sans logRemovalFailure injecté (usage réel), un retrait raté ne relance toujours pas l\'exception', () async {
      clientRepository.clients['client-1'] = _client(id: 'client-1', portalUid: 'portal-1');
      portalRepository.throwOnDeleteMirroredWorkEntry = Exception('réseau indisponible');

      // service (pas serviceWithLogging) utilise le vrai dev.log par défaut,
      // gaté par kDebugMode — on vérifie seulement l'absence de rethrow ici,
      // pas le contenu du log réel (dart:developer, hors de portée d'un
      // test unitaire).
      await service.removeMirroredWorkEntry(clientId: 'client-1', entryId: 'entry-1');
    });
  });
}
