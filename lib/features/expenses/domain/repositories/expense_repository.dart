import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';


abstract class ExpenseRepository {
  /// Stream of all expenses, ordered by date descending
  Stream<List<Expense>> watchExpenses({String? clientId, String? projectId});

  /// Create a new expense
  Future<void> createExpense(Expense expense);

  /// Update an existing expense
  Future<void> updateExpense(Expense expense);

  /// Get expenses with optional filters (one-time fetch)
  Future<List<Expense>> getExpenses({
    DateOnly? from,
    DateOnly? to,
    String? clientId,
    String? projectId,
  });

  /// Delete an expense
  Future<void> deleteExpense(String id);
}

