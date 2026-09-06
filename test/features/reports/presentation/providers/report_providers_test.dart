// Caractérisation des transitions d'état de ReportFilter (R-SEC.3 étape 3,
// point 4), avant extraction de ReportsPage vers un contrôleur dédié.
//
// Teste directement le provider plutôt que ReportsPage : la vraie logique
// à risque est entièrement dans les 3 expressions de mutation (quel champ
// est préservé/réinitialisé), pas dans le câblage des dropdowns eux-mêmes
// (deux DropdownButtonFormField, un onChanged direct chacun — rien à
// caractériser côté widget que le typage statique ne garantisse déjà).
// Monter tout ReportsPage nécessiterait de simuler 8+ providers de flux
// (clients, projets, workEntries ×3, expenses ×3, payments) sans rapport
// avec ce qui change ici.

import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  ReportFilter currentFilter() => container.read(reportFilterProvider);
  void setFilter(ReportFilter filter) {
    container.read(reportFilterProvider.notifier).state = filter;
  }

  test('état initial : ReportFilter.initial() — mois courant, aucun filtre', () {
    final filter = currentFilter();
    expect(filter.clientId, isNull);
    expect(filter.projectId, isNull);
    final now = DateTime.now();
    expect(filter.dateRange.start, DateTime(now.year, now.month, 1));
    expect(filter.dateRange.end, DateTime(now.year, now.month + 1, 0));
  });

  group('changement de période (date range picker)', () {
    test('met à jour dateRange, préserve clientId et projectId', () {
      final initialRange = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      setFilter(ReportFilter(dateRange: initialRange, clientId: 'client-1', projectId: 'project-1'));

      final newRange = DateTimeRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 28));
      // Reproduit l'expression exacte du onTap du date range picker
      // (reports_page.dart) : filter.copyWith(dateRange: picked).
      setFilter(currentFilter().copyWith(dateRange: newRange));

      expect(currentFilter().dateRange, newRange);
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().projectId, 'project-1');
    });
  });

  group('changement de client (dropdown Client)', () {
    test('sélectionner un client réinitialise le chantier, préserve la période', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      setFilter(ReportFilter(dateRange: range, clientId: null, projectId: null));

      // Reproduit l'expression exacte du onChanged du dropdown Client :
      // un ReportFilter brut, PAS copyWith (voir le test suivant pour pourquoi).
      final filter = currentFilter();
      setFilter(ReportFilter(dateRange: filter.dateRange, clientId: 'client-1', projectId: null));

      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().projectId, isNull);
      expect(currentFilter().dateRange, range);
    });

    test(
      'revenir à "Tous les clients" (null) efface aussi le chantier — '
      'copyWith(clientId: null) ne le ferait PAS (null == paramètre omis)',
      () {
        final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
        setFilter(ReportFilter(dateRange: range, clientId: 'client-1', projectId: 'project-1'));

        // Piège : si ce test utilisait copyWith(clientId: null) au lieu du
        // constructeur brut, `clientId: clientId ?? this.clientId` dans
        // ReportFilter.copyWith laisserait clientId inchangé (le null passé
        // est indiscernable d'un paramètre non fourni). C'est exactement
        // pourquoi le onChanged du dropdown Client n'utilise pas copyWith.
        final filter = currentFilter();
        setFilter(ReportFilter(dateRange: filter.dateRange, clientId: null, projectId: null));

        expect(currentFilter().clientId, isNull);
        expect(currentFilter().projectId, isNull);
        expect(currentFilter().dateRange, range);
      },
    );
  });

  group('changement de chantier (dropdown Chantier)', () {
    test('sélectionner un chantier met à jour projectId, préserve client et période', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      setFilter(ReportFilter(dateRange: range, clientId: 'client-1', projectId: null));

      // Reproduit l'expression exacte du onChanged du dropdown Chantier.
      final filter = currentFilter();
      setFilter(filter.copyWith(projectId: 'project-1', clearProject: false));

      expect(currentFilter().projectId, 'project-1');
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().dateRange, range);
    });

    test('revenir à "Tous les chantiers" (null) efface projectId via clearProject', () {
      final range = DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31));
      setFilter(ReportFilter(dateRange: range, clientId: 'client-1', projectId: 'project-1'));

      final filter = currentFilter();
      setFilter(filter.copyWith(projectId: null, clearProject: true));

      expect(currentFilter().projectId, isNull);
      expect(currentFilter().clientId, 'client-1');
      expect(currentFilter().dateRange, range);
    });
  });
}
