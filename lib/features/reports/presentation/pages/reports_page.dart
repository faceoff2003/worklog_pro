import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';
import 'package:worklog_pro/features/reports/presentation/widgets/kpi_card.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/pdf/presentation/widgets/pdf_export_sheet.dart';
import 'package:worklog_pro/features/reports/presentation/providers/excel_provider.dart';
import 'package:worklog_pro/features/reports/presentation/utils/file_saver_util.dart';

class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  void _showPdfExport(BuildContext context, WidgetRef ref) {
    final filter = ref.read(reportFilterProvider);
    final reportAsync = ref.read(reportDataProvider);

    final report = reportAsync.valueOrNull;
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendez la fin du chargement du rapport')),
      );
      return;
    }

    // Try to resolve client and project from cached stream providers
    final clientId = filter.clientId;
    final projectId = filter.projectId;

    final clients = ref.read(clientsStreamProvider).valueOrNull ?? [];
    final client = clientId != null
        ? clients.where((c) => c.id == clientId).firstOrNull
        : null;

    // For project: look up from all projects watched by current client
    final projects = clientId != null
        ? (ref.read(projectsByClientStreamProvider(clientId)).valueOrNull ?? [])
        : [];
    final project = projectId != null
        ? projects.where((p) => p.id == projectId).firstOrNull
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PdfExportSheet(
        report: report,
        client: client,
        project: project,
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    final reportAsync = ref.read(reportDataProvider);
    final report = reportAsync.valueOrNull;

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Attendez la fin du chargement du rapport')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Génération du fichier Excel en cours...')),
    );

    try {
      final filter = ref.read(reportFilterProvider);
      final clients = ref.read(clientsStreamProvider).valueOrNull ?? [];
      final client = filter.clientId != null
          ? clients.where((c) => c.id == filter.clientId).firstOrNull
          : null;

      final projects = filter.clientId != null
          ? (ref.read(projectsByClientStreamProvider(filter.clientId!)).valueOrNull ?? [])
          : [];
      final project = filter.projectId != null
          ? projects.where((p) => p.id == filter.projectId).firstOrNull
          : null;

      final excelService = ref.read(excelExportServiceProvider);
      final bytes = await excelService.generateExcel(
        report,
        client: client,
        project: project,
      );

      final dateFormat = DateFormat('yyyyMMdd');
      final fileName = 'Rapport_${dateFormat.format(report.dateRange.start)}_${dateFormat.format(report.dateRange.end)}.xlsx';

      await FileSaverUtil.saveAndShareFile(
        bytes: bytes,
        fileName: fileName,
        mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export Excel terminé.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'export Excel : $e')),
        );
      }
    }
  }



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(reportFilterProvider);
    final reportAsync = ref.watch(reportDataProvider);
    final clientsAsync = ref.watch(clientsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: 'Exporter en Excel',
            onPressed: () => _exportExcel(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: 'Exporter en PDF',
            onPressed: () => _showPdfExport(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Date Range Filter
                InkWell(
                  onTap: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: filter.dateRange,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.indigo,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      ref.read(reportFilterProvider.notifier).updateDateRange(picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Période',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${DateFormat('dd/MM/yyyy').format(filter.dateRange.start)} - ${DateFormat('dd/MM/yyyy').format(filter.dateRange.end)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Client Filter
                clientsAsync.when(
                  data: (clients) {
                    return DropdownButtonFormField<String?>(
                      initialValue: filter.clientId,
                      decoration: const InputDecoration(
                        labelText: 'Client',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous les clients')),
                        ...clients.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (value) {
                         ref.read(reportFilterProvider.notifier).updateClient(value);
                      },
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, s) => Text('Erreur clients: $e'),
                ),
                // Project Filter (Only if client selected)
                if (filter.clientId != null) ...[
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final projectsAsync = ref.watch(projectsByClientStreamProvider(filter.clientId!));
                      return projectsAsync.when(
                        data: (projects) {
                          return DropdownButtonFormField<String?>(
                            initialValue: filter.projectId,
                            decoration: const InputDecoration(
                              labelText: 'Chantier',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.work),
                            ),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Tous les chantiers')),
                              ...projects.map((p) => DropdownMenuItem(value: p.id, child: Text(p.label))),

                            ],
                            onChanged: (value) {
                              ref.read(reportFilterProvider.notifier).updateProject(value);
                            },
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (e, s) => Text('Erreur projets: $e'),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          
          Expanded(
            child: reportAsync.when(
              data: (report) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // KPI Grid
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.4,
                      children: [
                        KPICard(
                          title: 'Production (CA)',
                          amount: report.totalProduction,
                          icon: Icons.trending_up,
                          color: Colors.blue,
                        ),
                        KPICard(
                          title: 'Dépenses',
                          amount: report.totalBillableExpenses + report.totalNonBillableExpenses,
                          icon: Icons.shopping_cart,
                          color: Colors.orange,
                        ),
                        KPICard(
                          title: 'Paiements Reçus',
                          amount: report.totalPayments,
                          icon: Icons.payments,
                          color: Colors.green,
                        ),
                        KPICard(
                          title: 'Reste à Percevoir', // Solde Théorique
                          amount: report.theoreticalBalance,
                          icon: Icons.account_balance_wallet,
                          color: report.theoreticalBalance.amountCents > 0 
                              ? Colors.red 
                              : (report.theoreticalBalance.amountCents < 0 ? Colors.purple : Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Detailed Breakdown Placeholder
                    // Ideally tabs here, but for simplicity let's list totals again or sections
                    const Text(
                      'Détails',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _DetailRow('Main d\'œuvre', report.totalLaborAmount),
                    _DetailRow('Marchandises (Refacturables)', report.totalBillableExpenses),
                    const Divider(),
                    _DetailRow('Total Production', report.totalProduction, isBold: true),
                    const SizedBox(height: 20),
                    _DetailRow('Frais Généraux (Non refacturables)', report.totalNonBillableExpenses),
                    
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Erreur calcul: $e')),
            ),
          ),
        ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final Money amount;
  final bool isBold;

  const _DetailRow(this.label, this.amount, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
          Text(
            amount.toEurosString(),
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
