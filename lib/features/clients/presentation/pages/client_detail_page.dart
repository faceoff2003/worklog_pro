import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_form_page.dart';
import 'package:worklog_pro/features/clients/presentation/pages/settle_account_dialog.dart';
import 'package:worklog_pro/features/clients/presentation/providers/client_balance_providers.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';

class ClientDetailPage extends ConsumerWidget {
  final Client client;
  const ClientDetailPage({super.key, required this.client});

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ClientFormPage(client: client)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const color = Colors.indigo;
    final balanceAsync = ref.watch(clientBalanceProvider(client.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(client.name),
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
                name: client.name,
                type: 'le client',
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(clientsControllerProvider.notifier)
                    .deleteClient(client.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.indigo.shade100,
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Colors.indigo.shade700,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  client.type.displayName,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Section COMPTE (balance + solde) ─────────────────────────────
          balanceAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, stack) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Erreur: $e')),
            ),
            data: (balance) => _AccountSection(
              client: client,
              balance: balance,
              ref: ref,
            ),
          ),

          const SizedBox(height: 8),

          // Informations générales
          const DetailSection(title: 'Informations'),
          DetailInfoRow(
            icon: Icons.person,
            label: 'Nom',
            value: client.name,
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.business,
            label: 'Type',
            value: client.type.displayName,
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),

          // Contact
          const DetailSection(title: 'Contact'),
          DetailInfoRow(
            icon: Icons.phone,
            label: 'Téléphone',
            value: client.phone ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.email,
            label: 'Email',
            value: client.email ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),

          // Tarifs
          const DetailSection(title: 'Tarifs par défaut'),
          DetailInfoRow(
            icon: Icons.access_time,
            label: 'Tarif horaire',
            value: client.defaultRates.hour?.toEurosString() ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Demi-journée',
            value: client.defaultRates.halfDay?.toEurosString() ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: 'Journée',
            value: client.defaultRates.day?.toEurosString() ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.workspaces_outline,
            label: 'Forfait',
            value: client.defaultRates.fixedJob?.toEurosString() ?? '',
            iconColor: color,
            onEdit: () => _openEdit(context),
          ),

          // Notes
          if (client.notes != null && client.notes!.isNotEmpty) ...[
            const DetailSection(title: 'Notes'),
            DetailInfoRow(
              icon: Icons.notes,
              label: 'Notes',
              value: client.notes!,
              iconColor: color,
              isMultiline: true,
              onEdit: () => _openEdit(context),
            ),
          ],

          // Tags
          if (client.tags.isNotEmpty) ...[
            const DetailSection(title: 'Tags'),
            Wrap(
              spacing: 8,
              children: client.tags
                  .map((tag) => Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        backgroundColor: Colors.indigo.shade50,
                        side: BorderSide(color: Colors.indigo.shade200),
                      ))
                  .toList(),
            ),
          ],

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

/// Section "Compte" affichant la balance et le bouton de solde.
class _AccountSection extends StatelessWidget {
  final Client client;
  final ClientBalance balance;
  final WidgetRef ref;

  const _AccountSection({
    required this.client,
    required this.balance,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final balanceColor = balance.isPaid
        ? Colors.green.shade700
        : balance.isOverpaid
            ? Colors.blue.shade700
            : Colors.red.shade700;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: Colors.indigo, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Compte client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.indigo,
                  ),
                ),
                const Spacer(),
                // Badge "soldé le XX/XX/XXXX"
                if (balance.hasBeenSettled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Text(
                      'Soldé le ${balance.settlementDate!.formatEuropean()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Lignes de balance
            _BalanceRow(
              label: 'Total M.O. + dépenses',
              value: balance.totalDue.toEurosString(),
              valueColor: Colors.grey.shade700,
            ),
            _BalanceRow(
              label: 'Total encaissé',
              value: '- ${balance.totalPayments.toEurosString()}',
              valueColor: Colors.green.shade700,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6),
              child: Divider(height: 1),
            ),
            _BalanceRow(
              label: 'Solde actuel',
              value: balance.balance.toEurosString(),
              valueColor: balanceColor,
              bold: true,
            ),

            const SizedBox(height: 14),

            // Bouton "Solder le compte"
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showSettleAccountDialog(
                  context: context,
                  ref: ref,
                  clientId: client.id,
                  clientName: client.name,
                  balance: balance,
                ),
                icon: const Icon(Icons.balance, size: 18),
                label: const Text('Remettre le compte à zéro'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Info dernier solde si existant
            if (balance.hasBeenSettled && balance.balanceAtLastSettlement != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Solde archivé : ${balance.balanceAtLastSettlement!.toEurosString()} '
                  'au ${balance.settlementDate!.formatEuropean()}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool bold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: valueColor,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
