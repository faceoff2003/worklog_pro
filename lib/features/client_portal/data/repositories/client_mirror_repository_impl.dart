import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:worklog_pro/features/client_portal/domain/repositories/client_mirror_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Implémentation Firestore de [ClientMirrorRepository]. Le uid entre
/// UNIQUEMENT ici, au constructeur — jamais dans une méthode publique (voir
/// le commentaire sur l'interface).
class ClientMirrorRepositoryImpl implements ClientMirrorRepository {
  final String _uid;
  final FirebaseFirestore _firestore;

  ClientMirrorRepositoryImpl({required String uid, FirebaseFirestore? firestore})
      : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<WorkEntry>> watchMyWorkEntries() {
    // orderBy à un seul champ : aucun index composite requis (Firestore
    // gère un index simple par champ automatiquement). Le tri secondaire
    // (stabilité entre deux prestations du même jour) se fait côté Dart
    // ci-dessous plutôt que d'ajouter un second orderBy() ici, qui en
    // exigerait un.
    return _firestore
        .collection('clientPortals')
        .doc(_uid)
        .collection('workEntries')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      final entries = snapshot.docs
          .map((doc) => WorkEntry.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
      entries.sort((a, b) {
        final dateCompare = b.date.compareTo(a.date);
        if (dateCompare != 0) return dateCompare;
        return b.createdAt.compareTo(a.createdAt);
      });
      return entries;
    });
  }
}
