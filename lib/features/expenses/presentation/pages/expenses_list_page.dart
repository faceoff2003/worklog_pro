import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expense_detail_page.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';

class ExpensesListPage extends ConsumerWidget {
  final String? clientId;
  final String? projectId;

  const ExpensesListPage({super.key, this.clientId, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which provider to use
    final AsyncValue<List<Expense>> expensesAsync;
    if (projectId != null) {
      expensesAsync = ref.watch(expensesByProjectStreamProvider(projectId!));
    } else if (clientId != null) {
      expensesAsync = ref.watch(expensesByClientStreamProvider(clientId!));
    } else {
      expensesAsync = ref.watch(expensesStreamProvider);
    }

    final String title = projectId != null ? 'Dépenses (Chantier)' : 
                         clientId != null ? 'Dépenses (Client)' : 
                         'Journal des Dépenses';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: expensesAsync.when(
        data: (expenses) {
          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text('Aucune dépense', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                ],
              ),
            );
          }

          // Group by Date
          final grouped = <DateOnly, List<Expense>>{};
          for (var expense in expenses) {
            if (!grouped.containsKey(expense.date)) {
              grouped[expense.date] = [];
            }
            grouped[expense.date]!.add(expense);
          }
          
          // Sort dates descending
          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateExpenses = grouped[date]!;
              
              // Calculate daily total
              Money dailyTotal = Money.zero;
              for (var e in dateExpenses) {
                dailyTotal += e.amountHT;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateHeader(date: date, totalAmount: dailyTotal),
                  ...dateExpenses.map((expense) => _ExpenseCard(expense: expense)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ExpenseFormPage(
                initialClientId: clientId,
                initialProjectId: projectId,
              ),
            ),
          );
        },
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateOnly date;
  final Money totalAmount;

  const _DateHeader({required this.date, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date.formatLongFrench(),
            style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            totalAmount.toEurosString(),
            style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  final Expense expense;

  const _ExpenseCard({required this.expense});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch Client Name if needed (optimization: redundant if in client view, but good for global)
    final clientAsync = ref.watch(clientStreamProvider(expense.clientId));

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ExpenseDetailPage(expense: expense)),
            );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Description
                   Expanded(
                     child: Text(
                       expense.description,
                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       maxLines: 1,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Amount
                       Text(
                         expense.amountHT.toEurosString(),
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal),
                       ),
                       PopupMenuButton<String>(
                         icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                         onSelected: (value) async {
                           if (value == 'edit') {
                             Navigator.of(context).push(
                               MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: expense)),
                             );
                           } else if (value == 'delete') {
                             final confirmed = await showDeleteConfirmDialog(
                               context,
                               name: expense.description,
                               type: 'la dépense',
                             );
                             if (confirmed == true) {
                               await ref.read(expensesControllerProvider.notifier).deleteExpense(expense.id);
                             }
                           }
                         },
                         itemBuilder: (_) => [
                           const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
                           PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), Text('Supprimer', style: TextStyle(color: Colors.red))])),
                         ],
                       ),
                     ],
                   ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   Icon(
                     _getCategoryIcon(expense.category),
                     size: 16, 
                     color: Colors.grey
                   ),
                   const SizedBox(width: 4),
                   Text(
                     expense.category.displayName,
                     style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                   ),
                   const SizedBox(width: 12),
                   if (expense.isBillable)
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                       decoration: BoxDecoration(
                         color: Colors.green.shade50,
                         borderRadius: BorderRadius.circular(4),
                         border: Border.all(color: Colors.green.shade200),
                       ),
                       child: const Text('Refacturable', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                     ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                   const Icon(Icons.person, size: 16, color: Colors.grey),
                   const SizedBox(width: 4),
                   Expanded(
                     child: clientAsync.when(
                       data: (c) => Text(c?.name ?? 'Client inconnu', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                       loading: () => const Text('...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                       error: (_,__) => const Text('Erreur', style: TextStyle(color: Colors.red, fontSize: 13)),
                     ),
                   ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(ExpenseCategory category) {
    switch (category) {
      case ExpenseCategory.materials: return Icons.build;
      case ExpenseCategory.travel: return Icons.directions_car;
      case ExpenseCategory.food: return Icons.restaurant;
      case ExpenseCategory.other: return Icons.attach_money;
    }
  }
}
