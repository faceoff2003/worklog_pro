import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_mirror_service.dart';
import 'package:worklog_pro/features/clients/data/repositories/client_repository_impl.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String userId;
  final ClientPortalMirrorService _mirror;

  ExpenseRepositoryImpl(
    this.userId, {
    FirebaseFirestore? firestore,
    ClientPortalMirrorService? mirror,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _mirror = mirror ??
            ClientPortalMirrorService(
              clientRepository: ClientRepositoryImpl(),
              clientPortalRepository: ClientPortalRepositoryImpl(),
            );

  CollectionReference<Map<String, dynamic>> _expensesCollection() {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses');
  }

  @override
  Future<void> createExpense(Expense expense) async {
    final docRef = _expensesCollection().doc();
    final expenseWithId = expense.copyWith(
      id: docRef.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await docRef.set(expenseWithId.toJson());
    await _mirror.mirrorExpense(expenseWithId);
  }

  @override
  Future<void> deleteExpense(String id) async {
    // Lu avant suppression : il faut clientId pour retrouver le portail
    // éventuel à nettoyer. Pas de getExpense(id) dans l'interface publique
    // (voir ExpenseRepository) : lecture directe, détail d'implémentation.
    final existing = await _expensesCollection().doc(id).get();

    await _expensesCollection().doc(id).delete();

    if (existing.exists) {
      final clientId = existing.data()!['clientId'] as String;
      await _mirror.removeMirroredExpense(clientId: clientId, expenseId: id);
    }
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseToUpdate = expense.copyWith(
      updatedAt: DateTime.now(),
    );
    await _expensesCollection()
        .doc(expense.id)
        .update(expenseToUpdate.toJson());
    await _mirror.mirrorExpense(expenseToUpdate);
  }

  @override
  Stream<List<Expense>> watchExpenses({String? clientId, String? projectId}) {
    Query<Map<String, dynamic>> query = _expensesCollection()
        .orderBy('date', descending: true);

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          // Handle potential issues with Money serialization or Enums
          final data = doc.data();
          // Ensure ID is set from doc ID if missing (though we set it on create)
          data['id'] = doc.id;
          return Expense.fromJson(data);
        } catch (e) {
          // Skip malformed documents or log error
          // debugPrint('Error parsing expense ${doc.id}: $e');
          return null;
        }
      }).whereType<Expense>().toList();
    });
  }
  @override
  Future<List<Expense>> getExpenses({
    DateOnly? from,
    DateOnly? to,
    String? clientId,
    String? projectId,
  }) async {
    Query<Map<String, dynamic>> query = _expensesCollection()
        .orderBy('date', descending: true);

    if (projectId != null) {
      query = query.where('projectId', isEqualTo: projectId);
    } else if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }

    if (from != null) {
      query = query.where('date', isGreaterThanOrEqualTo: from.toJson());
    }

    if (to != null) {
      query = query.where('date', isLessThanOrEqualTo: to.toJson());
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Expense.fromJson(data);
    }).toList();
  }
}

