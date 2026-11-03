import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/settlement_provider.dart';

/// Dialog de confirmation pour solder le compte d'un client.
///
/// Affiche un résumé de la balance (total dû, total payé, reste)
/// et permet d'ajouter une note avant de confirmer.
///
/// Solde non nul : choix obligatoire, sans présélection, entre solder à zéro
/// et reporter le solde exact sur la période suivante (décisions §10.1-2 de
/// `doc/F-FIX-SOLDE_PARTIAL_DESIGN.md`). L'historique reste archivé.
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

  /// null tant que rien n'est choisi ; ignoré si le solde est nul.
  bool? _carryOver;

  bool get _needsChoice => widget.balance.balance != Money.zero;
  bool get _withCarry => _needsChoice && _carryOver == true;

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
          carryOver: _withCarry,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
        );

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _withCarry
                ? 'Compte de ${widget.clientName} soldé. '
                    'Report de ${widget.balance.balance.toEurosString()} sur la période suivante.'
                : 'Compte de ${widget.clientName} soldé. Balance remise à 0€.',
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
    final amount = Money.fromCents(balance.balance.amountCents.abs()).toEurosString();
    final archiveNote = !_needsChoice || _carryOver == false
        ? "À partir d'aujourd'hui, la balance repart de 0€."
        : _carryOver == true
            ? "À partir d'aujourd'hui, la balance repart de ${balance.balance.toEurosString()}."
            : 'Choisissez ce que devient le reste.';

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
            if (balance.carriedOver != Money.zero)
              _SummaryRow(
                label: 'Report du solde précédent',
                value: balance.carriedOver,
                color: Colors.grey.shade700,
              ),
            _SummaryRow(
              label: 'Total dû (M.O. + déplacements + dépenses)',
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
                text: 'Le client vous doit encore $amount.',
              )
            else if (isOverpaid)
              _InfoBanner(
                icon: Icons.info_outline,
                color: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
                text: 'Le client a payé $amount en avance.',
              )
            else
              _InfoBanner(
                icon: Icons.check_circle_outline,
                color: Colors.green.shade50,
                borderColor: Colors.green.shade200,
                text: 'Compte à l\'équilibre. Parfait moment pour solder !',
              ),

            if (_needsChoice) ...[
              const SizedBox(height: 8),
              RadioGroup<bool>(
                groupValue: _carryOver,
                onChanged: (value) => setState(() => _carryOver = value),
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      key: const ValueKey('settle_choice_zero'),
                      value: false,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Solder à zéro'),
                      subtitle: Text(isOverpaid ? "L'avance est abandonnée." : 'Le reste est abandonné.'),
                    ),
                    RadioListTile<bool>(
                      key: const ValueKey('settle_choice_carry'),
                      value: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(isOverpaid
                          ? "Solder avec report de l'avance de $amount"
                          : 'Solder avec report de $amount'),
                      subtitle: const Text('Repris sur la période suivante.'),
                    ),
                  ],
                ),
              ),
            ],

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
              '$archiveNote',
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
          key: const ValueKey('settle_confirm'),
          onPressed: _loading || (_needsChoice && _carryOver == null) ? null : _confirm,
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
