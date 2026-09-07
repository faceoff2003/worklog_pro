// Caractérisation de l'arbre de réconciliation de SyncingSettingsRepository
// (F-SETTINGS.5). LocalSettingsRepository est réel (SharedPreferences
// mockée) ; le cloud est un FakeCloudSettingsGateway en mémoire, seul moyen
// de simuler de façon fiable et rapide les branches hors ligne et timeout
// (cloud_firestore ne peut pas s'exécuter sous flutter test — voir
// integration_test/firestore_cloud_gateway_test.dart pour la preuve, contre
// un vrai émulateur, que FirestoreCloudSettingsGateway traduit correctement
// absent/loaded/refus en CloudSettingsSnapshot).
//
// Règle absolue vérifiée ici : seul un CloudSettingsSnapshot avec
// status == absent confirme un cloud vide. Une exception ou un timeout ne
// le confirme jamais et ne doit déclencher aucune écriture.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/data/repositories/syncing_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

class FakeCloudSettingsGateway implements CloudSettingsGateway {
  CloudSettingsSnapshot snapshotToReturn = const CloudSettingsSnapshot(
    settings: Settings(),
    status: CloudSettingsStatus.absent,
  );
  Object? errorToThrow;
  bool hang = false;

  int fetchCallCount = 0;
  int pushCallCount = 0;
  Settings? lastPushed;

  @override
  Future<CloudSettingsSnapshot> fetch() {
    fetchCallCount++;
    if (hang) return Completer<CloudSettingsSnapshot>().future;
    if (errorToThrow != null) return Future.error(errorToThrow!);
    return Future.value(snapshotToReturn);
  }

  @override
  Future<void> push(Settings settings) async {
    pushCallCount++;
    lastPushed = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeCloudSettingsGateway cloud;
  late LocalSettingsRepository local;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    cloud = FakeCloudSettingsGateway();
    local = LocalSettingsRepository();
  });

  SyncingSettingsRepository repo({Duration timeout = const Duration(milliseconds: 50)}) =>
      SyncingSettingsRepository(local: local, cloud: cloud, reconciliationTimeout: timeout);

  group('absent + cloud vide', () {
    test('push local vers le cloud, loadSettings() renvoie Settings() immédiatement', () async {
      cloud.snapshotToReturn =
          const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.absent);

      final settings = await repo().loadSettings();
      expect(settings, const Settings());

      // laisser la réconciliation de fond se terminer.
      await Future<void>.delayed(Duration.zero);
      expect(cloud.pushCallCount, 1);
      expect(cloud.lastPushed!.updatedAt, isNotNull); // horodaté faute d'original
    });
  });

  group('loaded + cloud vide', () {
    test('push local vers le cloud', () async {
      await local.saveSettings(const Settings(dayHours: 6));
      cloud.snapshotToReturn =
          const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.absent);

      final settings = await repo().loadSettings();
      expect(settings.dayHours, 6);

      await Future<void>.delayed(Duration.zero);
      expect(cloud.pushCallCount, 1);
      expect(cloud.lastPushed!.dayHours, 6);
    });
  });

  group('loaded + cloud existant — updatedAt le plus récent gagne', () {
    test('local plus récent → push local vers le cloud', () async {
      final localSettings = Settings(dayHours: 6, updatedAt: DateTime(2026, 3, 15));
      await local.saveSettings(localSettings);
      cloud.snapshotToReturn = CloudSettingsSnapshot(
        settings: Settings(dayHours: 9, updatedAt: DateTime(2026, 1, 1)),
        status: CloudSettingsStatus.loaded,
      );

      await repo().loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cloud.pushCallCount, 1);
      expect(cloud.lastPushed!.dayHours, 6);
    });

    test('cloud plus récent → local écrasé par le cloud', () async {
      await local.saveSettings(Settings(dayHours: 6, updatedAt: DateTime(2026, 1, 1)));
      cloud.snapshotToReturn = CloudSettingsSnapshot(
        settings: Settings(dayHours: 9, updatedAt: DateTime(2026, 3, 15)),
        status: CloudSettingsStatus.loaded,
      );

      await repo().loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cloud.pushCallCount, 0);
      final reloaded = await local.loadSettings();
      expect(reloaded.dayHours, 9);
    });

    test('updatedAt égal (les deux null) → aucune écriture', () async {
      await local.saveSettings(const Settings(dayHours: 6));
      cloud.snapshotToReturn = const CloudSettingsSnapshot(
        settings: Settings(dayHours: 9),
        status: CloudSettingsStatus.loaded,
      );

      await repo().loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cloud.pushCallCount, 0);
      final reloaded = await local.loadSettings();
      expect(reloaded.dayHours, 6); // local inchangé
    });

    test('absent (local jamais écrit) face à un cloud plein → le cloud gagne '
        '(Settings().updatedAt == null == "le plus vieux possible")', () async {
      cloud.snapshotToReturn = CloudSettingsSnapshot(
        settings: Settings(dayHours: 9, updatedAt: DateTime(2026, 3, 15)),
        status: CloudSettingsStatus.loaded,
      );

      await repo().loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cloud.pushCallCount, 0);
      final reloaded = await local.loadSettings();
      expect(reloaded.dayHours, 9);
    });
  });

  group('corrupted', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'app_settings': '{{{ pas du json'});
    });

    test('cloud plein → récupération : loadSettings() renvoie les réglages du cloud, jamais de push', () async {
      cloud.snapshotToReturn = CloudSettingsSnapshot(
        settings: Settings(dayHours: 11, updatedAt: DateTime(2026, 3, 15)),
        status: CloudSettingsStatus.loaded,
      );

      final settings = await repo().loadSettings();

      expect(settings.dayHours, 11);
      expect(cloud.pushCallCount, 0);
      final localAfter = await local.loadSettings();
      expect(localAfter.dayHours, 11); // local réparé
    });

    test('cloud vide → rien du tout, loadSettings() renvoie Settings() par défaut', () async {
      cloud.snapshotToReturn =
          const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.absent);

      final settings = await repo().loadSettings();

      expect(settings, const Settings());
      expect(cloud.pushCallCount, 0); // jamais de push depuis corrupted, même cloud vide
      final localSnapshotAfter = await local.loadWithStatus();
      expect(localSnapshotAfter.status, LocalSettingsStatus.corrupted); // toujours corrompu, non "réparé" par du vide
    });

    test('get() lève une exception (hors ligne) → Settings() par défaut, recoveryFailed == true, aucune écriture',
        () async {
      cloud.errorToThrow = Exception('réseau indisponible');
      final r = repo();

      final settings = await r.loadSettings();

      expect(settings, const Settings());
      expect(r.recoveryFailed, isTrue);
      expect(cloud.pushCallCount, 0);
    });

    test('get() ne répond jamais (timeout) → Settings() par défaut renvoyé sans attendre indéfiniment, recoveryFailed == true',
        () async {
      cloud.hang = true;
      final r = repo(timeout: const Duration(milliseconds: 30));

      final stopwatch = Stopwatch()..start();
      final settings = await r.loadSettings();
      stopwatch.stop();

      expect(settings, const Settings());
      expect(r.recoveryFailed, isTrue);
      expect(stopwatch.elapsedMilliseconds, lessThan(2000)); // borné par le timeout, pas par un vrai hang
    });
  });

  group('absent/loaded — get() en échec → on ne touche à rien', () {
    test('exception réseau : loadSettings() renvoie le local immédiatement, aucune écriture', () async {
      await local.saveSettings(const Settings(dayHours: 6));
      cloud.errorToThrow = Exception('réseau indisponible');

      final settings = await repo().loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(settings.dayHours, 6); // non bloquant, valeur locale immédiate
      expect(cloud.pushCallCount, 0);
      final localAfter = await local.loadSettings();
      expect(localAfter.dayHours, 6); // local intact
    });
  });

  group('_reconciliationFuture — une seule exécution par session', () {
    test('deux appels à loadSettings() ne déclenchent qu\'un seul fetch() cloud', () async {
      final r = repo();
      await r.loadSettings();
      await r.loadSettings();
      await Future<void>.delayed(Duration.zero);

      expect(cloud.fetchCallCount, 1);
    });
  });

  group('saveSettings — local d\'abord et toujours, cloud best-effort', () {
    test('le cloud échoue (exception) → saveSettings() réussit quand même, local à jour', () async {
      cloud.errorToThrow = Exception('réseau indisponible');

      await repo().saveSettings(const Settings(dayHours: 7));

      final localAfter = await local.loadSettings();
      expect(localAfter.dayHours, 7);
    });

    test('cloud disponible → reçoit un updatedAt même si l\'appelant ne l\'a pas mis', () async {
      await repo().saveSettings(const Settings(dayHours: 7));

      expect(cloud.pushCallCount, 1);
      expect(cloud.lastPushed!.dayHours, 7);
      expect(cloud.lastPushed!.updatedAt, isNotNull);
    });
  });

  group('updatePdfHeader — délègue à loadSettings()/saveSettings()', () {
    test('modifie pdfHeader, préserve le reste, propage au cloud', () async {
      await local.saveSettings(const Settings(dayHours: 9, currency: 'USD'));
      // Cloud "loaded" avec un updatedAt à égalité (les deux null) avec le
      // local d'origine : la réconciliation de fond déclenchée par le
      // loadSettings() interne à updatePdfHeader() devient un no-op (cmp ==
      // 0), qui ne peut donc pas entrer en course avec le push explicite de
      // saveSettings() ci-dessous et fausser lastPushed/l'état local.
      cloud.snapshotToReturn =
          const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.loaded);

      const newHeader = PdfHeader(name: 'X', phone: '', mentionHT: 'Prix HT');
      await repo().updatePdfHeader(newHeader);

      final updated = await local.loadSettings();
      expect(updated.pdfHeader, newHeader);
      expect(updated.dayHours, 9);
      expect(cloud.lastPushed?.pdfHeader, newHeader);
    });
  });
}
