import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/core/widgets/detail_info_row.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_form_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class WorkEntryDetailPage extends ConsumerWidget {
  final WorkEntry entry;
  const WorkEntryDetailPage({super.key, required this.entry});

  void _openEdit(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => WorkEntryFormPage(workEntry: entry)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calculator = ref.read(workCalculatorServiceProvider);
    final clientAsync = ref.watch(clientStreamProvider(entry.clientId));
    final AsyncValue<Project?> projectAsync = entry.projectId != null
        ? ref.watch(projectStreamProvider(entry.projectId!))
        : const AsyncData<Project?>(null);

    final hours = entry.durationMinutes ~/ 60;
    final minutes = entry.durationMinutes % 60;
    final durationLabel = minutes > 0
        ? '${hours}h${minutes.toString().padLeft(2, '0')}'
        : '${hours}h';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: Text(entry.date.formatLongFrench()),
        backgroundColor: Colors.blueAccent,
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
                name: '${calculator.formatTime(entry.startTime)} → ${calculator.formatTime(entry.endTime)}',
                type: 'la prestation du',
              );
              if (confirmed == true && context.mounted) {
                await ref
                    .read(workEntriesControllerProvider.notifier)
                    .deleteWorkEntry(entry.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero: amount
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _HeroStat(
                  icon: Icons.euro,
                  value: entry.laborAmountHT.toEurosString(),
                  label: 'Montant HT',
                  color: Colors.blue.shade700,
                ),
                _HeroStat(
                  icon: Icons.access_time,
                  value: durationLabel,
                  label: 'Durée',
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const DetailSection(title: 'Horaires'),
          DetailInfoRow(
            icon: Icons.play_circle_outline,
            label: 'Début',
            value: calculator.formatTime(entry.startTime),
            iconColor: Colors.blue.shade600,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.stop_circle_outlined,
            label: 'Fin',
            value: calculator.formatTime(entry.endTime),
            iconColor: Colors.blue.shade600,
            onEdit: () => _openEdit(context),
          ),
          if (entry.pauseMinutes > 0)
            DetailInfoRow(
              icon: Icons.pause_circle_outline,
              label: 'Pause',
              value: '${entry.pauseMinutes} min',
              iconColor: Colors.blue.shade600,
              onEdit: () => _openEdit(context),
            ),

          const DetailSection(title: 'Facturation'),
          DetailInfoRow(
            icon: Icons.person,
            label: 'Client',
            value: clientAsync.value?.name ?? '…',
            iconColor: Colors.blue.shade600,
            onEdit: () => _openEdit(context),
          ),
          if (entry.projectId != null)
            DetailInfoRow(
              icon: Icons.construction,
              label: 'Chantier',
              value: projectAsync.value?.label ?? '…',
              iconColor: Colors.blue.shade600,
              onEdit: () => _openEdit(context),
            ),
          DetailInfoRow(
            icon: Icons.monetization_on_outlined,
            label: 'Mode de facturation',
            value: entry.billingMode.displayName,
            iconColor: Colors.blue.shade600,
            onEdit: () => _openEdit(context),
          ),
          DetailInfoRow(
            icon: Icons.euro,
            label: 'Tarif appliqué',
            value: entry.rateApplied.toEurosString(),
            iconColor: Colors.blue.shade600,
            onEdit: () => _openEdit(context),
          ),

          if (entry.tasks.isNotEmpty) ...[
            const DetailSection(title: 'Tâches réalisées'),
            ...entry.tasks.map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(child: Text(task, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],

          if (entry.notes != null && entry.notes!.isNotEmpty) ...[
            const DetailSection(title: 'Notes'),
            DetailInfoRow(
              icon: Icons.notes,
              label: 'Notes',
              value: entry.notes!,
              isMultiline: true,
              iconColor: Colors.blue.shade600,
              onEdit: () => _openEdit(context),
            ),
          ],

          if (entry.timerUsed)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Icon(Icons.timer, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    'Enregistré via le minuteur',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEdit(context),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit),
        label: const Text('Modifier'),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HeroStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
