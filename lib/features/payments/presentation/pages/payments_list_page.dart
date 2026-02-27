import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/core/constants/enums.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/features/payments/presentation/pages/payment_detail_page.dart';
import 'package:worklog_pro/features/payments/presentation/pages/payment_form_page.dart';
import 'package:worklog_pro/features/payments/presentation/providers/payments_provider.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';

class PaymentsListPage extends ConsumerWidget {
  final String? clientId;

  const PaymentsListPage({super.key, this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsStreamProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paiements'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: paymentsAsync.when(
        data: (payments) {
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun paiement',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by month
          final groupedPayments = <String, List<dynamic>>{};
          for (var payment in payments) {
             final monthKey = DateFormat('MMMM yyyy', 'fr_FR').format(payment.date.toDateTime());
             if (!groupedPayments.containsKey(monthKey)) {
               groupedPayments[monthKey] = [];
             }
             groupedPayments[monthKey]!.add(payment);
          }

          return ListView.builder(
            itemCount: groupedPayments.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final monthKey = groupedPayments.keys.elementAt(index);
              final monthPayments = groupedPayments[monthKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      monthKey.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                  ...monthPayments.map((payment) {
                    final clientAsync = ref.watch(clientStreamProvider(payment.clientId));
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(
                            _getPaymentMethodIcon(payment.method),
                            color: Colors.green.shade700,
                            size: 20,
                          ),
                        ),
                        title: clientAsync.when(
                          data: (client) => Text(
                            client?.name ?? 'Client inconnu',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          loading: () => const Text('Chargement...'),
                          error: (_, __) => const Text('Erreur'),
                        ),
                        subtitle: Row(
                          children: [
                            Text(DateFormat('dd/MM/yyyy').format(payment.date.toDateTime())),
                            const SizedBox(width: 8),
                            Text(
                              payment.method.displayName,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              payment.amount.toEurosString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.green,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: Colors.green.shade400, size: 20),
                              tooltip: 'Modifier',
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PaymentFormPage(payment: payment)),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                              tooltip: 'Supprimer',
                              onPressed: () async {
                                final clientName = ref.read(clientStreamProvider(payment.clientId)).value?.name ?? '';
                                // ignore: use_build_context_synchronously
                                final confirmed = await showDeleteConfirmDialog(
                                  context,
                                  name: '${payment.amount.toEurosString()} — $clientName',
                                  type: 'le paiement',
                                );
                                if (confirmed == true) {
                                  await ref.read(paymentsControllerProvider.notifier).deletePayment(payment.id);
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => PaymentDetailPage(payment: payment),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Erreur: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentFormPage(clientId: clientId),
            ),
          );
        },
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.virement:
        return Icons.account_balance;
      case PaymentMethod.autre:
        return Icons.payment;
    }
  }
}
