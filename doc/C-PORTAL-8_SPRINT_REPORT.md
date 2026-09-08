# Rapport de fin de sprint — C-PORTAL.8

> Clôturé le 2026-09-09 · Branche `feature/c-portal-8` · 3 commits
> Aucune rule à déployer pour ce sprint (rien touché dans `firestore.rules`).

---

## 1. Résumé en une phrase

`ClientHomePage` affiche désormais la vraie liste de prestations d'un
client depuis son miroir, avec une preuve d'isolation réelle entre deux
clients et une garde anti-boucle trouvée et corrigée grâce à un test
écrit avant la moindre supposition — mais un résiduel majeur, identifié
par William avant la clôture plutôt que découvert en test, rend la
fonctionnalité inutilisable en pratique pour un client avec de
l'historique antérieur à la création de son portail.

---

## 2. Ce qui a été fait, étape par étape

### Étape 1 — `ClientMirrorRepository`, lecture du miroir
`watchMyWorkEntries()` sans aucun paramètre `portalUid` — le uid est
dérivé une seule fois, au constructeur de l'implémentation, sourcé par
le provider depuis la session authentifiée. Aucun appelant (widget ou
autre) ne peut donc structurellement demander le miroir de quelqu'un
d'autre. Tri par date décroissante côté Firestore (`orderBy` à un seul
champ, aucun index composite requis — vérifié avant de coder) puis tri
secondaire par `createdAt` côté Dart pour départager deux prestations
du même jour de façon stable, sans exiger de second `orderBy()`.

Preuve d'isolation : `integration_test` contre l'émulateur ET l'AVD
réel, deux vrais comptes clients, chacun avec sa propre prestation
mirrorée par un vrai artisan — le vrai repository (pas un fake) ne
renvoie jamais que le miroir du client authentifié.

### Détour empirique — comportement d'un portail désactivé
Avant de coder l'étape 2, mesuré (émulateur ET vraie prod, avec compte
de test réel) ce que fait `watchMyWorkEntries()` sur un portail
`enabled: false` :

```
Flux DÉJÀ ouvert, avant désactivation           -> reçoit les données normalement
CE MÊME flux, après désactivation (5s après)    -> ERREUR permission-denied (coupé correctement)
get() frais, après désactivation                -> permission-denied
snapshots() FRAIS (nouveau), après désactivation -> AUCUNE erreur, données renvoyées quand même
```

Un flux déjà ouvert est bien coupé quand la désactivation survient
pendant qu'il tourne — le scénario réel qui comptait. Un flux
nouvellement rouvert après coup ne l'est pas, sans documentation
officielle Firestore trouvée pour l'expliquer (cherché avant de
conclure). Calibré par William comme un résiduel acceptable : pas une
révocation d'urgence dans son usage, le client concerné ne voit que ses
propres données, quelques minutes de plus au pire.

### Étape 2 — `ClientHomePage` sur le vrai flux
Rendu (chargement, données, liste vide, erreur+Réessayer) branché sur
`myWorkEntriesStreamProvider`. Interception ciblée sur
`permission-denied` **uniquement** pour réinvalider `userPortalProvider`
— pas sur n'importe quelle erreur, pour ne pas rebasculer un client à
connexion instable vers l'espace artisan (`decideRoleRoute()` route une
erreur réseau vers artisan, ce qui serait l'inverse de l'effet voulu
ici).

**Bug trouvé par un test écrit avant toute supposition** : William a
demandé de vérifier, pas déduire, si `ref.listen` pouvait boucler en
cas de `permission-denied` répétés sur un portail resté réellement
`enabled`. Un premier test sans garde a montré 1 → 2 → 3 → 4 appels
`getPortal()` pour 3 échecs consécutifs — sans borne. Corrigé par une
garde "une seule réinvalidation par épisode d'erreur" (réarmée à la
reprise), `ClientHomePage` converti en `ConsumerStatefulWidget`. Le
test sans garde est gardé comme régression à côté du test avec garde.

---

## 3. Le résiduel qui bloque un usage réel (pas un bug de ce sprint)

En répondant à la question de William avant la clôture — "un client à
qui je crée un accès aujourd'hui verra-t-il son historique déjà
saisi ?" — confirmé par le code : **non**. Le mirroring
(`ClientPortalMirrorService`) n'est appelé que par
`createWorkEntry`/`updateWorkEntry`/`deleteWorkEntry`, jamais par un
mécanisme qui reprendrait l'historique existant au moment du
provisioning. Aucun backfill nulle part dans le repo.

Un client avec des mois de prestations réelles verrait un écran vide à
la création de son accès — pire qu'un défaut mineur, ça rend la
fonctionnalité inutilisable pour l'usage réel de William. Traité comme
son propre sprint, **C-PORTAL.9**, pas greffé sur celui-ci : ça touche
le provisioning (domaine de C-PORTAL.5), pas la lecture côté client
(domaine propre de C-PORTAL.8, déjà testé et clos).

---

## 4. Chiffres finaux

| Mesure | Avant sprint | Après sprint |
|---|---|---|
| Tests automatisés (`flutter test`) | 401 | **406**, tous verts |
| Tests rules Firestore (émulateur) | 149 | **149** (inchangé, rien touché dans `firestore.rules`) |
| Tests intégration (émulateur + AVD réel, `integration_test/`) | 13 | **14** (+1, isolation réelle entre deux clients) |
| `flutter analyze` | 12 info | **12 info** (inchangé) |
| `ClientHomePage` | placeholder statique | **liste réelle**, triée, isolée, avec garde anti-boucle |
| Build APK release | — | ✅ réussi |

---

## 5. Documents mis à jour

- **`CONTEXT.md`** — §5 (lecture du miroir, résiduel backfill noté),
  §6 (`ClientHomePage` réelle), §9 (fixes de l'étape + résiduel majeur
  documenté explicitement comme bloquant), §12 (chiffres, portail
  client marqué ⚠️ pas encore utilisable en pratique, C-PORTAL.9 en
  tête des prochaines étapes).
- **`doc/C-PORTAL-8_SPRINT_REPORT.md`** — ce document.
- `SECURITY_AUDIT.md` — non touché (aucune rule modifiée ce sprint).

---

## 6. Ce qui reste ouvert

- **C-PORTAL.9 — reprise de l'historique** (bloquant, priorité avant
  toute autre étape du portail client) : plan déjà discuté avec
  William (batchs Firestore, idempotence par réutilisation de l'ID de
  document, échec partiel non bloquant mais visible côté artisan avec
  relance immédiate, filtrage `isBillable` des dépenses avant écriture,
  bouton "Reprendre l'historique" sur `ClientDetailPage` dès cette
  étape — pas reporté).
- **Dépenses côté client** dans `ClientHomePage` : après C-PORTAL.9.
- **Flux rouvert après désactivation sert les données quand même** :
  résiduel accepté, documenté (`CONTEXT.md` § Dette), pas corrigé —
  calibré comme un risque de fiabilité mineur, pas une fuite.
- Findings L1-L6, I1, I3-I5 (`SECURITY_AUDIT.md`) : toujours ouverts,
  hors périmètre.

---

## 7. Actions qui reviennent à William

1. **Décider de lancer C-PORTAL.9** (plan déjà validé dans la
   conversation) — priorité avant tout usage réel du portail client.
2. **Tester le parcours réel** : un client avec de l'historique
   existant confirmera concrètement l'écran vide avant C-PORTAL.9.
3. **Merge de la PR** : pas de PR ouverte sans confirmation explicite.

---

## 8. Commits du sprint (3)

```
7876df6 feat(client-portal): add ClientMirrorRepository, read-only workEntries mirror (C-PORTAL.8 step 1)
0263eaa docs(context): record measured behavior of a reopened stream after portal disable
74ce7c7 feat(client-portal): wire ClientHomePage to the real mirror stream (C-PORTAL.8 step 2)
```

(+ commits de clôture : resync `CONTEXT.md` et ce rapport — voir
l'historique pour leurs hashes exacts.)
