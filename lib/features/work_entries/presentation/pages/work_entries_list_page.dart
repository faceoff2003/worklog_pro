import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/core/widgets/delete_confirm_dialog.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_calculator_service.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_detail_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_form_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

class WorkEntriesListPage extends ConsumerWidget {
  final String? clientId;
  final String? projectId;

  const WorkEntriesListPage({super.key, this.clientId, this.projectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which provider to use
    final AsyncValue<List<WorkEntry>> entriesAsync;
    if (projectId != null) {
      entriesAsync = ref.watch(workEntriesByProjectStreamProvider(projectId!));
    } else if (clientId != null) {
      entriesAsync = ref.watch(workEntriesByClientStreamProvider(clientId!));
    } else {
      entriesAsync = ref.watch(workEntriesStreamProvider);
    }

    final calculator = ref.read(workCalculatorServiceProvider);
    
    final String title = projectId != null ? 'Prestations (Chantier)' : 
                         clientId != null ? 'Prestations (Client)' : 
                         'Journal des Prestations';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Icon(Icons.history, size: 80, color: Colors.grey.shade300),
                   const SizedBox(height: 16),
                   Text('Aucune prestation', style: TextStyle(color: Colors.grey.shade600, fontSize: 18)),
                ],
              ),
            );
          }

          // Group by Date
          final grouped = <DateOnly, List<WorkEntry>>{};
          for (var entry in entries) {
            if (!grouped.containsKey(entry.date)) {
              grouped[entry.date] = [];
            }
            grouped[entry.date]!.add(entry);
          }
          
          // Sort dates descending
          final sortedDates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDates.length,
            itemBuilder: (context, index) {
              final date = sortedDates[index];
              final dateEntries = grouped[date]!;
              
              // Calculate daily total
              Money dailyTotal = Money.zero;
              int dailyMinutes = 0;
              for (var e in dateEntries) {
                dailyTotal += e.laborAmountHT; // Using LaborAmountHT which should be the total cost
                dailyMinutes += e.durationMinutes;
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateHeader(date: date, totalDuration: dailyMinutes, totalAmount: dailyTotal),
                  ...dateEntries.map((entry) => _WorkEntryCard(entry: entry, calculator: calculator)),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e,s) => Center(child: Text('Erreur: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WorkEntryFormPage(
                initialClientId: clientId,
                initialProjectId: projectId,
              ),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateOnly date;
  final int totalDuration;
  final Money totalAmount;

  const _DateHeader({required this.date, required this.totalDuration, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date.formatLongFrench(),
            style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Row(
            children: [
               Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
               const SizedBox(width: 4),
               Text(
                 '${(totalDuration / 60).toStringAsFixed(1)}h',
                 style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
               ),
               const SizedBox(width: 12),
               Text(
                 totalAmount.toEurosString(),
                 style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
               ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WorkEntryCard extends ConsumerWidget {
  final WorkEntry entry;
  final WorkCalculatorService calculator;

  const _WorkEntryCard({required this.entry, required this.calculator});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch Client Name
    final clientAsync = ref.watch(clientStreamProvider(entry.clientId));
    
    // Fetch Project Name if exists
    final projectAsync = entry.projectId != null 
        ? ref.watch(projectStreamProvider(entry.projectId!)) 
        : const AsyncValue.data(null);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
            Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => WorkEntryDetailPage(entry: entry)),
            );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   // Time Range
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                     decoration: BoxDecoration(
                       color: Colors.blue.shade50,
                       borderRadius: BorderRadius.circular(8),
                     ),
                     child: Text(
                       '${calculator.formatTime(entry.startTime)} - ${calculator.formatTime(entry.endTime)}',
                       style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600, fontSize: 12),
                     ),
                   ),
                   Row(
                     mainAxisSize: MainAxisSize.min,
                     children: [
                       // Amount
                       Text(
                         entry.laborAmountHT.toEurosString(),
                         style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                       ),
                       PopupMenuButton<String>(
                         icon: Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
                         onSelected: (value) async {
                           if (value == 'edit') {
                             Navigator.of(context).push(
                               MaterialPageRoute(builder: (_) => WorkEntryFormPage(workEntry: entry)),
                             );
                           } else if (value == 'delete') {
                             final confirmed = await showDeleteConfirmDialog(
                               context,
                               name: '${calculator.formatTime(entry.startTime)} - ${calculator.formatTime(entry.endTime)}',
                               type: 'la prestation du',
                             );
                             if (confirmed == true) {
                               await ref.read(workEntriesControllerProvider.notifier).deleteWorkEntry(entry.id);
                             }
                           }
                         },
                         itemBuilder: (_) => [
                           const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Modifier')])),
                           PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400), const SizedBox(width: 8), const Text('Supprimer', style: TextStyle(color: Colors.red))])),
                         ],
                       ),
                     ],
                   ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                   const Icon(Icons.person, size: 16, color: Colors.grey),
                   const SizedBox(width: 4),
                   Expanded(
                     child: clientAsync.when(
                       data: (c) => Text(c?.name ?? 'Client inconnu', style: const TextStyle(fontWeight: FontWeight.w500)),
                       loading: () => const Text('...', style: TextStyle(color: Colors.grey)),
                       error: (_,__) => const Text('Erreur'),
                     ),
                   ),
                ],
              ),
              if (entry.projectId != null) ...[
                 const SizedBox(height: 4),
                 Row(
                    children: [
                       const Icon(Icons.construction, size: 16, color: Colors.grey),
                       const SizedBox(width: 4),
                       Expanded(
                         child: projectAsync.when(
                           data: (p) => Text(p?.label ?? 'Chantier inconnu', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                           loading: () => const SizedBox(),
                           error: (_,__) => const SizedBox(),
                         ),
                       ),
                    ],
                 ),
              ],
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Icon(Icons.notes, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(child: Text(entry.notes!, style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
