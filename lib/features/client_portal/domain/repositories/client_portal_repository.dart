import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Accès à l'arbre clientPortals/{portalUid}/... (côté artisan).
///
/// Ne connaît rien de users/{artisanUid}/clients/{clientId} — c'est
/// ClientRepository qui sait si un client a un portail (Client.portalUid).
/// Cette séparation évite qu'une classe ait à connaître les deux arbres.
abstract class ClientPortalRepository {
  Future<ClientPortal?> getPortal(String portalUid);

  /// Crée le profil initial, enabled: true. artisanUid et clientId
  /// immuables ensuite (firestore.rules) — l'appelant ne doit jamais
  /// réutiliser un portalUid déjà existant (chaque compte Firebase Auth
  /// n'a qu'un seul portail, jamais recréé).
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId});

  /// Tous les portails liés à cet artisan — nécessite la règle `list`
  /// filtrée par `artisanUid` (firestore.rules) : l'appelant DOIT être
  /// l'artisan lui-même, jamais un portalUid arbitraire. Usage : le
  /// balayage de réparation (ClientPortalReconciliationService).
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid);

  /// Bascule enabled — une seule écriture sur le profil, atomique. Pas de
  /// propagation : voir la note dans firestore.rules sur isPortalEnabled().
  Future<void> setEnabled(String portalUid, bool enabled);

  /// Miroir en lecture seule pour le client — champs internes exclus (voir
  /// ClientPortalMirrorService pour la liste exacte et pourquoi).
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry);
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId);

  /// N'écrit jamais une dépense non refacturable — c'est
  /// ClientPortalMirrorService qui tranche avant d'appeler ceci ou
  /// deleteMirroredExpense.
  Future<void> mirrorExpense(String portalUid, Expense expense);
  Future<void> deleteMirroredExpense(String portalUid, String expenseId);

  /// Primitives bas niveau pour ClientPortalHistoryBackfillService — UN
  /// seul WriteBatch Firestore, donc AU PLUS 500 éléments (limite du SDK,
  /// pas vérifiée ici : c'est l'appelant qui découpe et compte). Un
  /// WriteBatch est tout ou rien : un seul document qui violerait une rule
  /// (ex. une dépense non refacturable) ferait échouer tout le lot — c'est
  /// pour ça que le filtre isBillable doit être fait par l'appelant, jamais
  /// ici ni laissé à la rule.
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries);
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses);

  /// Statut persisté de la dernière reprise d'historique — voie de lecture
  /// et d'écriture SÉPARÉE de getPortal()/ClientPortal : ces compteurs ne
  /// vivent JAMAIS dans l'entité partagée, pour que decideRoleRoute() ne
  /// puisse structurellement jamais en dépendre. Écriture réservée à
  /// l'artisan lié (règle déjà en place sur le profil), immuable côté
  /// client (voir firestore.rules).
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome);
  Future<BackfillOutcome?> getBackfillStatus(String portalUid);
}

/// Compteurs séparés par collection — jamais agrégés. Un artisan doit
/// pouvoir voir "20/20 prestations, 0/5 dépenses" et savoir exactement
/// laquelle des deux a échoué, pas un total masquant lequel des deux a
/// foiré (décidé avec William avant de coder ceci). Défini ici, pas dans le
/// service : c'est aussi le type persisté par saveBackfillStatus/
/// getBackfillStatus ci-dessus.
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
