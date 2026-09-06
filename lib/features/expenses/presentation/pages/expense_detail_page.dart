import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';

class ExpenseDetailPage extends ConsumerWidget {
  final Expense expense;
  const ExpenseDetailPage({super.key, required this.expense});

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: expense)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const color = Colors.teal;
    final clientAsync = ref.watch(clientStreamProvider(expense.clientId));
    final AsyncValue<Project?> projectAsync = expense.projectId != null
        ? ref.watch(projectStreamProvider(expense.projectId!))
        : const AsyncData<Project?>(null);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(expense.description),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            onPressed: () => _openEdit(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Supprimer',
            onPressed: () async {
              // ignore: use_build_context_synchronously
              final confirmed = await showDeleteConfirmDialog(
                context,
                name: expense.description,
                type: 'la dépense',
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(expensesControllerProvider.notifier)
                    .deleteExpense(expense.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Amount hero
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withAlpha(15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withAlpha(60)),
            ),
            child: Column(
              children: [
                const Icon(Icons.receipt_long_outlined, color: color, size: 40),
                const SizedBox(height: 8),
                Text(
                  expense.amountHT.toEurosString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: expense.isBillable ? Colors.green.shade50 : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: expense.isBillable ? Colors.green.shade200 : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    expense.isBillable ? 'Refacturable' : 'Non refacturable',
                    style: TextStyle(
                      color: expense.isBillable ? Colors.green.shade700 : Colors.grey.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const DetailSection(title: 'Détails'),
          DetailInfoRow(
            icon: Icons.description,
            label: 'Description',
            value: expense.description,
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.category,
            label: 'Catégorie',
            value: expense.category.displayName,
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: expense.date.formatLongFrench(),
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.person,
            label: 'Client',
            value: clientAsync.value?.name ?? '…',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          if (expense.projectId != null)
            DetailInfoRow(
              icon: Icons.construction,
              label: 'Chantier',
              value: projectAsync.value?.label ?? '…',
              iconColor: color,
              onEdit: () => _openEdit(context),
            ),
          if (expense.vendor != null && expense.vendor!.isNotEmpty)
            DetailInfoRow(
              icon: Icons.store,
              label: 'Fournisseur',
              value: expense.vendor!,
              iconColor: color,
              onEdit: () => _openEdit(context),
            ),
          if (expense.travelDistanceKm != null)
            DetailInfoRow(
              icon: Icons.directions_car,
              label: 'Distance',
              value: '${expense.travelDistanceKm} km',
              iconColor: color,
              onEdit: () => _openEdit(context),
            ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context),
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Modifier'),
      ),
    );
  }
}
