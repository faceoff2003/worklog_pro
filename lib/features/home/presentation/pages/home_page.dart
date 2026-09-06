import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/features/home/presentation/providers/chart_providers.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/clients/presentation/pages/clients_list_page.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expenses_list_page.dart';
import 'package:worklog_pro/features/payments/presentation/pages/payments_list_page.dart';
import 'package:worklog_pro/features/projects/presentation/pages/projects_list_page.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/reports/presentation/pages/reports_page.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';
import 'package:worklog_pro/features/settings/presentation/pages/settings_page.dart';
import 'package:worklog_pro/features/timer/presentation/widgets/timer_floating_action_button.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entries_list_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/calendar_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final reportAsync = ref.watch(reportDataProvider);
    final filter = ref.watch(reportFilterProvider);

    final firstName = user?.displayName?.split(' ').first ?? 'Artisan';
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(filter.dateRange.start);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      floatingActionButton: const TimerFloatingActionButton(),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar / Header ──────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            collapsedHeight: 70,
            pinned: true,
            backgroundColor: Colors.indigo.shade700,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Paramètres',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsPage()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                tooltip: 'Déconnexion',
                onPressed: () async {
                  final controller = ref.read(authControllerProvider.notifier);
                  await controller.signOut();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade800, Colors.indigo.shade500],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withAlpha(40),
                              radius: 22,
                              child: Text(
                                firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bonjour, $firstName 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  monthLabel,
                                  style: TextStyle(
                                    color: Colors.white.withAlpha(180),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        // Inline mini stats
                        reportAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (report) => Row(
                            children: [
                              _miniStat(
                                label: 'CA',
                                value: report.totalProduction.toEurosString(),
                                icon: Icons.trending_up,
                              ),
                              const SizedBox(width: 24),
                              _miniStat(
                                label: 'Encaissé',
                                value: report.totalPayments.toEurosString(),
                                icon: Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 24),
                              _miniStat(
                                label: 'Prestations',
                                value: '${report.workEntries.length}',
                                icon: Icons.access_time,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI Cards
                _SectionHeader(title: 'Résumé du mois', onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportsPage()),
                  );
                }),
                const SizedBox(height: 10),
                reportAsync.when(
                  loading: () => const _KpiSkeleton(),
                  error: (e, _) => _ErrorBanner(message: e.toString()),
                  data: (report) => _KpiGrid(report: report, context: context),
                ),
                const SizedBox(height: 24),

                // Revenue chart
                const _SectionHeader(title: 'Chiffre d\'affaires — 6 derniers mois'),
                const SizedBox(height: 10),
                const _RevenueChart(),
                const SizedBox(height: 24),

                // Navigation grid
                const _SectionHeader(title: 'Navigation'),
                const SizedBox(height: 10),
                _NavGrid(context: context),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white.withAlpha(180), size: 13),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionHeader({required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Text(
              'Voir tout →',
              style: TextStyle(fontSize: 13, color: Colors.indigo.shade600),
            ),
          ),
      ],
    );
  }
}

// ── KPI Grid ──────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  final ReportData report;
  final BuildContext context;
  const _KpiGrid({required this.report, required this.context});

  @override
  Widget build(BuildContext context) {
    // Compute worked hours
    final totalMinutes = report.workEntries.fold<int>(
      0,
      (sum, e) => sum + e.durationMinutes,
    );
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final hoursLabel = minutes > 0 ? '${hours}h${minutes.toString().padLeft(2, '0')}' : '${hours}h';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Chiffre d\'affaires',
                value: report.totalProduction.toEurosString(),
                icon: Icons.euro_rounded,
                color: Colors.indigo,
                subtitle: 'Prestations + Dépenses fact.',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Encaissé',
                value: report.totalPayments.toEurosString(),
                icon: Icons.payments_outlined,
                color: Colors.green.shade600,
                subtitle: 'Acomptes & paiements',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'À facturer',
                value: report.theoreticalBalance.toEurosString(),
                icon: Icons.pending_actions,
                color: report.theoreticalBalance.amountCents > 0
                    ? Colors.orange.shade700
                    : Colors.green.shade600,
                subtitle: 'CA − Encaissé',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Heures',
                value: hoursLabel,
                icon: Icons.access_time_filled,
                color: Colors.teal,
                subtitle: '${report.workEntries.length} prestas',
                isTime: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Dépenses fact.',
                value: report.totalBillableExpenses.toEurosString(),
                icon: Icons.receipt_long,
                color: Colors.purple.shade600,
                subtitle: 'Refacturables client',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _KpiCard(
                label: 'Frais internes',
                value: report.totalNonBillableExpenses.toEurosString(),
                icon: Icons.local_atm,
                color: Colors.red.shade400,
                subtitle: 'Non refacturables',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;
  final bool isTime;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
    this.isTime = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Navigation Grid ───────────────────────────────────────────────────────────
class _NavGrid extends StatelessWidget {
  final BuildContext context;
  const _NavGrid({required this.context});

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.people_rounded, label: 'Clients', color: Colors.blue.shade600, page: const ClientsListPage()),
      _NavItem(icon: Icons.construction_rounded, label: 'Chantiers', color: Colors.orange.shade700, page: const ProjectsListPage()),
      _NavItem(icon: Icons.access_time_filled_rounded, label: 'Prestations', color: Colors.green.shade600, page: const WorkEntriesListPage()),
      _NavItem(icon: Icons.calendar_month_rounded, label: 'Calendrier', color: Colors.blueAccent.shade400, page: const CalendarPage()),
      _NavItem(icon: Icons.receipt_long_rounded, label: 'Dépenses', color: Colors.purple.shade600, page: const ExpensesListPage()),
      _NavItem(icon: Icons.payments_rounded, label: 'Paiements', color: Colors.teal.shade600, page: const PaymentsListPage()),
      _NavItem(icon: Icons.bar_chart_rounded, label: 'Rapports', color: Colors.indigo.shade600, page: const ReportsPage()),
      _NavItem(icon: Icons.settings_rounded, label: 'Paramètres', color: Colors.grey.shade600, page: const SettingsPage()),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _NavTile(item: items[i]),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final Color color;
  final Widget page;
  const _NavItem({required this.icon, required this.label, required this.color, required this.page});
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  const _NavTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => item.page),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton loader ───────────────────────────────────────────────────────────
class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: List.generate(2, (__) => Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )),
        ),
      )),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: Colors.red.shade700, fontSize: 12))),
        ],
      ),
    );
  }
}

class _RevenueChart extends ConsumerWidget {
  const _RevenueChart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chartAsync = ref.watch(monthlyRevenueProvider);
    final theme = Theme.of(context);
    final monthFmt = DateFormat('MMM', 'fr_FR');

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
      child: chartAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (months) {
          if (months.isEmpty || months.every((m) => m.amount == 0)) {
            return Center(
              child: Text('Aucune donnée', style: TextStyle(color: theme.hintColor)),
            );
          }
          final maxVal = months.map((m) => m.amount).reduce((a, b) => a > b ? a : b);
          return BarChart(
            BarChartData(
              maxY: maxVal * 1.25 + 1,
              gridData: FlGridData(
                show: true,
                horizontalInterval: maxVal > 0 ? maxVal / 4 : 100,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: theme.dividerColor.withAlpha(80),
                  strokeWidth: 0.8,
                ),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 48,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '${(value / 1000).toStringAsFixed(0)}k€',
                        style: TextStyle(fontSize: 10, color: theme.hintColor),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= months.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          monthFmt.format(months[idx].month),
                          style: TextStyle(fontSize: 11, color: theme.hintColor),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barGroups: months.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.amount,
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade300, Colors.indigo.shade600],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      width: 20,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
