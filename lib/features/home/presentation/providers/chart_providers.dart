import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

/// Monthly revenue bar chart data — last 6 months
final monthlyRevenueProvider = Provider<AsyncValue<List<MonthRevenue>>>((ref) {
  final entriesAsync = ref.watch(workEntriesStreamProvider);
  return entriesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
    data: (entries) {
      final now = DateTime.now();
      final months = List.generate(6, (i) {
        final d = DateTime(now.year, now.month - 5 + i);
        return DateTime(d.year, d.month);
      });

      final map = <DateTime, double>{};
      for (final m in months) {
        map[m] = 0;
      }

      for (final e in entries) {
        final date = e.date.toDateTime();
        final key = DateTime(date.year, date.month);
        if (map.containsKey(key)) {
          map[key] = (map[key] ?? 0) + e.laborAmountHT.inEuros;
        }
      }

      final result = months.map((m) => MonthRevenue(month: m, amount: map[m] ?? 0)).toList();
      return AsyncValue.data(result);
    },
  );
});

class MonthRevenue {
  final DateTime month;
  final double amount;
  const MonthRevenue({required this.month, required this.amount});
}
