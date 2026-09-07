// Vérifie empiriquement, contre l'émulateur Auth + Firestore réel, les
// quatre points soulevés avant de coder (C-PORTAL.5, implémentation réelle
// de PortalAccountProvisioner) — aucun n'est pris pour acquis par lecture
// de code :
//
// 1. Nom d'app secondaire unique par appel (voir
//    FirebasePortalAccountProvisioner) — ce fichier prouve la conséquence
//    directe : deux créations consécutives dans la même session réussissent
//    toutes les deux (test "point 2").
// 2. Le test de double création EST le vrai test du dispose() — sans lui,
//    rien ne prouve que l'app secondaire est bien libérée.
// 3. La session artisan (app primaire) doit survivre : prouvé par une
//    VRAIE écriture Firestore sous l'uid artisan après coup, pas
//    seulement par une comparaison d'uid (les deux sont vérifiés).
// 4. createUserWithEmailAndPassword sur l'app secondaire connecte
//    l'utilisateur SUR CETTE APP — vérifié qu'aucun événement ne fuit vers
//    authStateChanges() de l'app primaire pendant ce temps.
//
// Complété ensuite (mot de passe jamais transmis par l'artisan) : vérifié
// que resendInvite() (sendPasswordResetEmail sur l'app PRIMAIRE, artisan
// connecté dessus) ne perturbe pas non plus sa session — pas supposé
// seulement parce que c'est "juste un envoi d'email".
//
// Prérequis, dans deux terminaux séparés :
//   1. firebase emulators:start --only firestore,auth
//   2. flutter test integration_test/portal_account_provisioning_test.dart -d <device>

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/data/services/firebase_portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/data/services/firebase_portal_invite_email_sender.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_provisioning_service.dart';
import 'package:worklog_pro/features/clients/data/repositories/client_repository_impl.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const uuid = Uuid();
  final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  Future<String> signInFreshArtisan() async {
    await FirebaseAuth.instance.signOut();
    final credential = await FirebaseAuth.instance.signInAnonymously();
    return credential.user!.uid;
  }

  ClientPortalProvisioningService buildService() => ClientPortalProvisioningService(
        // Configure chaque app secondaire nouvellement créée pour pointer
        // vers l'émulateur — jamais renseigné en production (voir
        // FirebasePortalAccountProvisioner).
        provisionerFactory: () => FirebasePortalAccountProvisioner(
          configureSecondaryAuth: (auth) => auth.useAuthEmulator(emulatorHost, 9099),
        ),
        clientPortalRepository: ClientPortalRepositoryImpl(),
        clientRepository: ClientRepositoryImpl(),
        inviteEmailSender: FirebasePortalInviteEmailSender(),
      );

  Future<Client> seedClient() async {
    return ClientRepositoryImpl().createClient(
      Client(
        id: '',
        name: 'Jean Dupont',
        type: ClientType.patron,
        defaultRates: const DefaultRates(),
        tags: const [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  testWidgets(
    'points 1 et 3 — création réussie, PUIS une vraie écriture Firestore sous l\'uid artisan réussit encore '
    '(pas seulement une comparaison d\'uid)',
    (tester) async {
      final artisanUid = await signInFreshArtisan();
      final client = await seedClient();

      final result = await buildService().createPortalAccount(
        artisanUid: artisanUid,
        clientId: client.id,
        email: 'portal-${uuid.v4()}@example.com',
      );

      expect(result.outcome, ClientPortalProvisioningOutcome.success);

      // La vraie preuve : le token de l'artisan est encore valide pour
      // Firestore, pas juste currentUser.uid encore égal (un objet en
      // cache pourrait rester égal sans que le token le soit encore).
      await expectLater(
        ClientRepositoryImpl().updateClient(client.copyWith(notes: 'vérif post-provisioning')),
        completes,
      );

      // Comparaison d'uid EN PLUS, pas à la place.
      expect(FirebaseAuth.instance.currentUser?.uid, artisanUid);
    },
  );

  testWidgets(
    'point 2 — deux créations consécutives dans la même session réussissent toutes les deux '
    '(la vraie preuve que dispose() libère l\'app secondaire précédente)',
    (tester) async {
      final artisanUid = await signInFreshArtisan();
      final clientA = await seedClient();
      final clientB = await seedClient();

      final service = buildService();

      final first = await service.createPortalAccount(
        artisanUid: artisanUid,
        clientId: clientA.id,
        email: 'portal-a-${uuid.v4()}@example.com',
      );
      final second = await service.createPortalAccount(
        artisanUid: artisanUid,
        clientId: clientB.id,
        email: 'portal-b-${uuid.v4()}@example.com',
      );

      expect(first.outcome, ClientPortalProvisioningOutcome.success);
      expect(second.outcome, ClientPortalProvisioningOutcome.success);
      expect(first.portalUid, isNot(second.portalUid));
    },
  );

  testWidgets(
    'point 4 — aucun événement ne fuit vers authStateChanges() de l\'app primaire pendant la création '
    'du compte secondaire (vérifié empiriquement, pas supposé)',
    (tester) async {
      final artisanUid = await signInFreshArtisan();
      final client = await seedClient();

      final events = <String?>[];
      final subscription = FirebaseAuth.instance.authStateChanges().listen((user) => events.add(user?.uid));
      // Laisser l'émission initiale (l'état déjà connu) passer avant de
      // lancer la création, pour ne compter que ce qui se produit PENDANT.
      await Future<void>.delayed(const Duration(milliseconds: 300));
      events.clear();

      await buildService().createPortalAccount(
        artisanUid: artisanUid,
        clientId: client.id,
        email: 'portal-${uuid.v4()}@example.com',
      );

      // Laisser le temps à une éventuelle fuite tardive de s'émettre.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      expect(
        events,
        isEmpty,
        reason: 'authStateChanges() de l\'app primaire a émis pendant la création du compte '
            'secondaire (devrait être totalement silencieux) : $events',
      );
      expect(FirebaseAuth.instance.currentUser?.uid, artisanUid);
    },
  );

  testWidgets(
    'resendInvite (sendPasswordResetEmail sur l\'app PRIMAIRE, artisan connecté dessus) ne touche pas sa session — '
    'même vérification que le point 4 (authStateChanges() vide + vraie écriture Firestore après), pas supposé '
    'parce que "c\'est juste un envoi d\'email"',
    (tester) async {
      final artisanUid = await signInFreshArtisan();
      final client = await seedClient();

      final events = <String?>[];
      final subscription = FirebaseAuth.instance.authStateChanges().listen((user) => events.add(user?.uid));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      events.clear();

      final sent = await buildService().resendInvite(email: 'portal-${uuid.v4()}@example.com');

      await Future<void>.delayed(const Duration(milliseconds: 500));
      await subscription.cancel();

      // L'email n'existe pas côté Auth (jamais créé), donc l'envoi peut
      // échouer selon le réglage d'énumération de l'émulateur — ce n'est
      // pas ce qui est testé ici. Ce qui compte : quel que soit le
      // résultat de l'envoi, la session artisan ne bouge pas.
      expect(sent, isA<bool>());

      expect(
        events,
        isEmpty,
        reason: 'authStateChanges() de l\'app primaire a émis pendant sendPasswordResetEmail '
            '(devrait être totalement silencieux) : $events',
      );

      // La vraie preuve, comme au point 3 : une écriture Firestore sous
      // l'uid artisan doit encore réussir après coup.
      await expectLater(
        ClientRepositoryImpl().updateClient(client.copyWith(notes: 'vérif post-resendInvite')),
        completes,
      );
      expect(FirebaseAuth.instance.currentUser?.uid, artisanUid);
    },
  );
}
