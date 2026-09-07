// F-SETTINGS.7 : settingsRecoveryFailedProvider doit se RÉÉVALUER quand
// SyncingSettingsRepository.recoveryFailed devient vrai après la résolution
// initiale de settingsProvider — pas seulement lire une valeur figée au
// moment de sa création (un Provider synchrone qui lirait le bool une seule
// fois ne se réévaluerait jamais quand ce bool change ensuite : le bandeau
// ne s'afficherait jamais).
//
// On overrideWithValue(settingsRepositoryProvider) avec un vrai
// SyncingSettingsRepository construit avec un CloudSettingsGateway factice
// qui ne répond jamais (hang) : ça déclenche la branche corrupted+timeout
// exactement comme sur un appareil hors ligne. Aucun Firestore réel touché
// (authStateProvider n'entre jamais en jeu ici).

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/data/repositories/syncing_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/presentation/providers/settings_provider.dart';

class _HangingCloud implements CloudSettingsGateway {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'devient true après coup : le bandeau apparaît quand recoveryFailed passe à '
    'vrai après la résolution initiale de settingsProvider (pas figé à sa création)',
    () async {
      SharedPreferences.setMockInitialValues({'app_settings': '{{{ pas du json'});
      final repository = SyncingSettingsRepository(
        local: LocalSettingsRepository(),
        cloud: _HangingCloud(),
        reconciliationTimeout: const Duration(milliseconds: 20),
      );
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final emitted = <bool>[];
      container.listen<bool>(
        settingsRecoveryFailedProvider,
        (previous, next) => emitted.add(next),
        fireImmediately: true,
      );

      // Avant que loadSettings() n'ait eu le temps de timeout : pas encore vrai.
      expect(emitted, [false]);

      await container.read(settingsProvider.future);
      await Future<void>.delayed(Duration.zero);

      // Après la transition loading -> data (timeout inclus), le provider
      // s'est réévalué tout seul et reflète le flag désormais stable.
      expect(emitted.last, isTrue);
    },
  );

  test('reste false du début à la fin sur un chemin normal (pas de faux positif)', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = SyncingSettingsRepository(
      local: LocalSettingsRepository(),
      cloud: _AbsentCloud(),
    );
    final container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final emitted = <bool>[];
    container.listen<bool>(
      settingsRecoveryFailedProvider,
      (previous, next) => emitted.add(next),
      fireImmediately: true,
    );

    await container.read(settingsProvider.future);
    await Future<void>.delayed(Duration.zero); // laisser la réconciliation de fond se terminer

    expect(emitted, everyElement(isFalse));
  });
}
