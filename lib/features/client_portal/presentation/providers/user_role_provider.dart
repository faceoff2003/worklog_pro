import 'dart:async' show TimeoutException;

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';

/// Détermine le rôle d'un utilisateur authentifié à partir de
/// clientPortals/{uid} — null = artisan (comportement historique, aucun
/// signal positif "je suis artisan" n'a jamais existé), trouvé = client.
///
/// Timeout 15s en filet : mesuré empiriquement (2026-09-08, AVD réel,
/// document jamais mis en cache, backend injoignable, SDK non prévenu) que
/// le SDK lâche déjà une FirebaseException(code: 'unavailable') après
/// ~11,7s de lui-même — ce timeout ne sert donc qu'à couvrir un hang qui ne
/// lèverait jamais cette erreur spontanément, pas le cas courant.
final userPortalProvider = FutureProvider.family.autoDispose<ClientPortal?, String>((ref, uid) {
  return ref.watch(clientPortalRepositoryProvider).getPortal(uid).timeout(const Duration(seconds: 15));
});

enum RoleRoute { checking, artisan, clientEnabled, clientDisabled, blocked }

/// Pure — aucune dépendance Firebase/Flutter, testable sans emulateur ni
/// widget. Seule la vérification de rôle passe par ici ; les données
/// réelles (workEntries, expenses...) restent protégées par firestore.rules
/// indépendamment de ce que cette fonction décide.
///
/// Décision révisée le 2026-09-08, après un vrai bug (TypeError de
/// désérialisation sur clientPortals/{uid}.createdAt, voir
/// client_portal_repository_impl.dart) qui a montré que la version
/// précédente ("tout sauf permission-denied -> artisan") routait aussi les
/// erreurs de CODE vers artisan — pas seulement les pannes réseau qu'on
/// voulait couvrir. Un client dont la lecture plante pour une raison de bug
/// (désérialisation, exception inattendue) doit voir un écran de blocage,
/// pas atterrir silencieusement dans l'espace artisan.
///
/// Règle désormais : SEULES les erreurs identifiées comme réseau routent
/// vers artisan (usage hors ligne, mesuré empiriquement le 2026-09-08 —
/// voir le commentaire sur userPortalProvider). Tout le reste bloque,
/// y compris permission-denied, unauthenticated (token invalide/expiré —
/// un vrai problème d'identité, pas un problème réseau, ne doit pas être
/// masqué), les erreurs de désérialisation, et tout type imprévu.
///
/// Router à tort vers artisan (cas réseau) n'ouvre aucun trou de sécurité :
/// users/{uid}/... est scopé par isOwner(uid), un client mal routé n'y voit
/// et n'y écrit jamais que dans SON PROPRE espace vide, jamais les données
/// d'un autre artisan — résiduel accepté, documenté dans CONTEXT.md § Dette.
const _networkErrorCodes = {'unavailable', 'deadline-exceeded', 'cancelled'};

RoleRoute decideRoleRoute(AsyncValue<ClientPortal?> state) {
  return state.when(
    data: (portal) {
      if (portal == null) return RoleRoute.artisan;
      return portal.enabled ? RoleRoute.clientEnabled : RoleRoute.clientDisabled;
    },
    loading: () => RoleRoute.checking,
    error: (error, _) {
      final isNetworkError =
          error is TimeoutException || (error is FirebaseException && _networkErrorCodes.contains(error.code));
      return isNetworkError ? RoleRoute.artisan : RoleRoute.blocked;
    },
  );
}
