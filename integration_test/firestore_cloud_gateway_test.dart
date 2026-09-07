// Vérifie que FirestoreCloudSettingsGateway (F-SETTINGS.5) traduit
// correctement l'état Firestore réel en CloudSettingsSnapshot : un doc
// absent en status absent, un doc existant en status loaded avec les bonnes
// valeurs, un refus des rules en exception propagée telle quelle.
//
// Ne teste PAS l'arbre de réconciliation (SyncingSettingsRepository) : voir
// test/features/settings/data/repositories/syncing_settings_repository_test.dart
// (FakeCloudSettingsGateway en mémoire, seul moyen fiable et rapide de
// simuler les branches hors ligne et timeout — cloud_firestore ne peut pas
// s'exécuter sous flutter test seul, VM sans plateforme).
//
// Web (Chrome) était le premier choix (plus léger qu'un AVD), mais
// `flutter test -d chrome` répond "Web devices are not supported for
// integration tests yet" : la voie web impose flutter drive + chromedriver,
// non installé ici. On réutilise donc l'AVD Android du sprint R-SEC
// ("test_avd_medium"), déjà en place.
//
// Prérequis, dans deux terminaux séparés :
//   1. firebase emulators:start --only firestore,auth
//   2. flutter test integration_test/firestore_cloud_gateway_test.dart -d <device>

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // 10.0.2.2 = alias vers le localhost de la machine hôte depuis
    // l'intérieur d'un émulateur Android (cf. integration_test/app_test.dart).
    final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  /// Un nouvel utilisateur anonyme (uid frais) par test : isolation
  /// naturelle, pas besoin de vider l'émulateur entre les tests.
  Future<String> freshUid() async {
    await FirebaseAuth.instance.signOut();
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user!.uid;
  }

  testWidgets('doc absent -> CloudSettingsStatus.absent', (tester) async {
    final uid = await freshUid();
    final gateway = FirestoreCloudSettingsGateway(uid: uid);

    final snapshot = await gateway.fetch();

    expect(snapshot.status, CloudSettingsStatus.absent);
    expect(snapshot.settings, const Settings());
  });

  testWidgets('doc existant -> CloudSettingsStatus.loaded avec les bonnes valeurs', (tester) async {
    final uid = await freshUid();
    final gateway = FirestoreCloudSettingsGateway(uid: uid);
    final pushed = const Settings(dayHours: 6, currency: 'USD')
        .copyWith(updatedAt: DateTime.utc(2026, 3, 15, 10, 30));

    await gateway.push(pushed);
    final snapshot = await gateway.fetch();

    expect(snapshot.status, CloudSettingsStatus.loaded);
    expect(snapshot.settings.dayHours, 6);
    expect(snapshot.settings.currency, 'USD');
    expect(snapshot.settings.updatedAt, pushed.updatedAt);
  });

  testWidgets('write refusé par les rules (uid différent du compte authentifié) -> exception propagée',
      (tester) async {
    await freshUid(); // authentifié, mais avec un autre uid que celui ciblé.
    final gateway = FirestoreCloudSettingsGateway(uid: 'un-uid-qui-nest-pas-le-mien');

    await expectLater(
      gateway.push(const Settings()),
      throwsA(isA<FirebaseException>()),
    );
  });
}
