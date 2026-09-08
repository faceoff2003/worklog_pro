// C-PORTAL.10, étape 1 — preuve qu'un fake ne peut pas fournir : le
// round-trip réel du pivot de solde (lastSettlementCreatedAt) à travers le
// VRAI SDK Firestore. Exactement la même classe de bug que celle trouvée
// sur ClientPortal.createdAt en C-PORTAL.7 (voir
// client_portal_round_trip_test.dart) : un DateTime écrit à la main dans un
// Map serait converti en Timestamp par le SDK, illisible par
// ClientPortal.fromJson() qui attend une String ISO8601.
// ClientPortalRepositoryImpl.updateSettlementPivot() convertit explicitement
// via .toIso8601String() — ce test vérifie que ça marche RÉELLEMENT, pas
// seulement que le code a l'air correct.
//
// Écriture par l'ARTISAN (isLinkedArtisan, update() — pas soumis à
// l'asymétrie get/list), lecture par le CLIENT (seul isOwner peut get() un
// profil directement, voir la note sur getBackfillStatus).
//
// Prérequis : firebase emulators:start --only firestore,auth, puis
// flutter test integration_test/client_portal_settlement_pivot_round_trip_test.dart -d <device>

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
    'updateSettlementPivot() par l\'artisan PUIS getPortal() par le client — le pivot revient comme le '
    'même DateTime, à la seconde près, pas un Timestamp non lu',
    (tester) async {
      final repo = ClientPortalRepositoryImpl();
      final ts = DateTime.now().millisecondsSinceEpoch;

      final clientCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'pivot-client-$ts@example.com',
        password: 'testpass123',
      );
      final portalUid = clientCred.user!.uid;
      await FirebaseAuth.instance.signOut();

      final artisanCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'pivot-artisan-$ts@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisanCred.user!.uid;

      await repo.createPortal(portalUid: portalUid, artisanUid: artisanUid, clientId: 'client-doc-1');

      // Précision à la seconde : Firestore/ISO8601 ne garantit pas la
      // microseconde exacte après un aller-retour réseau réel.
      final settlementCreatedAt = DateTime(2026, 6, 1, 10, 30, 0);
      await repo.updateSettlementPivot(portalUid, settlementCreatedAt);
      await FirebaseAuth.instance.signOut();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: clientCred.user!.email!,
        password: 'testpass123',
      );

      // Doit réussir sans lever — même bug de classe que createdAt si
      // .toIso8601String() était oublié dans updateSettlementPivot().
      final portal = await repo.getPortal(portalUid);

      expect(portal, isNotNull);
      expect(portal!.lastSettlementCreatedAt, isNotNull);
      expect(
        portal.lastSettlementCreatedAt!.difference(settlementCreatedAt).inSeconds.abs(),
        0,
        reason: 'round-trip réel via le SDK Firestore, pas une simple relecture en mémoire',
      );
    },
  );

  testWidgets(
    'un portail sans aucun solde jamais enregistré → lastSettlementCreatedAt est null, pas une erreur',
    (tester) async {
      final repo = ClientPortalRepositoryImpl();
      final ts = DateTime.now().millisecondsSinceEpoch;

      final clientCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'pivot-none-client-$ts@example.com',
        password: 'testpass123',
      );
      final portalUid = clientCred.user!.uid;
      await FirebaseAuth.instance.signOut();

      final artisanCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'pivot-none-artisan-$ts@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisanCred.user!.uid;

      await repo.createPortal(portalUid: portalUid, artisanUid: artisanUid, clientId: 'client-doc-2');

      await FirebaseAuth.instance.signOut();
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: clientCred.user!.email!,
        password: 'testpass123',
      );

      final portal = await repo.getPortal(portalUid);

      expect(portal, isNotNull);
      expect(portal!.lastSettlementCreatedAt, isNull);
    },
  );
}
