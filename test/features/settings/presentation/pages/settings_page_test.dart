// F-SETTINGS.7 : preuve du chemin COMPLET, pas seulement de la valeur du
// provider (voir settings_recovery_failed_provider_test.dart, qui ne monte
// jamais SettingsPage et ne prouve donc pas que le bandeau apparaît à
// l'écran). Ici, SettingsPage est réellement montée avec un
// SyncingSettingsRepository forcé en recoveryFailed == true, et on cherche
// le texte du bandeau dans l'arbre de widgets.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/data/repositories/syncing_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/presentation/pages/settings_page.dart';
import 'package:worklog_pro/features/settings/presentation/providers/settings_provider.dart';

const _bannerText = 'Réglages non récupérés, vérifiez votre connexion avant de les modifier';

class _HangingCloud implements CloudSettingsGateway {
  // Un Completer jamais complété plutôt qu'un Future.delayed : ne pose
  // aucun Timer réel, donc rien que le détecteur de "pending timer" de
  // flutter_test puisse reprocher à la fin du test. Seul le .timeout()
  // interne de SyncingSettingsRepository pose un vrai Timer — celui-là,
  // voulu, est déclenché en avançant l'horloge factice via tester.pump().
  @override
  Future<CloudSettingsSnapshot> fetch() => Completer<CloudSettingsSnapshot>().future;

  @override
  Future<void> push(Settings settings) async {}
}

class _AbsentCloud implements CloudSettingsGateway {
  @override
  Future<CloudSettingsSnapshot> fetch() async =>
      const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.absent);

  @override
  Future<void> push(Settings settings) async {}
}

Future<void> _pumpSettingsPage(WidgetTester tester, SyncingSettingsRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
}

void main() {
  testWidgets('recoveryFailed vrai (corrupted + cloud injoignable) : le bandeau est affiché à l\'écran', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'app_settings': '{{{ pas du json'});
    final repository = SyncingSettingsRepository(
      local: LocalSettingsRepository(),
      cloud: _HangingCloud(),
      reconciliationTimeout: const Duration(milliseconds: 20),
    );

    await _pumpSettingsPage(tester, repository);
    // pump() répété plutôt que pumpAndSettle() : le fetch() du cloud factice
    // reste délibérément en vol 10s (simule un réseau qui ne répond jamais
    // dans la fenêtre du test) — pumpAndSettle() attendrait cette tâche de
    // fond et timeoutrait le test lui-même. On avance seulement assez pour
    // dépasser le timeout de réconciliation (20ms) et laisser
    // settingsProvider transiter vers AsyncData.
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }

    expect(find.text(_bannerText), findsOneWidget);
  });

  testWidgets('chemin normal (pas de corruption) : le bandeau est absent', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repository = SyncingSettingsRepository(local: LocalSettingsRepository(), cloud: _AbsentCloud());

    await _pumpSettingsPage(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text(_bannerText), findsNothing);
  });
}
