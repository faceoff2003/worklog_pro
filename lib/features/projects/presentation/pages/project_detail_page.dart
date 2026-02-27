import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/presentation/pages/project_form_page.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';

class ProjectDetailPage extends ConsumerWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProjectFormPage(project: project)),
    );
  }

  Color _statusColor(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.actif: return Colors.green;
      case ProjectStatus.termine: return Colors.grey;
      case ProjectStatus.en_attente: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const color = Colors.orange;
    final clientAsync = ref.watch(clientStreamProvider(project.clientId));

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(project.label),
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
                name: project.label,
                type: 'le chantier',
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(projectsControllerProvider.notifier)
                    .deleteProject(project.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status badge header
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _statusColor(project.status).withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _statusColor(project.status).withAlpha(80)),
              ),
              child: Text(
                project.status.displayName,
                style: TextStyle(
                  color: _statusColor(project.status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          const DetailSection(title: 'Informations'),
          DetailInfoRow(
            icon: Icons.construction,
            label: 'Libellé',
            value: project.label,
            iconColor: Colors.orange.shade700,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.category,
            label: 'Type',
            value: project.type.displayName,
            iconColor: Colors.orange.shade700,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.person,
            label: 'Client',
            value: clientAsync.value?.name ?? '…',
            iconColor: Colors.orange.shade700,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.flag,
            label: 'Statut',
            value: project.status.displayName,
            iconColor: _statusColor(project.status),
            onEdit: () => _openEdit(context),
          ),

          const DetailSection(title: 'Adresse'),
          DetailInfoRow(
            icon: Icons.location_on,
            label: 'Adresse',
            value: project.address.format(),
            iconColor: Colors.orange.shade700,
            isMultiline: true,
            onEdit: () => _openEdit(context),
          ),

          const DetailSection(title: 'Dates'),
          DetailInfoRow(
            icon: Icons.calendar_today,
            label: 'Créé le',
            value: DateFormat('dd/MM/yyyy').format(project.createdAt),
            iconColor: Colors.orange.shade700,
          ),
          DetailInfoRow(
            icon: Icons.update,
            label: 'Modifié le',
            value: DateFormat('dd/MM/yyyy').format(project.updatedAt),
            iconColor: Colors.orange.shade700,
          ),

          if (project.notes != null && project.notes!.isNotEmpty) ...[
            const DetailSection(title: 'Notes'),
            DetailInfoRow(
              icon: Icons.notes,
              label: 'Notes générales',
              value: project.notes!,
              isMultiline: true,
              iconColor: Colors.orange.shade700,
              onEdit: () => _openEdit(context),
            ),
          ],
          if (project.technicalNotes != null && project.technicalNotes!.isNotEmpty) ...[
            DetailInfoRow(
              icon: Icons.build,
              label: 'Notes techniques',
              value: project.technicalNotes!,
              isMultiline: true,
              iconColor: Colors.orange.shade700,
              onEdit: () => _openEdit(context),
            ),
          ],
          if (project.accessNotes != null && project.accessNotes!.isNotEmpty) ...[
            DetailInfoRow(
              icon: Icons.key,
              label: "Notes d'accès",
              value: project.accessNotes!,
              isMultiline: true,
              iconColor: Colors.orange.shade700,
              onEdit: () => _openEdit(context),
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Modifier'),
      ),
    );
  }
}
