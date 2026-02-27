import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';

/// Firestore implementation of [ClientRepository].
class ClientRepositoryImpl implements ClientRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Uuid _uuid;

  ClientRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    Uuid? uuid,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _uuid = uuid ?? const Uuid();

  /// Get the clients collection path for the current user.
  CollectionReference<Map<String, dynamic>> _clientsCollection() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return _firestore.collection('users/$userId/clients');
  }

  @override
  Stream<List<Client>> watchClients() {
    return _clientsCollection()
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              return Client.fromJson({...data, 'id': doc.id});
            } catch (e) {
              // Log error and skip invalid document
              debugPrint('Error parsing client ${doc.id}: $e');
              return null;
            }
          })
          .whereType<Client>()
          .toList();
    });
  }

  @override
  Stream<Client?> watchClient(String clientId) {
    return _clientsCollection().doc(clientId).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      try {
        final data = snapshot.data()!;
        return Client.fromJson({...data, 'id': snapshot.id});
      } catch (e) {
        debugPrint('Error parsing client $clientId: $e');
        return null;
      }
    });
  }

  @override
  Future<Client?> getClient(String clientId) async {
    final snapshot = await _clientsCollection().doc(clientId).get();
    if (!snapshot.exists) return null;
    try {
      final data = snapshot.data()!;
      return Client.fromJson({...data, 'id': snapshot.id});
    } catch (e) {
      debugPrint('Error parsing client $clientId: $e');
      return null;
    }
  }

  @override
  Future<List<Client>> getClients() async {
    final snapshot = await _clientsCollection().orderBy('name').get();
    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            return Client.fromJson({...data, 'id': doc.id});
          } catch (e) {
            debugPrint('Error parsing client ${doc.id}: $e');
            return null;
          }
        })
        .whereType<Client>()
        .toList();
  }

  @override
  Future<Client> createClient(Client client) async {
    final now = DateTime.now();
    final clientId = _uuid.v4();

    final clientWithTimestamps = client.copyWith(
      id: clientId,
      createdAt: now,
      updatedAt: now,
    );

    final json = clientWithTimestamps.toJson();
    // Remove id from JSON (it's the document ID, not a field)
    json.remove('id');

    await _clientsCollection().doc(clientId).set(json);

    return clientWithTimestamps;
  }

  @override
  Future<void> updateClient(Client client) async {
    final clientWithUpdatedAt = client.copyWith(
      updatedAt: DateTime.now(),
    );

    final json = clientWithUpdatedAt.toJson();
    // Remove id and createdAt from update (immutable fields)
    json.remove('id');
    json.remove('createdAt');

    await _clientsCollection().doc(client.id).update(json);
  }

  @override
  Future<void> deleteClient(String clientId) async {
    await _clientsCollection().doc(clientId).delete();
  }

  @override
  Future<List<Client>> searchClientsByName(String query) async {
    if (query.isEmpty) {
      return getClients();
    }

    final snapshot = await _clientsCollection()
        .orderBy('name')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get();

    return snapshot.docs
        .map((doc) {
          try {
            final data = doc.data();
            return Client.fromJson({...data, 'id': doc.id});
          } catch (e) {
            debugPrint('Error parsing client ${doc.id}: $e');
            return null;
          }
        })
        .whereType<Client>()
        .toList();
  }
}
