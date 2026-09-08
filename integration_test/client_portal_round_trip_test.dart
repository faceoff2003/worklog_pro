// Reproduit le bug du 2026-09-08 (C-PORTAL.7, découvert en test terrain
// réel) : createPortal() écrit `createdAt` en DateTime natif Dart, que le
// SDK Firestore convertit automatiquement en Timestamp natif côté serveur.
// ClientPortal.fromJson (généré par json_serializable) attend une String
// ISO8601 sur ce champ (`DateTime.parse(json['createdAt'] as String)`) —
// exactement la convention suivie par TOUTES les autres entités de ce repo
// (Client, WorkEntry...), qui écrivent via `.toJson()` (String) et lisent
// via `.fromJson()` (String). ClientPortalRepositoryImpl.createPortal() est
// le seul point d'écriture qui déroge à cette convention, en construisant
// un Map à la main plutôt que via ClientPortal(...).toJson().
//
// Ce test aurait dû échouer avant le fix, et ne l'a jamais fait plus tôt
// dans le sprint car ClientPortal.fromJson n'a jamais été appelé sur un
// document RÉELLEMENT écrit par createPortal() avant que le routage de
// rôle (C-PORTAL.7, userPortalProvider -> getPortal()) ne l'exerce enfin —
// createPortal() et getPortal() étaient jusque-là testés séparément
// (fakes), jamais en aller-retour réel via le même repository.
//
// Prérequis : firebase emulators:start --only firestore,auth, puis
// flutter test integration_test/client_portal_round_trip_test.dart -d <device>

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  testWidgets(
    'createPortal() PUIS getPortal() sur le même document, par les deux vraies identités (artisan qui écrit, '
    'client qui relit) — l\'aller-retour réel que fait userPortalProvider, pas createPortal() et getPortal() '
    'testés séparément',
    (tester) async {
      final repo = ClientPortalRepositoryImpl();

      // 1. Le futur CLIENT se crée un compte d'abord — son uid devient portalUid.
      final clientCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'client-roundtrip-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpass123',
      );
      final portalUid = clientCred.user!.uid;
      await FirebaseAuth.instance.signOut();

      // 2. L'ARTISAN se connecte et crée le portail — exactement le chemin
      //    réel de ClientPortalProvisioningService.
      final artisanCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'artisan-roundtrip-${DateTime.now().millisecondsSinceEpoch}@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisanCred.user!.uid;

      await repo.createPortal(portalUid: portalUid, artisanUid: artisanUid, clientId: 'client-doc-1');
      await FirebaseAuth.instance.signOut();

      // 3. Le CLIENT se reconnecte et relit SON PROPRE profil — exactement
      //    ce que userPortalProvider fait pour décider du rôle.
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: clientCred.user!.email!,
        password: 'testpass123',
      );

      // Doit réussir sans lever — avant le fix, ceci lève un TypeError
      // ("type 'Timestamp' is not a subtype of type 'String'").
      final portal = await repo.getPortal(portalUid);

      expect(portal, isNotNull);
      expect(portal!.portalUid, portalUid);
      expect(portal.artisanUid, artisanUid);
      expect(portal.clientId, 'client-doc-1');
      expect(portal.enabled, true);
      expect(
        portal.createdAt.isAfter(DateTime.now().subtract(const Duration(minutes: 1))),
        isTrue,
        reason: 'createdAt doit être une date valide, récente — pas un artefact de parsing raté',
      );
    },
  );
}
