// C-PORTAL.8, étape 1 — la seule chose que ce test prouve : watchMyWorkEntries()
// (le VRAI repository, pas un fake) ne renvoie jamais que le miroir du
// client authentifié, jamais celui d'un autre — la chaîne complète (auth ->
// provider -> repository -> requête Firestore -> rules), pas les rules
// isolément.
//
// Le cas du portail désactivé (comportement de watchMyWorkEntries() une fois
// enabled == false) a été exploré séparément, empiriquement, contre
// l'émulateur ET la vraie prod — voir la conversation / le prochain commit
// pour ce sujet, hors périmètre de cette fondation.
//
// Prérequis : firebase emulators:start --only firestore,auth, puis
// flutter test integration_test/client_mirror_repository_isolation_test.dart -d <device>

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_mirror_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  WorkEntry entry({required String id, required String clientId}) => WorkEntry(
        id: id,
        date: DateOnly.fromString('2026-03-10'),
        startTime: 480,
        endTime: 720,
        durationMinutes: 240,
        clientId: clientId,
        billingMode: BillingMode.hourly,
        rateApplied: Money.fromCents(2000),
        laborAmountHT: Money.fromCents(8000),
        createdAt: DateTime(2026, 3, 10),
        updatedAt: DateTime(2026, 3, 10),
      );

  testWidgets(
    'isolation réelle entre deux clients — chacun ne voit jamais que sa propre prestation',
    (tester) async {
      final portalRepo = ClientPortalRepositoryImpl();

      // 1. Deux futurs clients se créent un compte — leur uid devient portalUid.
      final clientA = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'mirror-a-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpass123',
      );
      final uidA = clientA.user!.uid;
      await FirebaseAuth.instance.signOut();

      final clientB = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'mirror-b-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpass123',
      );
      final uidB = clientB.user!.uid;
      await FirebaseAuth.instance.signOut();

      // 2. L'artisan crée les deux portails et mirrore une prestation pour chacun.
      final artisan = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'mirror-artisan-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisan.user!.uid;

      await portalRepo.createPortal(portalUid: uidA, artisanUid: artisanUid, clientId: 'client-a');
      await portalRepo.createPortal(portalUid: uidB, artisanUid: artisanUid, clientId: 'client-b');

      await portalRepo.mirrorWorkEntry(uidA, entry(id: 'entry-a', clientId: 'client-a'));
      await portalRepo.mirrorWorkEntry(uidB, entry(id: 'entry-b', clientId: 'client-b'));

      await FirebaseAuth.instance.signOut();

      // 3. CLIENT_A ne voit que sa propre prestation.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: clientA.user!.email!,
        password: 'testpass123',
      );
      final entriesA = await ClientMirrorRepositoryImpl(uid: uidA).watchMyWorkEntries().first;
      expect(entriesA.map((e) => e.id), ['entry-a']);
      await FirebaseAuth.instance.signOut();

      // 4. CLIENT_B ne voit que sa propre prestation — jamais celle de A.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: clientB.user!.email!,
        password: 'testpass123',
      );
      final entriesB = await ClientMirrorRepositoryImpl(uid: uidB).watchMyWorkEntries().first;
      expect(entriesB.map((e) => e.id), ['entry-b']);
      await FirebaseAuth.instance.signOut();
    },
  );
}
