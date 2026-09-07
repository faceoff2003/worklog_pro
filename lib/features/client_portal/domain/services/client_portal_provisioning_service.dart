import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';
import 'package:worklog_pro/features/client_portal/domain/services/secure_password_generator.dart';
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';

enum ClientPortalProvisioningOutcome {
  /// Compte créé, profil créé, Client.portalUid lié, email d'accès envoyé —
  /// tout a réussi.
  success,

  /// Étape 1 : l'email est déjà utilisé. Aucun compte créé, rien à
  /// compenser.
  emailAlreadyInUse,

  /// Étape 1 : format d'email invalide. Cas le plus fréquent (faute de
  /// frappe) après emailAlreadyInUse — issue dédiée, pas confondue avec une
  /// panne : l'artisan doit savoir que c'est corrigeable de son côté.
  invalidEmail,

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
  /// automatiquement au prochain lancement. L'email d'accès est envoyé
  /// quand même (le client peut se connecter indépendamment de ce lien,
  /// qui ne sert qu'à l'artisan et au mirroring).
  linkPendingAutomaticRepair,

  /// Compte et profil créés (étape 3 réussie ou non, peu importe) mais
  /// l'envoi de l'email d'accès a échoué — remplace l'issue de l'étape 3
  /// quel qu'elle soit, puisque c'est ce qui est réellement actionnable
  /// pour l'artisan : [portalUid] et [email] du résultat permettent de
  /// proposer un renvoi (ClientPortalProvisioningService.resendInvite).
  inviteEmailFailed,
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
///
/// Le mot de passe est généré ICI (SecurePasswordGenerator, Random.secure())
/// et n'est JAMAIS accepté en paramètre ni exposé en retour — aucun
/// appelant ne peut donc l'afficher, le logger ou le stocker par erreur. Le
/// client définit le sien via l'email d'accès envoyé après l'étape 3
/// (jamais transmis par l'artisan).
class ClientPortalProvisioningService {
  final PortalAccountProvisioner Function() _provisionerFactory;
  final ClientPortalRepository _clientPortalRepository;
  final ClientRepository _clientRepository;
  final PortalInviteEmailSender _inviteEmailSender;
  final SecurePasswordGenerator _passwordGenerator;

  ClientPortalProvisioningService({
    required PortalAccountProvisioner Function() provisionerFactory,
    required ClientPortalRepository clientPortalRepository,
    required ClientRepository clientRepository,
    required PortalInviteEmailSender inviteEmailSender,
    SecurePasswordGenerator? passwordGenerator,
  })  : _provisionerFactory = provisionerFactory,
        _clientPortalRepository = clientPortalRepository,
        _clientRepository = clientRepository,
        _inviteEmailSender = inviteEmailSender,
        _passwordGenerator = passwordGenerator ?? SecurePasswordGenerator();

  Future<ClientPortalProvisioningResult> createPortalAccount({
    required String artisanUid,
    required String clientId,
    required String email,
  }) async {
    final provisioner = _provisionerFactory();
    try {
      final String portalUid;
      try {
        portalUid = await provisioner.createAccount(email: email, password: _passwordGenerator.generate());
      } on PortalEmailAlreadyInUseException {
        return ClientPortalProvisioningResult(outcome: ClientPortalProvisioningOutcome.emailAlreadyInUse, email: email);
      } on PortalInvalidEmailException {
        return ClientPortalProvisioningResult(outcome: ClientPortalProvisioningOutcome.invalidEmail, email: email);
      } catch (_) {
        return ClientPortalProvisioningResult(outcome: ClientPortalProvisioningOutcome.authCreationFailed, email: email);
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

      var linkOutcome = ClientPortalProvisioningOutcome.linkPendingAutomaticRepair;
      try {
        final client = await _clientRepository.getClient(clientId);
        if (client != null) {
          await _clientRepository.updateClient(client.copyWith(portalUid: portalUid));
          linkOutcome = ClientPortalProvisioningOutcome.success;
        }
      } catch (_) {
        // linkOutcome reste linkPendingAutomaticRepair (sa valeur par défaut).
      }

      // Envoyé que l'étape 3 ait réussi ou non : le client peut se
      // connecter indépendamment du lien Client.portalUid, qui ne sert
      // qu'à l'artisan et au mirroring.
      try {
        await _inviteEmailSender.sendInvite(email: email);
      } catch (_) {
        return ClientPortalProvisioningResult(
          outcome: ClientPortalProvisioningOutcome.inviteEmailFailed,
          email: email,
          portalUid: portalUid,
        );
      }

      return ClientPortalProvisioningResult(outcome: linkOutcome, email: email, portalUid: portalUid);
    } finally {
      // Sur TOUTE la séquence, jamais avant : si l'étape 2 échoue et qu'on
      // compense en supprimant le compte de l'étape 1, il faut être encore
      // connecté dessus sur l'app secondaire — qui n'existerait déjà plus
      // si dispose() avait été appelé à la fin de l'étape 1.
      await provisioner.dispose();
    }
  }

  /// Renvoi indépendant, pour l'écran qui gérera un email perdu — sans lui,
  /// un email égaré rendrait le portail inutilisable sans recours.
  ///
  /// I3 (SECURITY_AUDIT.md, Email Enumeration Protection) a une prise ici,
  /// mais différente de sa version d'origine : I3 parle d'un attaquant
  /// externe énumérant des comptes arbitraires via une UI publique ; ici,
  /// c'est l'artisan qui vérifie son propre client déjà connu — pas un
  /// risque d'énumération. Seule conséquence réelle : si le compte a été
  /// supprimé entre-temps (console, ou une future révocation qui
  /// supprimerait plutôt que désactiverait) ET que la protection est
  /// activée côté console (jamais confirmée), cet appel renverrait un
  /// succès silencieux sans qu'aucun email ne parte — l'artisan croirait
  /// à tort avoir renvoyé l'accès. Un désagrément de fiabilité, pas un
  /// nouveau trou de sécurité — pas de nouveau finding pour ça.
  Future<bool> resendInvite({required String email}) async {
    try {
      await _inviteEmailSender.sendInvite(email: email);
      return true;
    } catch (_) {
      return false;
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
