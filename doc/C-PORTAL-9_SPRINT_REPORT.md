# Rapport de fin de sprint — C-PORTAL.9

> Clôturé le 2026-09-09 · Branche `feature/c-portal-9` · 3 commits
> Une rule déployée pendant ce sprint (immuabilité des compteurs de
> backfill côté client), avant l'étape 3 — voir §4 et §7.

---

## 1. Résumé en une phrase

Le résiduel majeur de C-PORTAL.8 (aucun backfill de l'historique
existant) est fermé : `ClientPortalHistoryBackfillService` reprend
prestations et dépenses par lots au provisioning et à la demande, avec
un statut persisté que le client ne peut pas falsifier et une UI qui
distingue explicitement "jamais lancé", "complet" et "incomplet" —
plus un bug de lecture trouvé et corrigé avant tout code UI, pas en
test terrain.

---

## 2. Ce qui a été fait, étape par étape

### Étape 1 — `ClientPortalHistoryBackfillService`
Copie l'historique existant (`WorkEntry`/`Expense`) en lots de 500
(limite d'un `WriteBatch` Firestore), réutilisant les mêmes IDs de
document que le mirroring normal (idempotent : rejouer ne duplique
rien, complète ce qui manque). Le filtre `isBillable` sur les dépenses
est appliqué **avant** toute construction de batch — jamais laissé à la
rule, un `WriteBatch` étant tout ou rien, une seule dépense non
refacturable ferait échouer tout le lot. Prouvé par un test
d'intégration montrant que sans ce filtre, un batch contenant une seule
dépense non refacturable échoue intégralement contre les vraies rules,
y compris les documents par ailleurs valides.

Prestations et dépenses sont tentées **indépendamment** : l'échec total
des unes ne doit jamais empêcher la tentative des autres (décidé et
argumenté avec William avant de coder). `BackfillOutcome` porte deux
compteurs séparés, jamais agrégés.

Preuve d'intégration (émulateur + AVD réel) : 600 prestations (>500,
force le découpage en plusieurs lots) écrites puis rejouées sans
duplication, vérifiées en lecture côté client réel (l'artisan n'a
jamais eu accès en lecture au miroir, découvert en écrivant ce test).

### Étape 2 — Statut persisté, immuable côté client
Les compteurs de backfill sont écrits sur `clientPortals/{portalUid}`
mais **exclus de l'entité `ClientPortal` partagée** — garantie
structurelle (pas une convention) : `decideRoleRoute()` ne voit jamais
que des `ClientPortal`, qui ne peuvent physiquement pas porter ces
champs. Lus par une voie séparée (`getBackfillStatus`), jamais via
`getPortal()`.

**Rule modifiée** : les 4 champs ajoutés à la liste des champs
immuables côté client de la rule `update` déjà en place. Méthodologie
filet d'abord : caractérisé que le client POUVAIT écrire ces champs
(vert contre les rules d'avant), fix appliqué, même assertion rejouée
→ rouge, corrigée en `assertFails`, plus un test de non-régression pour
un document sans aucun champ backfill (le portail BGS de William,
créé avant ce sprint) — `.get(champ, null)` plutôt qu'un accès direct,
pour ne pas faire échouer une écriture sur un ancien document. Suite
rules complète : 152/152 avant déploiement.

**Déployé par William** sur `worklog-pro-2b3fb` entre l'étape 2 et
l'étape 3, confirmé avant de coder la suite — pas testé après coup.

### Étape 3 — UI sur `ClientDetailPage`
Indicateur persistant à trois états (jamais lancé / complet /
incomplet), prestations et dépenses toujours sur deux lignes séparées,
jamais un total. Bouton "Reprendre l'historique" **toujours visible**
dès `portalUid != null` — pas seulement quand incomplet, pour que le
portail BGS (jamais backfillé) en profite aussi. Backfill automatique
best-effort à la création d'un portail, SnackBar de résultat séparé de
celui de création. Un backfill à 0 prestation/0 dépense a son propre
message neutre ("Aucun historique à reprendre") — 0/0 est sinon
indiscernable d'un succès complet par les seuls compteurs, et un succès
silencieux serait indiscernable d'un échec silencieux.

**Bug trouvé avant tout code UI, pas en test terrain** :
`getBackfillStatus()` tel qu'écrit à l'étape 2 faisait un `.get()`
direct sur `clientPortals/{portalUid}` — or `allow get` sur ce document
exige `isOwner(portalUid)` (le CLIENT), jamais l'artisan, qui n'a
toujours eu que `list()` (filtré par `artisanUid`, déjà utilisé par
`listPortalsForArtisan`). Un test rules existait déjà pour le prouver
mais n'avait jamais été mis en regard du nouveau code de l'étape 2.
Le test AVD de l'étape 2 ne l'a pas révélé non plus : il ne couvrait
que l'écriture (`saveBackfillStatus`, via `update()`, qui n'a pas cette
asymétrie), jamais la lecture — **un sens de l'accès testé, pas
l'autre**, pas un simple défaut de couverture. Corrigé en réutilisant
la requête `list` déjà déployée (même forme que
`listPortalsForArtisan`), sans nouvelle rule ni redéploiement — vérifié
empiriquement (artisan lié trouve son document ; artisan non lié
obtient un résultat vide, jamais une erreur) **avant** d'écrire le
moindre code Dart.

---

## 3. Chiffres finaux

| Mesure | Avant sprint | Après sprint |
|---|---|---|
| Tests automatisés (`flutter test`) | 406 | **431**, tous verts |
| Tests rules Firestore (émulateur) | 149 | **154** (+5 : immuabilité des compteurs ×2, non-régression document sans champs backfill, lecture artisan lié/non lié ×2) |
| Tests intégration (émulateur + AVD réel, `integration_test/`) | 14 | **16** (+2 : volume 600 + idempotence, filtre isBillable contre les vraies rules) |
| `flutter analyze` | 12 info | **12 info** (inchangé) |
| Backfill de l'historique | inexistant | **fait**, au provisioning et à la demande, avec statut persisté et UI dédiée |
| Rule déployée | — | ✅ immuabilité des compteurs backfill côté client |
| Build APK release | — | ✅ réussi |

---

## 4. Documents mis à jour

- **`CONTEXT.md`** — §5 (historique repris, plus de résiduel), §9
  (section C-PORTAL.9 "Résolue" avec le tableau des fixes + le constat
  get/list), §12 (portail client marqué ✅ utilisable en pratique,
  chiffres à jour, C-PORTAL.10 en tête des prochaines étapes).
- **`doc/C-PORTAL-9_SPRINT_REPORT.md`** — ce document.
- `SECURITY_AUDIT.md` — non touché (le fix de rule n'est pas une
  vulnérabilité corrigée mais une immuabilité renforcée, déjà dans la
  même catégorie que les fixes existants ; aucun nouveau finding).

---

## 5. Ce qui reste ouvert

- **C-PORTAL.10 — distinction archives/en cours après un solde de
  compte** : le backfill recopie tout sans distinction, un client voit
  dans la même liste ce qu'il a déjà payé et ce qu'il doit. Plan et
  options déjà discutés avec William, conception à faire, pas encore
  commencé.
- **Dépenses côté client** dans `ClientHomePage` (affichage) : toujours
  une étape séparée, non planifiée.
- Résiduels C-PORTAL/C-PORTAL.8 déjà connus, non rouverts par ce
  sprint : CP1, client mal routé pour raison réseau, App Check web sans
  branche debug, flux du miroir rouvert après désactivation.
- Findings L1-L6, I1, I3-I5 (`SECURITY_AUDIT.md`) : toujours ouverts,
  hors périmètre.

---

## 6. Actions qui reviennent à William

1. **Merge de la PR** : pas de PR mergée sans confirmation explicite.
2. Rule déjà déployée pendant ce sprint (voir §2, étape 2) — rien de
   plus à déployer pour clore ce sprint.
3. **Décider du lancement de C-PORTAL.10** et trancher les deux points
   de conception déjà réglés dans la conversation (un seul pivot de
   solde, split sur `createdAt`) plus la question d'affichage
   (archives en section séparée ou badge).

---

## 7. Commits du sprint (3)

```
0652e80 feat(client-portal): add history backfill service (C-PORTAL.9 step 1)
21f9527 feat(client-portal): persist backfill status, immutable to the client (C-PORTAL.9 step 2)
4d88523 feat(client-portal): backfill status UI on ClientDetailPage (C-PORTAL.9 step 3)
```

(+ commit de clôture : resync `CONTEXT.md` et ce rapport — voir
l'historique pour son hash exact.)
