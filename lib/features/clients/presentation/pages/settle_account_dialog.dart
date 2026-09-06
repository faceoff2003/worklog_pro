import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';

/// Dialog de confirmation pour solder le compte d'un client.
///
/// Affiche un résumé de la balance (total dû, total payé, reste)
/// et permet d'ajouter une note avant de confirmer la remise à zéro.
///
/// Après confirmation, la balance courante redémarre de 0€.
/// L'historique reste archivé et consultable.
Future<void> showSettleAccountDialog({
  required BuildContext context,
  required WidgetRef ref,
  required String clientId,
  required String clientName,
  required ClientBalance balance,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _SettleAccountDialog(
      clientId: clientId,
      clientName: clientName,
      balance: balance,
    ),
  );
}

class _SettleAccountDialog extends ConsumerStatefulWidget {
  final String clientId;
  final String clientName;
  final ClientBalance balance;

  const _SettleAccountDialog({
    required this.clientId,
    required this.clientName,
    required this.balance,
  });

  @override
  ConsumerState<_SettleAccountDialog> createState() =>
      _SettleAccountDialogState();
}

class _SettleAccountDialogState extends ConsumerState<_SettleAccountDialog> {
  final _noteController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _loading = true);
    await ref.read(settlementsControllerProvider.notifier).settle(
          clientId: widget.clientId,
          currentBalance: widget.balance.balance,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compte de ${widget.clientName} soldé. Balance remise à 0€.',
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = widget.balance;
    final isInDebt = balance.balance.amountCents > 0;
    final isOverpaid = balance.isOverpaid;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.balance, color: Colors.indigo),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Solder le compte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.clientName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),

            // Résumé financier
            _SummaryRow(
              label: 'Total dû (M.O. + dépenses)',
              value: balance.totalDue,
              color: Colors.grey.shade700,
            ),
            _SummaryRow(
              label: 'Total encaissé',
              value: balance.totalPayments,
              color: Colors.green.shade700,
            ),
            const Divider(height: 20),
            _SummaryRow(
              label: 'Reste à solder',
              value: balance.balance,
              color: isOverpaid
                  ? Colors.green.shade700
                  : isInDebt
                      ? Colors.red.shade700
                      : Colors.grey.shade700,
              bold: true,
            ),

            const SizedBox(height: 16),

            // Avertissement contextuel
            if (isInDebt)
              _InfoBanner(
                icon: Icons.info_outline,
                color: Colors.orange.shade100,
                borderColor: Colors.orange.shade300,
                text:
                    'Le client vous doit encore ${balance.balance.toEurosString()}. '
                    'Le solde sera enregistré à 0€ quand même.',
              )
            else if (isOverpaid)
              _InfoBanner(
                icon: Icons.info_outline,
                color: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
                text: 'Le client a payé en avance. Solde négatif enregistré.',
              )
            else
              _InfoBanner(
                icon: Icons.check_circle_outline,
                color: Colors.green.shade50,
                borderColor: Colors.green.shade200,
                text: 'Compte à l\'équilibre. Parfait moment pour solder !',
              ),

            const SizedBox(height: 16),

            // Note optionnelle
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Note (optionnelle)',
                hintText: 'Ex: Règlement final chantier Avenue Louise',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.notes_outlined),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.done,
            ),

            const SizedBox(height: 16),

            // Note d'archivage
            Text(
              '⚠️ Les données historiques restent archivées et consultables. '
              'À partir d\'aujourd\'hui, la balance repart de 0€.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _confirm,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('Confirmer le solde'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.indigo,
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final Money value;
  final Color color;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value.toEurosString(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color borderColor;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: borderColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
