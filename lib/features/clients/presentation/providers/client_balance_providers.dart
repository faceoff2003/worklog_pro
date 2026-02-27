import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class ClientBalance {
  final Money totalWork;
  final Money totalExpenses;
  final Money totalPayments;
  
  Money get totalDue => totalWork + totalExpenses;
  Money get balance => totalDue - totalPayments;
  bool get isPaid => balance.amountCents <= 0;
  bool get isOverpaid => balance.amountCents < 0;
  
  const ClientBalance({
    required this.totalWork,
    required this.totalExpenses,
    required this.totalPayments,
  });
  
  factory ClientBalance.zero() => ClientBalance(
    totalWork: Money.zero,
    totalExpenses: Money.zero,
    totalPayments: Money.zero,
  );
}

final clientBalanceProvider = Provider.family.autoDispose<AsyncValue<ClientBalance>, String>((ref, clientId) {
  final workEntriesAsync = ref.watch(workEntriesByClientStreamProvider(clientId));
  final expensesAsync = ref.watch(expensesByClientStreamProvider(clientId));
  final paymentsAsync = ref.watch(paymentsStreamProvider(clientId));
  
  if (workEntriesAsync.isLoading || expensesAsync.isLoading || paymentsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (workEntriesAsync.hasError) {
    return AsyncValue.error(workEntriesAsync.error!, workEntriesAsync.stackTrace!);
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }
  if (paymentsAsync.hasError) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }
  
  final workEntries = workEntriesAsync.value ?? [];
  final expenses = expensesAsync.value ?? [];
  final payments = paymentsAsync.value ?? [];
  
  Money totalWork = Money.zero;
  for (final entry in workEntries) {
     totalWork += entry.laborAmountHT;
  }
  
  Money totalExpenses = Money.zero;
  for (final expense in expenses) {
    if (expense.isBillable) {
      totalExpenses += expense.amountHT;
    }
  }
  
  Money totalPayments = Money.zero;
  for (final payment in payments) {
    totalPayments += payment.amount;
  }
  
  return AsyncValue.data(ClientBalance(
    totalWork: totalWork,
    totalExpenses: totalExpenses,
    totalPayments: totalPayments,
  ));
});
