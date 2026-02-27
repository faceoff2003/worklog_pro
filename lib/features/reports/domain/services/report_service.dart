import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/features/payments/domain/repositories/payment_repository.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';

/// Fournisseur Riverpod pour injecter le [ReportService].
/// Il requiert l'accès aux trois dépôts de données principaux.
final reportServiceProvider = Provider<ReportService>((ref) {
  return ReportService(
    ref.watch(workEntryRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(paymentRepositoryProvider),
  );
});

/// Service métier responsable de la génération des bilans financiers.
///
/// Ce service orchestre la récupération asynchrone concurrente des données
/// (Prestations, Dépenses, Encaissements) et effectue la somme totale
/// pour produire un objet [ReportData] consolidé.
class ReportService {
  final WorkEntryRepository _workEntryRepository;
  final ExpenseRepository _expenseRepository;
  final PaymentRepository _paymentRepository;

  ReportService(
    this._workEntryRepository,
    this._expenseRepository,
    this._paymentRepository,
  );

  /// Génère un bilan consolidé ([ReportData]) pour une période donnée.
  ///
  /// Le rapport limite les requêtes dans le [dateRange]. 
  /// Des filtres optionnels [clientId] et [projectId] peuvent limiter 
  /// le ciblage de la recherche (par exemple pour la facturation d'un projet unique).
  Future<ReportData> getReport({
    required DateTimeRange dateRange,
    String? clientId,
    String? projectId,
  }) async {
    final from = DateOnly.fromDateTime(dateRange.start);
    final to = DateOnly.fromDateTime(dateRange.end);

    // Fetch data concurrently
    final results = await Future.wait([
      _workEntryRepository.getWorkEntries(
        from: from,
        to: to,
        clientId: clientId,
        projectId: projectId,
      ),
      _expenseRepository.getExpenses(
        from: from,
        to: to,
        clientId: clientId,
        projectId: projectId,
      ),
      _paymentRepository.getPayments(
        clientId: clientId,
        projectId: projectId,
      ),
    ]);

    final workEntries = results[0] as List<dynamic>; // List<WorkEntry>
    final expenses = results[1] as List<dynamic>;    // List<Expense>
    final allPayments = results[2] as List<dynamic>; // List<Payment>

    // Filter payments by date range locally since repo doesn't support range query
    // Also filter by date range locally if needed (though repo supports it usually)
    // Here we rely on repo for WorkEntries and Expenses basic filtering, but double check
    
    final filteredPayments = allPayments.where((p) {
      final pDate = (p as dynamic).date as DateOnly;
      return pDate >= from && pDate <= to;
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

    return ReportData(
      totalLaborAmount: totalLabor,
      totalTravelAmount: totalTravel,
      totalBillableExpenses: totalBillableExpenses,
      totalNonBillableExpenses: totalNonBillableExpenses,
      totalPayments: totalPayments,
      workEntries: workEntries.cast(),
      expenses: expenses.cast(),
      payments: filteredPayments.cast(),
      dateRange: dateRange,
    );
  }
}
