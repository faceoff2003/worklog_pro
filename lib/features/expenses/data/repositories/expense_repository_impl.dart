import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';


class ExpenseRepositoryImpl implements ExpenseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId;

  ExpenseRepositoryImpl(this.userId);

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
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expensesCollection().doc(id).delete();
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final expenseToUpdate = expense.copyWith(
      updatedAt: DateTime.now(),
    );
    await _expensesCollection()
        .doc(expense.id)
        .update(expenseToUpdate.toJson());
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

