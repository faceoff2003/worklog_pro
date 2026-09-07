import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';

/// Balayage de réparation (C-PORTAL.4, point B du diagnostic) — pour un
/// portail dont `clientPortals/{portalUid}.clientId` ne pointe vers aucun
/// `Client.portalUid` correspondant. Pas de champ "pending" à créer ni à
/// nettoyer : le signal de réparation est déjà durable (l'incohérence entre
/// les deux documents), donc auto-cicatrisant — une fois réparé, plus rien
/// à suivre. Survit à un kill en plein milieu d'un provisioning de compte :
/// au prochain lancement, le même balayage retrouve la même incohérence.
///
/// NE COUVRE PAS le cas A (compte Firebase Auth créé pendant le
/// provisioning, mais dont l'écriture du profil clientPortals a ensuite
/// échoué) : dans ce cas, AUCUN document Firestore n'existe nulle part
/// pour ce compte (ni profil, ni lien) — rien à balayer, rien à détecter.
/// Seul un accès Admin SDK listant tous les comptes Firebase Auth pourrait
/// le repérer par différence avec les clientPortals existants ; hors
/// périmètre de ce sprint (voir SECURITY_AUDIT.md / décision sur la
/// création de compte, pas de Cloud Function prévue).
///
/// Une seule exécution par session : reconcileOnce() met en cache sa
/// propre Future, comme SyncingSettingsRepository. Le déclenchement (une
/// fois par lancement de l'app, pas à chaque ouverture de la liste
/// clients) est une décision de câblage UI, pas de ce service — voir
/// l'étape qui construira l'écran.
class ClientPortalReconciliationService {
  final String _artisanUid;
  final ClientRepository _clientRepository;
  final ClientPortalRepository _clientPortalRepository;

  Future<ClientPortalReconciliationReport>? _sessionReconciliation;

  ClientPortalReconciliationService({
    required String artisanUid,
    required ClientRepository clientRepository,
    required ClientPortalRepository clientPortalRepository,
  })  : _artisanUid = artisanUid,
        _clientRepository = clientRepository,
        _clientPortalRepository = clientPortalRepository;

  Future<ClientPortalReconciliationReport> reconcileOnce() => _sessionReconciliation ??= _reconcile();

  Future<ClientPortalReconciliationReport> _reconcile() async {
    final portals = await _clientPortalRepository.listPortalsForArtisan(_artisanUid);

    var repairedCount = 0;
    final issues = <ClientPortalReconciliationIssue>[];

    for (final portal in portals) {
      final client = await _clientRepository.getClient(portal.clientId);

      if (client == null) {
        issues.add(ClientPortalReconciliationIssue(
          type: ReconciliationIssueType.clientNotFound,
          portalUid: portal.portalUid,
          clientId: portal.clientId,
        ));
        continue;
      }

      if (client.portalUid == portal.portalUid) continue; // déjà correctement lié

      if (client.portalUid == null) {
        await _clientRepository.updateClient(client.copyWith(portalUid: portal.portalUid));
        repairedCount++;
        continue;
      }

      // client.portalUid pointe vers un AUTRE portail : jamais d'écriture
      // automatique, remonté pour décision par l'artisan.
      issues.add(ClientPortalReconciliationIssue(
        type: ReconciliationIssueType.conflictingLink,
        portalUid: portal.portalUid,
        clientId: portal.clientId,
        conflictingPortalUid: client.portalUid,
      ));
    }

    return ClientPortalReconciliationReport(repairedCount: repairedCount, issues: issues);
  }
}

enum ReconciliationIssueType { conflictingLink, clientNotFound }

class ClientPortalReconciliationIssue {
  final ReconciliationIssueType type;
  final String portalUid;
  final String clientId;

  /// Non-null uniquement pour [ReconciliationIssueType.conflictingLink].
  final String? conflictingPortalUid;

  const ClientPortalReconciliationIssue({
    required this.type,
    required this.portalUid,
    required this.clientId,
    this.conflictingPortalUid,
  });
}

class ClientPortalReconciliationReport {
  final int repairedCount;
  final List<ClientPortalReconciliationIssue> issues;

  const ClientPortalReconciliationReport({required this.repairedCount, required this.issues});
}
