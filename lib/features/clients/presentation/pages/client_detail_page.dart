import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_form_page.dart';
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
    final color = Colors.indigo;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(client.name),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier tout',
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
                  backgroundColor: color.shade100,
                  child: Text(
                    client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: color.shade700,
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
                        backgroundColor: color.shade50,
                        side: BorderSide(color: color.shade200),
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
