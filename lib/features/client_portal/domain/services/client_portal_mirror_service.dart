import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Décide QUOI mirrorer et OÙ, appelé par WorkEntryRepositoryImpl et
/// ExpenseRepositoryImpl après leur écriture réelle — jamais avant, jamais à
/// la place. Toute méthode ici est best-effort : une exception (client
/// introuvable, pas de portail, écriture cloud échouée) est avalée, jamais
/// propagée. Le miroir ne doit JAMAIS faire échouer l'enregistrement réel
/// d'une prestation ou d'une dépense pour l'artisan.
class ClientPortalMirrorService {
  final ClientRepository _clientRepository;
  final ClientPortalRepository _clientPortalRepository;

  ClientPortalMirrorService({
    required ClientRepository clientRepository,
    required ClientPortalRepository clientPortalRepository,
  })  : _clientRepository = clientRepository,
        _clientPortalRepository = clientPortalRepository;

  Future<void> mirrorWorkEntry(WorkEntry entry) => _guarded(() async {
        final portalUid = await _portalUidFor(entry.clientId);
        if (portalUid == null) return;
        await _clientPortalRepository.mirrorWorkEntry(portalUid, entry);
      });

  Future<void> removeMirroredWorkEntry({required String clientId, required String entryId}) => _guarded(() async {
        final portalUid = await _portalUidFor(clientId);
        if (portalUid == null) return;
        await _clientPortalRepository.deleteMirroredWorkEntry(portalUid, entryId);
      });

  /// N'écrit jamais une dépense non refacturable — la retire du miroir si
  /// elle y était (le cas où isBillable bascule de true à false sur une
  /// dépense déjà mirrorée).
  Future<void> mirrorExpense(Expense expense) => _guarded(() async {
        final portalUid = await _portalUidFor(expense.clientId);
        if (portalUid == null) return;
        if (!expense.isBillable) {
          await _clientPortalRepository.deleteMirroredExpense(portalUid, expense.id);
          return;
        }
        await _clientPortalRepository.mirrorExpense(portalUid, expense);
      });

  Future<void> removeMirroredExpense({required String clientId, required String expenseId}) => _guarded(() async {
        final portalUid = await _portalUidFor(clientId);
        if (portalUid == null) return;
        await _clientPortalRepository.deleteMirroredExpense(portalUid, expenseId);
      });

  Future<String?> _portalUidFor(String clientId) async {
    final client = await _clientRepository.getClient(clientId);
    return client?.portalUid;
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // best-effort : voir le commentaire de classe.
    }
  }
}
