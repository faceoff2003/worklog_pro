import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_mirror_service.dart';
import 'package:worklog_pro/features/clients/data/repositories/client_repository_impl.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/repositories/settlement_repository.dart';

/// Implémentation Firestore du [SettlementRepository].
///
/// Collection : `users/{userId}/client_settlements`
/// Filtrée par [clientId] pour chaque client.
class SettlementRepositoryImpl implements SettlementRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ClientPortalMirrorService _mirror;

  SettlementRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ClientPortalMirrorService? mirror,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _mirror = mirror ??
            ClientPortalMirrorService(
              clientRepository: ClientRepositoryImpl(),
              clientPortalRepository: ClientPortalRepositoryImpl(),
            );

  String get _userId {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _collection() =>
      _firestore.collection('users/$_userId/client_settlements');

  @override
  Stream<ClientSettlement?> watchLastSettlement(String clientId) {
    return _collection()
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      try {
        final settlements = snap.docs
            .map((doc) => ClientSettlement.fromJson(doc.data()))
            .toList();
        settlements.sort((a, b) => b.date.compareTo(a.date));
        return settlements.first;
      } catch (_) {
        return null;
      }
    });
  }

  @override
  Stream<List<ClientSettlement>> watchAllSettlements(String clientId) {
    return _collection()
        .where('clientId', isEqualTo: clientId)
        .snapshots()
        .map((snap) {
      final settlements = snap.docs
          .map((doc) {
            try {
              return ClientSettlement.fromJson(doc.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<ClientSettlement>()
          .toList();
      settlements.sort((a, b) => b.date.compareTo(a.date));
      return settlements;
    });
  }

  @override
  Future<void> createSettlement(ClientSettlement settlement) async {
    await _collection().doc(settlement.id).set(settlement.toJson());
    // Best-effort, après l'écriture réelle : un échec ici ne doit jamais
    // faire échouer le solde de compte lui-même (voir ClientPortalMirror
    // Service.mirrorSettlementPivot).
    await _mirror.mirrorSettlementPivot(settlement);
  }

  @override
  Future<void> deleteSettlement(String settlementId) async {
    await _collection().doc(settlementId).delete();
  }
}
