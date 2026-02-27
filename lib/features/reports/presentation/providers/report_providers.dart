import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

// State class for filters
class ReportFilter {
  final DateTimeRange dateRange;
  final String? clientId;
  final String? projectId;

  ReportFilter({
    required this.dateRange,
    this.clientId,
    this.projectId,
  });

  factory ReportFilter.initial() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);
    return ReportFilter(
      dateRange: DateTimeRange(start: start, end: end),
    );
  }

  ReportFilter copyWith({
    DateTimeRange? dateRange,
    String? clientId,
    String? projectId,
    bool clearProject = false,
  }) {
    return ReportFilter(
      dateRange: dateRange ?? this.dateRange,
      clientId: clientId ?? this.clientId,
      projectId: clearProject ? null : (projectId ?? this.projectId),
    );
  }
}

/// Provider for the filter state
final reportFilterProvider = StateProvider<ReportFilter>((ref) {
  return ReportFilter.initial();
});

/// Provider for report data — rebuilt whenever any sub-stream emits a new value.
/// Correctly applies clientId and projectId filters from the active ReportFilter.
final reportDataProvider = Provider<AsyncValue<ReportData>>((ref) {
  final filter = ref.watch(reportFilterProvider);
  final from = DateOnly.fromDateTime(filter.dateRange.start);
  final to = DateOnly.fromDateTime(filter.dateRange.end);
  final clientId = filter.clientId;
  final projectId = filter.projectId;

  // Watch the appropriate work entries stream based on filter
  final AsyncValue<List<dynamic>> workEntriesAsync;
  if (projectId != null) {
    workEntriesAsync = ref.watch(workEntriesByProjectStreamProvider(projectId));
  } else if (clientId != null) {
    workEntriesAsync = ref.watch(workEntriesByClientStreamProvider(clientId));
  } else {
    workEntriesAsync = ref.watch(workEntriesStreamProvider);
  }

  // Watch the appropriate expenses stream based on filter
  final AsyncValue<List<dynamic>> expensesAsync;
  if (projectId != null) {
    expensesAsync = ref.watch(expensesByProjectStreamProvider(projectId));
  } else if (clientId != null) {
    expensesAsync = ref.watch(expensesByClientStreamProvider(clientId));
  } else {
    expensesAsync = ref.watch(expensesStreamProvider);
  }

  // Payments are filtered by client (no project-level filter available at stream level)
  final paymentsAsync = ref.watch(paymentsStreamProvider(clientId));

  // Propagate loading
  if (workEntriesAsync.isLoading || expensesAsync.isLoading || paymentsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Propagate errors
  final workEntriesError = workEntriesAsync.error;
  if (workEntriesError != null) {
    return AsyncValue.error(workEntriesError, workEntriesAsync.stackTrace!);
  }
  final expensesError = expensesAsync.error;
  if (expensesError != null) {
    return AsyncValue.error(expensesError, expensesAsync.stackTrace!);
  }
  final paymentsError = paymentsAsync.error;
  if (paymentsError != null) {
    return AsyncValue.error(paymentsError, paymentsAsync.stackTrace!);
  }

  // All data available — compute the report
  final allEntries = workEntriesAsync.value ?? [];
  final allExpenses = expensesAsync.value ?? [];
  final allPayments = paymentsAsync.value ?? [];

  // Apply date filters (and local project filter on payments if needed)
  final workEntries = allEntries.where((e) {
    final entry = e as dynamic;
    final dateInRange = entry.date >= from && entry.date <= to;
    // If project filter is active, also filter by project
    if (projectId != null) {
      return dateInRange && entry.projectId == projectId;
    }
    return dateInRange;
  }).toList();

  final expenses = allExpenses.where((e) {
    final expense = e as dynamic;
    final dateInRange = expense.date >= from && expense.date <= to;
    if (projectId != null) {
      return dateInRange && expense.projectId == projectId;
    }
    return dateInRange;
  }).toList();

  // Payments: filter by date (and project if applicable)
  final filteredPayments = allPayments.where((p) {
    final payment = p as dynamic;
    final dateInRange = payment.date >= from && payment.date <= to;
    if (projectId != null) {
      return dateInRange && payment.projectId == projectId;
    }
    return dateInRange;
  }).toList();

  // Calculate totals
  var totalLabor = Money.zero;
  var totalTravel = Money.zero;
  for (final entry in workEntries) {
    totalLabor += (entry as dynamic).laborAmountHT as Money;
    totalTravel += (entry as dynamic).travelAmountHT as Money;
  }

  var totalBillableExpenses = Money.zero;
  var totalNonBillableExpenses = Money.zero;
  for (final expense in expenses) {
    final e = expense as dynamic;
    if (e.isBillable) {
      totalBillableExpenses += e.amountHT as Money;
    } else {
      totalNonBillableExpenses += e.amountHT as Money;
    }
  }

  var totalPayments = Money.zero;
  for (final payment in filteredPayments) {
    totalPayments += (payment as dynamic).amount as Money;
  }

  return AsyncValue.data(ReportData(
    totalLaborAmount: totalLabor,
    totalTravelAmount: totalTravel,
    totalBillableExpenses: totalBillableExpenses,
    totalNonBillableExpenses: totalNonBillableExpenses,
    totalPayments: totalPayments,
    workEntries: workEntries.cast(),
    expenses: expenses.cast(),
    payments: filteredPayments.cast(),
    dateRange: filter.dateRange,
  ));
});
