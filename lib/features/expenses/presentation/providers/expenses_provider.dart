import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';

// --- Repository ---

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User must be authenticated to access ExpenseRepository');
  }
  return ExpenseRepositoryImpl(user.uid);
});

// --- Streams ---

// All expenses
final expensesStreamProvider = StreamProvider.autoDispose<List<Expense>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpenses();
});

// Expenses for a specific client
final expensesByClientStreamProvider = StreamProvider.family.autoDispose<List<Expense>, String>((ref, clientId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpenses(clientId: clientId);
});

// Expenses for a specific project
final expensesByProjectStreamProvider = StreamProvider.family.autoDispose<List<Expense>, String>((ref, projectId) {
  final repository = ref.watch(expenseRepositoryProvider);
  return repository.watchExpenses(projectId: projectId);
});

// --- Controller ---

final expensesControllerProvider = StateNotifierProvider<ExpensesController, AsyncValue<void>>((ref) {
  final repository = ref.watch(expenseRepositoryProvider);
  return ExpensesController(repository);
});

class ExpensesController extends StateNotifier<AsyncValue<void>> {
  final ExpenseRepository _repository;

  ExpensesController(this._repository) : super(const AsyncData(null));

  Future<void> createExpense(Expense expense) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.createExpense(expense));
  }

  Future<void> updateExpense(Expense expense) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.updateExpense(expense));
  }

  Future<void> deleteExpense(String id) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.deleteExpense(id));
  }
}
