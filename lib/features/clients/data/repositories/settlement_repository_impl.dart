import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/repositories/settlement_repository.dart';

/// Implémentation Firestore du [SettlementRepository].
///
/// Collection : `users/{userId}/client_settlements`
/// Filtrée par [clientId] pour chaque client.
class SettlementRepositoryImpl implements SettlementRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  SettlementRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

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
  }

  @override
  Future<void> deleteSettlement(String settlementId) async {
    await _collection().doc(settlementId).delete();
  }
}
