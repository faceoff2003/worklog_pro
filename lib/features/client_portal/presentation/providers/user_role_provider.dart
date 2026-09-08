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
/// Décision du 2026-09-08 (mesure empirique à l'appui) : SEUL
/// permission-denied bloque. Tout le reste (unavailable, deadline-exceeded,
/// cancelled, TimeoutException du timeout ci-dessus, code imprévu) route
/// vers artisan — un code d'erreur non anticipé ne doit jamais bloquer un
/// artisan en production, et router à tort vers artisan n'ouvre aucun trou
/// de sécurité : users/{uid}/... est scopé par isOwner(uid), un client
/// mal routé n'y voit et n'y écrit jamais que dans SON PROPRE espace vide,
/// jamais les données d'un autre artisan.
///
/// Résiduel accepté, pas corrigé (documenté aussi dans CONTEXT.md § Dette,
/// 2026-09-08) : un CLIENT hors ligne (ou dont la vérification échoue pour
/// une raison autre que permission-denied) atterrit sur HomePage et peut
/// théoriquement y créer des documents sous users/{son_propre_uid}/... —
/// autorisé par les rules (c'est son propre espace), ça ne pollue les
/// données d'aucun artisan réel, mais ça laisse des documents orphelins
/// sous cet uid si jamais un rôle lui était réellement attribué plus tard.
RoleRoute decideRoleRoute(AsyncValue<ClientPortal?> state) {
  return state.when(
    data: (portal) {
      if (portal == null) return RoleRoute.artisan;
      return portal.enabled ? RoleRoute.clientEnabled : RoleRoute.clientDisabled;
    },
    loading: () => RoleRoute.checking,
    error: (error, _) {
      if (error is FirebaseException && error.code == 'permission-denied') {
        return RoleRoute.blocked;
      }
      return RoleRoute.artisan;
    },
  );
}
