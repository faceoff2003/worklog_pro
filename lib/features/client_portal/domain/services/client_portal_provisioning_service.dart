import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';

enum ClientPortalProvisioningOutcome {
  /// Compte créé, profil créé, Client.portalUid lié — tout a réussi.
  success,

  /// Étape 1 : l'email est déjà utilisé. Aucun compte créé, rien à
  /// compenser.
  emailAlreadyInUse,

  /// Étape 1 : autre échec de création du compte. Aucun compte créé, rien
  /// à compenser.
  authCreationFailed,

  /// Étape 2 a échoué ; le compte Auth de l'étape 1 a été supprimé avec
  /// succès (compensé) — aucune trace ne persiste.
  profileCreationFailedAndCompensated,

  /// Étape 2 a échoué ET la compensation (suppression du compte) a
  /// également échoué après retry — le compte reste orphelin, [email] et
  /// [portalUid] du résultat identifient le compte pour un nettoyage
  /// manuel (console Firebase).
  profileCreationFailedOrphaned,

  /// Étapes 1 et 2 ont réussi ; l'étape 3 (lier Client.portalUid) a échoué.
  /// Non bloquant — le balayage de réconciliation répare ce lien
  /// automatiquement au prochain lancement.
  linkPendingAutomaticRepair,
}

class ClientPortalProvisioningResult {
  final ClientPortalProvisioningOutcome outcome;

  /// Non-null dès qu'un compte a été créé (y compris orphelin).
  final String? portalUid;

  final String email;

  const ClientPortalProvisioningResult({
    required this.outcome,
    required this.email,
    this.portalUid,
  });
}

/// Séquence de provisioning d'un compte portail — voir le commentaire de
/// chaque valeur de [ClientPortalProvisioningOutcome] pour le comportement
/// exact à chaque étape. Aucune saga à 3 compensations : seule l'étape 1
/// est compensée en cas d'échec de l'étape 2 (clientPortals n'a pas de
/// allow delete, donc l'étape 2 elle-même n'est jamais compensable) ;
/// l'étape 3 est non bloquante par conception (le balayage répare).
class ClientPortalProvisioningService {
  final PortalAccountProvisioner Function() _provisionerFactory;
  final ClientPortalRepository _clientPortalRepository;
  final ClientRepository _clientRepository;

  ClientPortalProvisioningService({
    required PortalAccountProvisioner Function() provisionerFactory,
    required ClientPortalRepository clientPortalRepository,
    required ClientRepository clientRepository,
  })  : _provisionerFactory = provisionerFactory,
        _clientPortalRepository = clientPortalRepository,
        _clientRepository = clientRepository;

  Future<ClientPortalProvisioningResult> createPortalAccount({
    required String artisanUid,
    required String clientId,
    required String email,
    required String password,
  }) async {
    final provisioner = _provisionerFactory();
    try {
      final String portalUid;
      try {
        portalUid = await provisioner.createAccount(email: email, password: password);
      } on PortalEmailAlreadyInUseException {
        return ClientPortalProvisioningResult(
          outcome: ClientPortalProvisioningOutcome.emailAlreadyInUse,
          email: email,
        );
      } catch (_) {
        return ClientPortalProvisioningResult(
          outcome: ClientPortalProvisioningOutcome.authCreationFailed,
          email: email,
        );
      }

      try {
        await _clientPortalRepository.createPortal(
          portalUid: portalUid,
          artisanUid: artisanUid,
          clientId: clientId,
        );
      } catch (_) {
        final compensated = await _tryDeleteJustCreatedAccount(provisioner);
        return ClientPortalProvisioningResult(
          outcome: compensated
              ? ClientPortalProvisioningOutcome.profileCreationFailedAndCompensated
              : ClientPortalProvisioningOutcome.profileCreationFailedOrphaned,
          email: email,
          portalUid: compensated ? null : portalUid,
        );
      }

      try {
        final client = await _clientRepository.getClient(clientId);
        if (client == null) {
          return ClientPortalProvisioningResult(
            outcome: ClientPortalProvisioningOutcome.linkPendingAutomaticRepair,
            email: email,
            portalUid: portalUid,
          );
        }
        await _clientRepository.updateClient(client.copyWith(portalUid: portalUid));
        return ClientPortalProvisioningResult(
          outcome: ClientPortalProvisioningOutcome.success,
          email: email,
          portalUid: portalUid,
        );
      } catch (_) {
        return ClientPortalProvisioningResult(
          outcome: ClientPortalProvisioningOutcome.linkPendingAutomaticRepair,
          email: email,
          portalUid: portalUid,
        );
      }
    } finally {
      // Sur TOUTE la séquence, jamais avant : si l'étape 2 échoue et qu'on
      // compense en supprimant le compte de l'étape 1, il faut être encore
      // connecté dessus sur l'app secondaire — qui n'existerait déjà plus
      // si dispose() avait été appelé à la fin de l'étape 1.
      await provisioner.dispose();
    }
  }

  /// Un seul retry : deux tentatives au total, jamais plus.
  Future<bool> _tryDeleteJustCreatedAccount(PortalAccountProvisioner provisioner) async {
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        await provisioner.deleteJustCreatedAccount();
        return true;
      } catch (_) {
        if (attempt == 2) return false;
      }
    }
    return false;
  }
}
