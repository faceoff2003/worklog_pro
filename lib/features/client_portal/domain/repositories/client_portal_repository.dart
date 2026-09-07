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
}
