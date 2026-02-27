import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';
import 'package:worklog_pro/features/payments/presentation/pages/payment_form_page.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';

class PaymentDetailPage extends ConsumerWidget {
  final Payment payment;
  const PaymentDetailPage({super.key, required this.payment});

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PaymentFormPage(payment: payment)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const color = Colors.green;
    final clientAsync = ref.watch(clientStreamProvider(payment.clientId));
    final AsyncValue<Project?> projectAsync = payment.projectId != null
        ? ref.watch(projectStreamProvider(payment.projectId!))
        : const AsyncData<Project?>(null);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(payment.amount.toEurosString()),
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
              final clientName = clientAsync.value?.name ?? '';
              // ignore: use_build_context_synchronously
              final confirmed = await showDeleteConfirmDialog(
                context,
                name: '${payment.amount.toEurosString()} — $clientName',
                type: 'le paiement',
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(paymentsControllerProvider.notifier)
                    .deletePayment(payment.id);
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
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.payments_outlined, color: Colors.green.shade700, size: 40),
                const SizedBox(height: 8),
                Text(
                  payment.amount.toEurosString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const DetailSection(title: 'Détails'),
          DetailInfoRow(
            icon: Icons.person,
            label: 'Client',
            value: clientAsync.value?.name ?? '…',
            iconColor: Colors.green.shade700,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: 'Date',
            value: DateFormat('dd/MM/yyyy').format(payment.date.toDateTime()),
            iconColor: Colors.green.shade700,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.payment,
            label: 'Mode de paiement',
            value: payment.method.displayName,
            iconColor: Colors.green.shade700,
            onEdit: () => _openEdit(context),
          ),
          if (payment.projectId != null)
            DetailInfoRow(
              icon: Icons.construction,
              label: 'Chantier',
              value: projectAsync.value?.label ?? '…',
              iconColor: Colors.green.shade700,
              onEdit: () => _openEdit(context),
            ),
          if (payment.note != null && payment.note!.isNotEmpty)
            DetailInfoRow(
              icon: Icons.notes,
              label: 'Note',
              value: payment.note!,
              isMultiline: true,
              iconColor: Colors.green.shade700,
              onEdit: () => _openEdit(context),
            ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Modifier'),
      ),
    );
  }
}
