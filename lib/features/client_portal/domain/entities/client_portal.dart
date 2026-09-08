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
  }) = _ClientPortal;

  factory ClientPortal.fromJson(Map<String, dynamic> json) => _$ClientPortalFromJson(json);
}
