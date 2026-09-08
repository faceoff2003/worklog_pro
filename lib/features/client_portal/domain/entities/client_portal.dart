import 'package:freezed_annotation/freezed_annotation.dart';

part 'client_portal.freezed.dart';
part 'client_portal.g.dart';

/// Profil du portail client (C-PORTAL) : clientPortals/{portalUid}.
///
/// portalUid n'est PAS un champ ici — c'est l'ID du document, réattaché par
/// le repository comme pour Client/WorkEntry/Expense. artisanUid et
/// clientId sont immuables une fois créés (voir firestore.rules) ; enabled
/// est le seul champ que l'artisan peut modifier ensuite.
///
/// Le document Firestore porte aussi les compteurs de reprise d'historique
/// (backfillWorkEntriesTotal, etc. — voir ClientPortalRepository.
/// saveBackfillStatus/getBackfillStatus) : EXCLUS DÉLIBÉRÉMENT d'ici. Comme
/// fromJson() ignore les clés inconnues (pas de disallowUnknownKeys), ceci
/// est une garantie structurelle, pas juste une convention : un ClientPortal
/// ne peut physiquement jamais porter ces compteurs, donc decideRoleRoute()
/// (qui ne voit que des ClientPortal) ne peut structurellement pas en
/// dépendre. Lus par une voie séparée (getBackfillStatus), jamais ici.
@freezed
abstract class ClientPortal with _$ClientPortal {
  const factory ClientPortal({
    /// uid Firebase Auth du compte portail (= l'ID du document).
    required String portalUid,

    /// uid de l'artisan propriétaire de ce lien. Immuable.
    required String artisanUid,

    /// Identifiant du Client (users/{artisanUid}/clients/{clientId}) lié à
    /// ce portail. Immuable.
    required String clientId,

    /// Accès actif ou non. Ne gate que le client — jamais le mirroring de
    /// l'artisan, qui continue même désactivé.
    required bool enabled,

    /// Nom d'affichage propre au client, modifiable par lui.
    String? displayName,

    required DateTime createdAt,

    /// Pivot du split "Archives" / "En cours" côté client (C-PORTAL.10).
    /// C'est TOUJOURS ClientSettlement.createdAt qui est stocké ici, JAMAIS
    /// ClientSettlement.date — parce que clientBalanceProvider (le calcul
    /// de balance de l'artisan) filtre déjà ses propres prestations/dépenses
    /// sur `createdAt.isAfter(cutoff)`, pas sur `date` (voir
    /// client_balance_providers.dart). Si le split ici se faisait sur
    /// `date`, le client et l'artisan calculeraient deux soldes différents
    /// sur le même compte pour les mêmes prestations — pire qu'un cas
    /// limite, une contradiction visible. Limite connue, partagée avec le
    /// calcul de l'artisan (pas propre au portail) : une prestation dont la
    /// date de travaux précède le solde mais saisie APRÈS compte comme "en
    /// cours", pas "archivée" — si ce critère doit changer, il doit changer
    /// des deux côtés à la fois, jamais ici seul.
    ///
    /// null = aucun solde de compte n'a jamais été enregistré pour ce
    /// client ; tout est "en cours".
    DateTime? lastSettlementCreatedAt,
  }) = _ClientPortal;

  factory ClientPortal.fromJson(Map<String, dynamic> json) => _$ClientPortalFromJson(json);
}
