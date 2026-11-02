import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

/// Relevé de compte d'un client, recalculé à chaque émission d'un des flux.
final accountStatementProvider =
    Provider.family.autoDispose<AsyncValue<AccountStatement>, String>((ref, clientId) {
  final workEntries = ref.watch(workEntriesByClientStreamProvider(clientId));
  final expenses = ref.watch(expensesByClientStreamProvider(clientId));
  final payments = ref.watch(paymentsStreamProvider(clientId));
  final settlements = ref.watch(allSettlementsProvider(clientId));

  if (workEntries.isLoading || expenses.isLoading || payments.isLoading || settlements.isLoading) {
    return const AsyncValue.loading();
  }
  if (workEntries.hasError) return AsyncValue.error(workEntries.error!, workEntries.stackTrace!);
  if (expenses.hasError) return AsyncValue.error(expenses.error!, expenses.stackTrace!);
  if (payments.hasError) return AsyncValue.error(payments.error!, payments.stackTrace!);
  if (settlements.hasError) return AsyncValue.error(settlements.error!, settlements.stackTrace!);

  return AsyncValue.data(const AccountStatementService().build(
    workEntries: workEntries.value ?? [],
    expenses: expenses.value ?? [],
    payments: payments.value ?? [],
    settlements: settlements.value ?? [],
  ));
});
