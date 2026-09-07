import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';

/// Implémentation réelle de [PortalAccountProvisioner] : crée le compte sur
/// une app Firebase SECONDAIRE, jetable, pour ne jamais toucher la session
/// de l'app par défaut (celle de l'artisan connecté).
///
/// Nom d'app UNIQUE à chaque appel (jamais un nom fixe) : Firebase.
/// initializeApp() lève si le nom existe déjà, et un nom fixe échouerait
/// dès la 2e création de la même session — y compris dans le cas normal
/// (deux clients créés à la suite), pas seulement après un crash qui
/// aurait laissé une app précédente en vie.
class FirebasePortalAccountProvisioner implements PortalAccountProvisioner {
  final Uuid _uuid;

  /// Point d'extension pour les tests : configurer l'app secondaire tout
  /// juste créée (ex. la pointer vers l'émulateur Auth) avant toute
  /// utilisation. Jamais renseigné en production — l'app secondaire pointe
  /// alors vers le même projet Firebase que l'app par défaut (mêmes
  /// options), donc vers Firebase réel.
  final FutureOr<void> Function(FirebaseAuth secondaryAuth)? _configureSecondaryAuth;

  FirebaseApp? _secondaryApp;
  FirebaseAuth? _secondaryAuth;

  FirebasePortalAccountProvisioner({
    Uuid? uuid,
    FutureOr<void> Function(FirebaseAuth secondaryAuth)? configureSecondaryAuth,
  })  : _uuid = uuid ?? const Uuid(),
        _configureSecondaryAuth = configureSecondaryAuth;

  @override
  Future<String> createAccount({required String email, required String password}) async {
    final app = await Firebase.initializeApp(
      name: 'portal-provisioning-${_uuid.v4()}',
      options: Firebase.app().options,
    );
    _secondaryApp = app;

    final auth = FirebaseAuth.instanceFor(app: app);
    _secondaryAuth = auth;

    if (_configureSecondaryAuth != null) {
      await _configureSecondaryAuth(auth);
    }

    try {
      final credential = await auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw const PortalEmailAlreadyInUseException();
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteJustCreatedAccount() async {
    await _secondaryAuth?.currentUser?.delete();
  }

  @override
  Future<void> dispose() async {
    await _secondaryApp?.delete();
    _secondaryApp = null;
    _secondaryAuth = null;
  }
}
