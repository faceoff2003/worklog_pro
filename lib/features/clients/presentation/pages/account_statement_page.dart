import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/clients/domain/services/account_statement_service.dart';
import 'package:worklog_pro/features/clients/presentation/providers/account_statement_provider.dart';
import 'package:worklog_pro/features/clients/presentation/widgets/work_entry_status_badge.dart';

/// Relevé de compte d'un client : affichage seul, tout est calculé par
/// [AccountStatementService].
class AccountStatementPage extends ConsumerWidget {
  final String clientId;
  final String clientName;

  const AccountStatementPage({super.key, required this.clientId, required this.clientName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statementAsync = ref.watch(accountStatementProvider(clientId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Relevé — $clientName'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: statementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (statement) {
          if (statement.lines.isEmpty) {
            return const Center(child: Text('Aucune opération'));
          }
          return Column(
            children: [
              _BalanceHeader(statement: statement),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: statement.lines.length,
                  itemBuilder: (context, index) {
                    final line = statement.lines[index];
                    return line.type == StatementLineType.settlement
                        ? _SettlementSeparator(line: line)
                        : _LineTile(line: line);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _BalanceHeader extends StatelessWidget {
  final AccountStatement statement;

  const _BalanceHeader({required this.statement});

  @override
  Widget build(BuildContext context) {
    final cents = statement.balance.amountCents;
    return Container(
      width: double.infinity,
      color: Colors.indigo.shade50,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(cents < 0 ? 'Avance du client' : 'Solde actuel', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            statement.balance.toEurosString(),
            key: const ValueKey('statement_balance'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: cents > 0 ? Colors.red.shade700 : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementSeparator extends StatelessWidget {
  final StatementLine line;

  const _SettlementSeparator({required this.line});

  @override
  Widget build(BuildContext context) {
    final dayMonth = line.date.formatEuropean().substring(0, 5);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        children: [
          Text(
            '── COMPTE SOLDÉ le $dayMonth ──',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.indigo.shade700),
          ),
          Text(
            'Solde archivé : ${line.amount.toEurosString()}',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final StatementLine line;

  const _LineTile({required this.line});

  String get _title {
    switch (line.type) {
      case StatementLineType.workEntry:
        return 'Prestation';
      case StatementLineType.expense:
        return 'Dépense';
      case StatementLineType.payment:
        return 'Paiement';
      case StatementLineType.settlement:
        return 'Solde';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = line.isArchived ? Colors.grey : Colors.black87;
    final isPayment = line.type == StatementLineType.payment;
    final description = line.description;
    final status = line.status;
    final enteredOn = line.enteredOn;

    return Opacity(
      key: ValueKey('statement_line_${line.id}'),
      opacity: line.isArchived ? 0.6 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${line.date.formatEuropean()} · $_title',
                      style: TextStyle(fontWeight: FontWeight.w600, color: color)),
                  if (enteredOn != null)
                    Text('saisie le ${enteredOn.formatEuropean().substring(0, 5)}',
                        style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.orange.shade800)),
                  if (description != null && description.isNotEmpty)
                    Text(description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  if (status != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: WorkEntryStatusBadge(status: status),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(line.amount.toEurosString(),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isPayment && !line.isArchived ? Colors.green.shade700 : color,
                    )),
                Text('Solde : ${line.runningBalance.toEurosString()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
