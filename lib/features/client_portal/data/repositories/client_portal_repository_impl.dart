import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Firestore implementation of [ClientPortalRepository], sur
/// clientPortals/{portalUid}/... — voir firestore.rules pour le détail des
/// permissions (miroir écrit uniquement par l'artisan lié, lu uniquement
/// par le client owner avec le portail activé).
class ClientPortalRepositoryImpl implements ClientPortalRepository {
  final FirebaseFirestore _firestore;

  ClientPortalRepositoryImpl({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _portalDoc(String portalUid) =>
      _firestore.collection('clientPortals').doc(portalUid);

  CollectionReference<Map<String, dynamic>> _workEntriesMirror(String portalUid) =>
      _portalDoc(portalUid).collection('workEntries');

  CollectionReference<Map<String, dynamic>> _expensesMirror(String portalUid) =>
      _portalDoc(portalUid).collection('expenses');

  @override
  Future<ClientPortal?> getPortal(String portalUid) async {
    final doc = await _portalDoc(portalUid).get();
    if (!doc.exists) return null;
    return ClientPortal.fromJson({...doc.data()!, 'portalUid': doc.id});
  }

  @override
  Future<void> setEnabled(String portalUid, bool enabled) async {
    await _portalDoc(portalUid).update({'enabled': enabled});
  }

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) async {
    // Via toJson(), comme Client/WorkEntry/etc. — jamais un Map écrit à la
    // main : un DateTime brut serait converti par le SDK en Timestamp
    // Firestore, que fromJson() (qui attend une String ISO8601, comme
    // partout ailleurs dans ce repo) ne sait pas relire. Bug réel du
    // 2026-09-08, voir integration_test/client_portal_round_trip_test.dart.
    final json = ClientPortal(
      portalUid: portalUid,
      artisanUid: artisanUid,
      clientId: clientId,
      enabled: true,
      createdAt: DateTime.now(),
    ).toJson()
      ..remove('portalUid'); // c'est l'ID du document, pas un champ.
    await _portalDoc(portalUid).set(json);
  }

  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) async {
    final snapshot = await _firestore.collection('clientPortals').where('artisanUid', isEqualTo: artisanUid).get();
    return snapshot.docs.map((doc) => ClientPortal.fromJson({...doc.data(), 'portalUid': doc.id})).toList();
  }

  @override
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry) async {
    await _workEntriesMirror(portalUid).doc(entry.id).set(_curatedWorkEntryMirror(entry));
  }

  @override
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId) async {
    await _workEntriesMirror(portalUid).doc(entryId).delete();
  }

  @override
  Future<void> mirrorExpense(String portalUid, Expense expense) async {
    await _expensesMirror(portalUid).doc(expense.id).set(_curatedExpenseMirror(expense));
  }

  @override
  Future<void> deleteMirroredExpense(String portalUid, String expenseId) async {
    await _expensesMirror(portalUid).doc(expenseId).delete();
  }

  @override
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) async {
    final batch = _firestore.batch();
    for (final entry in entries) {
      batch.set(_workEntriesMirror(portalUid).doc(entry.id), _curatedWorkEntryMirror(entry));
    }
    await batch.commit();
  }

  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) async {
    final batch = _firestore.batch();
    for (final expense in expenses) {
      batch.set(_expensesMirror(portalUid).doc(expense.id), _curatedExpenseMirror(expense));
    }
    await batch.commit();
  }
}

/// Champs volontairement exclus du miroir WorkEntry : notes ("détails
/// internes pour l'organisation", d'après le commentaire de l'entité) et
/// tags (classification interne) ne concernent pas le client ;
/// attachments et timerUsed n'ont pas de sens côté portail tant que le
/// Storage n'a pas son propre chemin miroir (hors scope ici). id est
/// retiré car c'est l'ID du document, pas un champ.
Map<String, dynamic> _curatedWorkEntryMirror(WorkEntry entry) => entry.toJson()
  ..remove('id')
  ..remove('notes')
  ..remove('tags')
  ..remove('timerUsed')
  ..remove('attachments');

/// attachments exclu pour la même raison que WorkEntry (pas de miroir
/// Storage). Le reste (y compris vendor) apparaît tel quel sur une dépense
/// refacturée — rien d'autre n'est marqué "interne" sur cette entité.
Map<String, dynamic> _curatedExpenseMirror(Expense expense) => expense.toJson()
  ..remove('id')
  ..remove('attachments');
