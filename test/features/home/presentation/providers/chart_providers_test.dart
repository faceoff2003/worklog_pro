import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/home/presentation/providers/chart_providers.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

WorkEntry _entry(String id, DateTime date, int labor, int travel) => WorkEntry(
      id: id,
      date: DateOnly.fromDateTime(date),
      startTime: 480,
      endTime: 540,
      durationMinutes: 60,
      clientId: 'c1',
      billingMode: BillingMode.hourly,
      rateApplied: Money.fromCents(labor),
      laborAmountHT: Money.fromCents(labor),
      travelAmountHT: Money.fromCents(travel),
      createdAt: date,
      updatedAt: date,
    );

void main() {
  test('CA mensuel : main-d\'œuvre + déplacements, mois hors fenêtre ignorés', () async {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final container = ProviderContainer(overrides: [
      workEntriesStreamProvider.overrideWith((ref) => Stream.value([
            _entry('a', thisMonth, 10000, 1250),
            _entry('b', thisMonth, 5000, 0),
            _entry('old', DateTime(now.year, now.month - 7, 1), 99900, 100),
          ])),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(monthlyRevenueProvider, (_, __) {});
    while (sub.read().isLoading) {
      await Future<void>.delayed(Duration.zero);
    }

    final months = sub.read().requireValue;
    expect(months, hasLength(6));
    expect(months.last.month, thisMonth);
    expect(months.last.amount, 162.5);
    expect(months.take(5).every((m) => m.amount == 0), isTrue);
  });
}
