import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/domain/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  PaymentRepositoryImpl(this._firestore, this._auth);

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _getPaymentsCollection() {
    if (_userId == null) {
      throw Exception('User must be logged in to access payments');
    }
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('payments');
  }

  @override
  Stream<List<Payment>> watchPayments({String? clientId, String? projectId}) {
    var query = _getPaymentsCollection().orderBy('date', descending: true);

    // Filter order: Equality first
    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    
    // Project filter if applicable
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return Payment.fromJson(doc.data());
        } catch (e) {
          return null;
        }
      }).whereType<Payment>().toList();
    });
  }

  @override
  Future<List<Payment>> getPayments({String? clientId, String? projectId}) async {
    var query = _getPaymentsCollection().orderBy('date', descending: true);

    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    
    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      try {
        return Payment.fromJson(doc.data());
      } catch (e) {
        return null;
      }
    }).whereType<Payment>().toList();
  }

  @override
  Future<void> createPayment(Payment payment) async {
    await _getPaymentsCollection().doc(payment.id).set(payment.toJson());
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    await _getPaymentsCollection().doc(payment.id).update(payment.toJson());
  }

  @override
  Future<void> deletePayment(String id) async {
    await _getPaymentsCollection().doc(id).delete();
  }
}
