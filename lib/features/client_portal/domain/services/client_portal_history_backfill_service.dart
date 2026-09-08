import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';

/// Un WriteBatch Firestore est limité à 500 opérations.
const _maxBatchSize = 500;

/// Compteurs séparés par collection — jamais agrégés. Un artisan doit
/// pouvoir voir "20/20 prestations, 0/5 dépenses" et savoir exactement
/// laquelle des deux a échoué, pas un total masquant lequel des deux
/// a foiré (décidé avec William avant de coder ceci).
class BackfillOutcome {
  final int totalWorkEntries;
  final int mirroredWorkEntries;
  final int totalExpenses;
  final int mirroredExpenses;

  const BackfillOutcome({
    required this.totalWorkEntries,
    required this.mirroredWorkEntries,
    required this.totalExpenses,
    required this.mirroredExpenses,
  });

  bool get workEntriesComplete => mirroredWorkEntries == totalWorkEntries;
  bool get expensesComplete => mirroredExpenses == totalExpenses;
  bool get isComplete => workEntriesComplete && expensesComplete;
}

/// Reprend l'historique existant d'un client au moment du provisioning (ou
/// à la demande, pour un portail déjà créé avant que ce service existe) —
/// le mirroring en continu (ClientPortalMirrorService) ne couvre que les
/// écritures qui arrivent APRÈS la création du portail, jamais l'historique.
///
/// Idempotent par construction : réutilise les mêmes IDs de document que le
/// mirroring normal (l'ID de la prestation/dépense) — rejouer ce service
/// réécrit les documents déjà mirrorés à l'identique (no-op réel) et
/// complète ceux qui manquent, jamais de doublon.
///
/// Prestations et dépenses sont tentées INDÉPENDAMMENT : rien ne dit qu'un
/// échec sur l'une prédit un échec sur l'autre (chemins Firestore séparés),
/// et le coût d'avoir quand même tenté est négligeable — s'arrêter net sur
/// l'échec des prestations priverait le client de dépenses qui, elles,
/// seraient passées. Décidé avec William, argumenté avant de coder.
class ClientPortalHistoryBackfillService {
  final WorkEntryRepository _workEntryRepository;
  final ExpenseRepository _expenseRepository;
  final ClientPortalRepository _clientPortalRepository;

  ClientPortalHistoryBackfillService(
    this._workEntryRepository,
    this._expenseRepository,
    this._clientPortalRepository,
  );

  Future<BackfillOutcome> backfillHistory({required String portalUid, required String clientId}) async {
    final allEntries = await _workEntryRepository.getWorkEntries(clientId: clientId);
    final allExpenses = (await _expenseRepository.getExpenses(clientId: clientId))
        .where((expense) => expense.isBillable)
        .toList();

    final mirroredWorkEntries = await _mirrorInChunks<WorkEntry>(
      allEntries,
      (chunk) => _clientPortalRepository.mirrorWorkEntriesBatch(portalUid, chunk),
    );
    final mirroredExpenses = await _mirrorInChunks<Expense>(
      allExpenses,
      (chunk) => _clientPortalRepository.mirrorExpensesBatch(portalUid, chunk),
    );

    return BackfillOutcome(
      totalWorkEntries: allEntries.length,
      mirroredWorkEntries: mirroredWorkEntries,
      totalExpenses: allExpenses.length,
      mirroredExpenses: mirroredExpenses,
    );
  }

  /// Découpe en lots de 500 max, écrit chunk par chunk, s'arrête au premier
  /// chunk qui échoue (ne tente pas les suivants) — état déterministe,
  /// jamais une tentative en aveugle sur un lot qui suit un échec.
  Future<int> _mirrorInChunks<T>(List<T> items, Future<void> Function(List<T> chunk) writeChunk) async {
    var mirrored = 0;
    for (var start = 0; start < items.length; start += _maxBatchSize) {
      final end = (start + _maxBatchSize < items.length) ? start + _maxBatchSize : items.length;
      final chunk = items.sublist(start, end);
      try {
        await writeChunk(chunk);
        mirrored += chunk.length;
      } catch (_) {
        break;
      }
    }
    return mirrored;
  }
}
