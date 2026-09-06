// Caractérisation des transitions d'état de ReportFilter (R-SEC.3 étape 3,
// point 4). Testé directement au niveau du provider/contrôleur plutôt que
// via ReportsPage : la vraie logique à risque est entièrement dans quel
// champ est préservé/réinitialisé par chaque transition, pas dans le
// câblage des dropdowns eux-mêmes (un onChanged direct chacun, typage
// statique). Monter tout ReportsPage nécessiterait de simuler 8+ providers
// de flux (clients, projets, workEntries ×3, expenses ×3, payments) sans
// rapport avec ce qui change ici.
//
// Après extraction vers ReportFilterController (updateDateRange/
// updateClient/updateProject), les mêmes scénarios sont réexercés via la
// nouvelle API publique — la sortie doit rester strictement identique.

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';

void main() {
  late ProviderContainer container;
  late ReportFilterController notifier;

  setUp(() {
    container = ProviderContainer();
    notifier = container.read(reportFilterProvider.notifier);
  });

  tearDown(() {
    container.dispose();
  });

  ReportFilter currentFilter() => container.read(reportFilterProvider);

  test('état initial : ReportFilter.initial() — mois courant, aucun filtre', () {
    final filter = currentFilter();
    expect(filter.clientId, isNull);
    expect(filter.projectId, isNull);
    final now = DateTime.now();
    expect(filter.dateRange.start, DateTime(now.year, now.month, 1));
    expect(filter.dateRange.end, DateTime(now.year, now.month + 1, 0));
  });

  group('updateDateRange (date range picker)', () {
    test('met à jour dateRange, préserve clientId et projectId', () {
      final initialRange = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      notifier.updateDateRange(initialRange);
      notifier.updateClient('client-1');
      notifier.updateProject('project-1');

      final newRange = DateTimeRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 28));
      notifier.updateDateRange(newRange);

      expect(currentFilter().dateRange, newRange);
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().projectId, 'project-1');
    });
  });

  group('updateClient (dropdown Client)', () {
    test('sélectionner un client réinitialise le chantier, préserve la période', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      notifier.updateDateRange(range);

      notifier.updateClient('client-1');

      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().projectId, isNull);
      expect(currentFilter().dateRange, range);
    });

    test(
      'revenir à "Tous les clients" (null) efface aussi le chantier — '
      'copyWith(clientId: null) ne le ferait PAS (null == paramètre omis)',
      () {
        final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
        notifier.updateDateRange(range);
        notifier.updateClient('client-1');
        notifier.updateProject('project-1');

        // updateClient(null) doit effacer clientId ET projectId. C'est
        // pourquoi updateClient construit un ReportFilter brut plutôt que
        // d'utiliser copyWith(clientId: null), qui serait un no-op :
        // `clientId: clientId ?? this.clientId` ne distingue pas un null
        // explicite d'un paramètre omis.
        notifier.updateClient(null);

        expect(currentFilter().clientId, isNull);
        expect(currentFilter().projectId, isNull);
        expect(currentFilter().dateRange, range);
      },
    );
  });

  group('updateProject (dropdown Chantier)', () {
    test('sélectionner un chantier met à jour projectId, préserve client et période', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      notifier.updateDateRange(range);
      notifier.updateClient('client-1');

      notifier.updateProject('project-1');

      expect(currentFilter().projectId, 'project-1');
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().dateRange, range);
    });

    test('revenir à "Tous les chantiers" (null) efface projectId via clearProject', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      notifier.updateDateRange(range);
      notifier.updateClient('client-1');
      notifier.updateProject('project-1');

      notifier.updateProject(null);

      expect(currentFilter().projectId, isNull);
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().dateRange, range);
    });
  });
}
