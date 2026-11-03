import 'package:flutter/material.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';

/// Badge affichant le statut de paiement calculé d'une prestation.
class WorkEntryStatusBadge extends StatelessWidget {
  final WorkEntryPaymentStatus status;

  const WorkEntryStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final MaterialColor color;
    switch (status.state) {
      case WorkEntryPaymentState.settled:
        color = Colors.grey;
      case WorkEntryPaymentState.paid:
        color = Colors.green;
      case WorkEntryPaymentState.partial:
        color = Colors.orange;
      case WorkEntryPaymentState.unpaid:
        color = Colors.red;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.shade300),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, color: color.shade800, fontWeight: FontWeight.w600),
      ),
    );
  }
}
