import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

/// Balance financière d'un client à l'instant T.
///
/// Si un solde ([ClientSettlement]) existe, seules les entrées
/// **strictement postérieures** à [settlementDate] sont comptabilisées.
/// Les données antérieures restent archivées mais n'affectent plus la balance courante.
class ClientBalance {
  final Money totalWork;
  final Money totalExpenses;
  final Money totalPayments;

  /// Date du dernier solde (null si jamais soldé).
  final DateOnly? settlementDate;

  /// Montant qui était dû au moment du dernier solde.
  final Money? balanceAtLastSettlement;

  Money get totalDue => totalWork + totalExpenses;
  Money get balance => totalDue - totalPayments;
  bool get isPaid => balance.amountCents <= 0;
  bool get isOverpaid => balance.amountCents < 0;

  /// Indique si le compte a déjà été soldé au moins une fois.
  bool get hasBeenSettled => settlementDate != null;

  const ClientBalance({
    required this.totalWork,
    required this.totalExpenses,
    required this.totalPayments,
    this.settlementDate,
    this.balanceAtLastSettlement,
  });

  factory ClientBalance.zero() => const ClientBalance(
        totalWork: Money.zero,
        totalExpenses: Money.zero,
        totalPayments: Money.zero,
      );
}

/// Provider de la balance d'un client.
///
/// Prend en compte le dernier solde ([lastSettlementProvider]) :
/// seules les entrées postérieures à la date du solde sont incluses.
final clientBalanceProvider =
    Provider.family.autoDispose<AsyncValue<ClientBalance>, String>(
        (ref, clientId) {
  final workEntriesAsync =
      ref.watch(workEntriesByClientStreamProvider(clientId));
  final expensesAsync = ref.watch(expensesByClientStreamProvider(clientId));
  final paymentsAsync = ref.watch(paymentsStreamProvider(clientId));
  final settlementAsync = ref.watch(lastSettlementProvider(clientId));

  if (workEntriesAsync.isLoading ||
      expensesAsync.isLoading ||
      paymentsAsync.isLoading ||
      settlementAsync.isLoading) {
    return const AsyncValue.loading();
  }

  if (workEntriesAsync.hasError) {
    return AsyncValue.error(
        workEntriesAsync.error!, workEntriesAsync.stackTrace!);
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }
  if (paymentsAsync.hasError) {
    return AsyncValue.error(paymentsAsync.error!, paymentsAsync.stackTrace!);
  }
  if (settlementAsync.hasError) {
    return AsyncValue.error(settlementAsync.error!, settlementAsync.stackTrace!);
  }

  final allWorkEntries = workEntriesAsync.value ?? [];
  final allExpenses = expensesAsync.value ?? [];
  final allPayments = paymentsAsync.value ?? [];
  final lastSettlement = settlementAsync.value; // null = jamais soldé

  // Si un solde existe, on filtre pour ne garder que les entrées créées
  // APRES l'instant précis du solde (createdAt > cutoffTime)
  final cutoffTime = lastSettlement?.createdAt;

  final workEntries = cutoffTime == null
      ? allWorkEntries
      : allWorkEntries
          .where((e) => e.createdAt.isAfter(cutoffTime))
          .toList();

  final expenses = cutoffTime == null
      ? allExpenses
      : allExpenses
          .where((e) => e.createdAt.isAfter(cutoffTime))
          .toList();

  final payments = cutoffTime == null
      ? allPayments
      : allPayments.where((p) => p.createdAt.isAfter(cutoffTime)).toList();

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
    settlementDate: lastSettlement?.date,
    balanceAtLastSettlement: lastSettlement?.balanceAtSettlement,
  ));
});
