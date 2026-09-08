# SECURITY_AUDIT.md — worklog_pro

> Sprint R-SEC.1 — audit lecture seule. Aucun fichier modifié à part celui-ci.
> Audité sur le code réel (`firestore.rules`, `storage.rules`, `lib/`, historique
> Git complet), le 2026-09-06. CONTEXT.md utilisé comme piste de départ
> uniquement — voir §7 pour les écarts constatés avec l'état réel du repo.
>
> **Clôture de sprint (R-SEC.5, 2026-09-06)** — statut final : M1 corrigé et
> livré (code Dart, dans l'APK release). M2/M3/M4/M5 corrigés dans le
> repo, non déployés à la clôture de ce sprint (contrainte explicite tout
> du long) — `firebase deploy --only firestore:rules` restait une action
> de William. Tous les L1-L6 et I1-I5 restaient **ouverts, non traités** :
> le périmètre R-SEC.2 n'a jamais couvert que M1-M5.
>
> **Mise à jour (sprint F-SETTINGS, 2026-09-07)** — M2/M3/M4/M5 **déployés
> et vérifiés sur appareil par William** avant le début du sprint
> F-SETTINGS. M5 a reçu une extension pendant F-SETTINGS.8 (validation du
> nouveau champ `updatedAt`), également déployée et vérifiée — voir le
> statut détaillé de M5 plus bas. L1-L6 et I1-I5 restent ouverts, non
> traités par F-SETTINGS (hors périmètre — sprint de synchronisation
> cloud des réglages, pas un sprint sécurité).
>
> **Mise à jour (sprint C-PORTAL, 2026-09-07)** — nouveau finding **CP1**
> (Medium), trouvé et corrigé partiellement pendant la construction des
> rules `clientPortals`, **rules non déployées**. Voir §1 pour le détail.
>
> **Clôture (sprint C-PORTAL, 2026-09-08)** — bloc `clientPortals`
> (avec CP1) **déployé et vérifié sur appareil par William** (parcours
> réel : création de portail, connexion client/artisan). **I2 confirmé
> actif** pour Firestore — par l'échec réel d'une écriture, pas par la
> console, voir I2. Aucun autre finding L1-L6/I1-I5 traité, hors
> périmètre C-PORTAL — voir §7ter pour la clôture complète.

---

## 0bis. C-PORTAL — résumé

| Sévérité | Nombre |
|---|---|
| Medium | 1 (CP1, fix partiel appliqué, **déployé** le 2026-09-08, résiduel documenté) |

Voir aussi I2 (§3) : confirmé actif pour Firestore pendant ce sprint,
et §7ter pour la clôture complète.

---

## 0. Résumé

| Sévérité | Nombre |
|---|---|
| Critical | 0 |
| High | 0 |
| Medium | 5 |
| Low | 6 |
| Informational | 5 |

Aucune faille critique ou haute trouvée : isolation par utilisateur
(`isOwner`) correcte sur toutes les collections, aucun secret réel dans
l'historique Git, App Check actif, messages d'erreur d'auth déjà
non-énumérables. Les points medium concernent tous la même famille de
problème : des champs numériques ou des transitions d'état ne sont pas
validés côté rules alors qu'ils portent de l'argent ou une garantie
métier (immuabilité, cohérence enum).

---

## 1. Medium

### M1 — `calculateDuration` négatif → écriture `workEntries` rejetée silencieusement
**Fichiers** : `lib/features/work_entries/domain/services/work_calculator_service.dart:17-25`
(bug caractérisé en R-SEC.0) × `firestore.rules:110,123` (`isPositiveInt(laborAmountHT)`)

Le bug déjà signalé en R-SEC.0 (`calculateDuration` peut renvoyer une durée
négative quand `endTime == startTime` avec une pause, ou quand la pause
dépasse la durée brute) se propage jusqu'au calcul de `laborAmountHT`. Une
durée négative produit un montant négatif ou nul selon le mode de
facturation. La rule `isPositiveInt(laborAmountHT)` (`field is int && field
>= 0`) rejette alors l'écriture côté serveur — **mais l'app ne montre
aujourd'hui aucun message d'erreur exploitable à l'utilisateur** : le
`WorkEntryFormPage` ne distingue pas un rejet de rules d'une autre erreur
réseau. L'artisan croit avoir sauvegardé sa prestation ; elle n'existe
nulle part.

**Ce qu'un utilisateur peut vivre** : saisie d'heures de début/fin
identiques avec une pause non nulle (faute de frappe plausible) → la
prestation disparaît sans explication.

**Fix proposé** (R-SEC.3, pas ici) : corriger `calculateDuration` pour
qu'il ne puisse jamais produire de valeur négative (clamp à 0 ou rejet
explicite avec message utilisateur), et faire remonter les erreurs de
permission Firestore (`permission-denied`) comme un message visible
distinct d'une erreur réseau.

**Statut final (R-SEC.3 étape 1, 2026-09-06) : ✅ CORRIGÉ ET LIVRÉ.**
Décision prise avec William (exception plutôt que clamp ou Result,
alignée sur la convention de `WorkDuration.fromTimeRange`) :
`calculateDuration` lève désormais `ArgumentError`. Validation live
ajoutée sur le champ Pause (`WorkEntryFormPage._validatePause`,
message visible pendant la saisie, pas seulement au submit) — le
try/catch au niveau de `_save()`/`_recalculate()` reste un filet, pas
la validation. Vérifié sur appareil par William (8h00/8h00/10min et
8h00/12h00/300min). C'est un fix de code Dart (pas une rule Firestore)
: **inclus dans l'APK release buildé en R-SEC.5**, aucune action de
déploiement séparée requise.

### M2 — `client_settlements` : l'immuabilité est contournable par delete + recreate
**Fichier** : `firestore.rules:193-206`

```
allow update: if false;   // "Les soldes ne sont pas modifiables"
allow delete: if isOwner(userId);
```

L'intention documentée dans le commentaire (soldes immuables une fois
créés) n'est pas réellement appliquée : un `delete` suivi d'un `create`
avec les mêmes champs mais un `balanceAtSettlement` différent produit
exactement le même effet qu'un `update` non autorisé. Comme
`client_settlements` sert à figer un solde de compte (probablement à
valeur d'archive comptable pour l'artisan), c'est une garantie métier
défaite, pas juste un détail technique.

**Fix proposé** : soit accepter que `delete` = trappe d'échappement
volontaire (et le documenter comme tel), soit retirer `allow delete` et
n'autoriser que `create` (les soldes deviennent alors vraiment
immuables, sans purge possible depuis le client).

**Statut final : ✅ CORRIGÉ ET DÉPLOYÉ.**
Tranché par William : `allow delete: if false`. Confirmé avant le fix
que `deleteSettlement()` existe dans `settlement_repository_impl.dart`
mais n'est appelé par aucune page/widget — coût fonctionnel nul.
Testé sur l'émulateur (`firestore-tests/`, 92/92 avant, après). Déployé
sur `worklog-pro-2b3fb` et vérifié sur appareil par William avant le
début du sprint F-SETTINGS (2026-09-07).

### M3 — `defaultRates` (clients) entièrement non validé
**Fichier** : `firestore.rules:57-72`

Le document `clients` valide `name`, `type`, les timestamps — mais
jamais `defaultRates` (map `{hour, halfDay, day, fixedJob}`, en
centimes). Un client compromis (ou un bug côté formulaire) peut écrire
un tarif négatif ou un type incorrect (`string` au lieu d'`int`) dans
`defaultRates.hour`. `WorkCalculatorService.calculateLaborCost` fait
ensuite confiance à cette valeur sans la re-valider (`rates.hour ??
Money.zero`, puis `hourlyRate * hours` sans jamais vérifier le signe).
Résultat possible : facture à montant négatif, calculée et affichée
sans qu'aucune rule ni aucun code Dart n'intercepte l'anomalie.

**Fix proposé** : valider `defaultRates.hour/halfDay/day/fixedJob` comme
`isPositiveInt` (quand présents) dans les rules `clients`, en miroir de
ce qui est déjà fait pour `laborAmountHT` sur `workEntries`.

**Statut final : ✅ CORRIGÉ ET DÉPLOYÉ.**
Pattern "absent OU null OU positif" (jamais "obligatoire") par clé,
vérifié contre la forme réelle des données (`_$DefaultRatesToJson`
inclut toujours les 4 clés, `null` quand un tarif n'est pas défini —
un pattern strict aurait cassé tout client existant sans defaultRates
complet). Testé sur l'émulateur avant/après. Déployé et vérifié — même
statut que M2.

### M4 — Enums métier sans whitelist dans les rules : `type` (projects), `materialCategory` et `travelMode` (expenses)
**Fichier** : `firestore.rules` (`projects` §75-94, `expenses` §134-156)

Voir le tableau complet en §6. Trois champs correspondant à un enum
Dart n'ont **aucune** contrainte `in [...]` côté rules : `ProjectType`
(6 valeurs), `MaterialCategory` (8 valeurs), `TravelMode` (3 valeurs).
N'importe quelle chaîne peut y être écrite. Comme les modèles Freezed
appellent `XxxEnum.fromJson(value)` à la lecture, et que ce
`fromJson` lève `ArgumentError` pour toute valeur inconnue (voir
`enums.dart:31-37` etc.), une valeur invalide écrite une fois plante la
lecture de ce document — et potentiellement l'écran entier qui liste
la collection — pour l'utilisateur propriétaire, sans qu'aucune autre
personne ne soit affectée (l'isolation `isOwner` tient).

**Fix proposé** : ajouter les trois whitelists manquantes, à l'identique
du pattern déjà utilisé pour `billingMode`/`category`/`status`.

**Statut final : ✅ CORRIGÉ ET DÉPLOYÉ.**
Whitelists ajoutées avec les valeurs complètes de `enums.dart`, pattern
"absent OU null OU dans la liste" — **rendu obligatoire par les
données réelles** : le script `scripts/list-distinct-enum-values.mjs`
lancé par William contre la prod a trouvé 4 documents
`expense.materialCategory` null et 14/14 documents `expense.travelMode`
null. Une whitelist stricte (sans tolérance null) aurait bloqué toute
modification future de ces documents. Filet ajouté d'abord (9 tests
caractérisant l'acceptation actuelle), vérifié sur les rules non
modifiées via `git stash` (88/92, seuls les 3 cas visés par le fix
échouaient), puis 92/92 après. Déployé et vérifié.

### M5 — `settings` : écriture libre, zéro validation de champ
**Fichier** : `firestore.rules:185-188`

```
allow read: if isOwner(userId);
allow write: if isOwner(userId);
```

Aucune contrainte de type, de taille de document ou de structure. Un
client buggé peut écrire un document `settings` arbitrairement gros ou
mal typé (ex. `schemaVersion` en string au lieu d'int), ce qui cassera
silencieusement toute logique qui en dépend (migrations futures,
préférences PDF). Isolation par propriétaire correcte, donc pas
d'exposition inter-utilisateurs — mais aucun garde-fou d'intégrité.

**Fix proposé** : au minimum valider `schemaVersion is int` et une
borne de taille sur les champs texte (en-tête PDF, etc.) si le modèle
`Settings` est stable.

**Statut R-SEC.2 (2026-09-06) : ✅ CORRIGÉ, déployé avant le début de
F-SETTINGS** (validation de type par champ connu + plafonds, voir
commit `f2bb600`). À la clôture de R-SEC, l'audit prod avait trouvé
0 document dans `users/{userId}/settings` — pas une base vide par
accident : `Settings` était persisté exclusivement via
`SharedPreferences` (clé `app_settings`, JSON local), aucun code de
l'app n'écrivait jamais sur ce chemin Firestore. Décision de l'époque
(William, 2026-09-06) : garder les rules M5 en l'état sans câbler
Firestore tout de suite, dette suivie dans `CONTEXT.md` (sprint
`F-SETTINGS` à planifier).

**Mise à jour (sprint F-SETTINGS, 2026-09-07) : collection désormais
active.** `SyncingSettingsRepository` écrit maintenant sur
`users/{uid}/settings/main` (ID de document fixe) — local d'abord,
synchronisation cloud en tâche de fond, `SharedPreferences` conservé
comme cache offline. Voir `doc/F-SETTINGS_SPRINT_REPORT.md` pour
l'architecture complète (trois repositories : `LocalSettingsRepository`,
`FirestoreSettingsRepository`/`FirestoreCloudSettingsGateway`,
`SyncingSettingsRepository`).

**Règle `updatedAt` ajoutée et déployée (F-SETTINGS.8).** Le nouveau
champ `Settings.updatedAt` (introduit en F-SETTINGS.4 pour arbitrer les
conflits de synchronisation — le plus récent gagne) n'était initialement
couvert par aucune validation de type dans les rules M5 : un `updatedAt`
mal typé aurait été accepté silencieusement (seul le plafond de 20 clés
top-level protégeait, aucune contrainte propre au champ). Comme
`updatedAt` arbitre littéralement quelle version des données écrase
l'autre, un type invalide n'aurait pas juste cassé une lecture — il
aurait fait trancher un conflit dans le mauvais sens et écrasé
silencieusement les bonnes données. Fix :
`optionalString(request.resource.data, 'updatedAt', 40)`, même pattern
que `lastBackupAt`. Filet d'abord (suite 98 tests reconfirmée verte sur
les rules avant modification, le test démontrant la tolérance retourné
pour asserter le refus), puis fix, puis 98/98 après. **Déployé sur
`worklog-pro-2b3fb` et vérifié sur appareil par William.**

---

## 1bis. C-PORTAL — Medium

### CP1 — `clientPortals/{portalUid}` : `create` permettait à quiconque de s'auto-désigner `artisanUid` sur un `portalUid` de son choix — usurpation de rôle et écriture dans le miroir d'une victime
**Fichier** : `firestore.rules` (`match /clientPortals/{portalUid}`, bloc `allow create`)

`allow create` ne vérifiait que `request.resource.data.artisanUid ==
request.auth.uid` (l'auteur se déclare artisan de lui-même) et
`isValidString(clientId, 100)` — rien n'empêchait de choisir n'importe
quel `portalUid` (l'ID du document) indépendamment de qui l'écrit.
`update` était déjà correctement verrouillé (`artisanUid` immuable,
testé), mais `create` s'applique tant que le document n'existe pas
encore — y compris sur l'uid d'un vrai artisan qui n'a **jamais** eu de
portail, puisque son propre uid ne porte alors aucun document
`clientPortals`.

**Ce qu'un attaquant peut faire, vérifié empiriquement (pas supposé)** :
1. Connaissant l'uid Firebase d'une victime (un artisan, ou n'importe
   quel compte), créer `clientPortals/{uid_de_la_victime}` en
   s'auto-désignant `artisanUid`. **Accepté** avant le fix — confirmé en
   emulateur (`firestore-tests/rules.test.mjs`, tests marqués
   "RÉSIDUEL DOCUMENTÉ").
2. Le rôle applicatif (artisan vs client) étant déterminé uniquement
   par l'existence de `clientPortals/{monUid}` (voir CONTEXT.md), la
   victime bascule de rôle perçu à sa prochaine connexion — si c'était
   un artisan sans portail, il ne peut alors plus atteindre son propre
   écran d'accueil artisan. **Aucune rule `delete` n'existe sur ce
   document, pas même pour son propriétaire** (`isOwner(portalUid)`
   n'a jamais que `get`, jamais `delete`) — la victime elle-même ne
   peut pas supprimer le document usurpateur. Verrouillage persistant,
   non réversible depuis l'app, seule une intervention console Firebase
   (accès projet, pas la victime) peut le défaire.
3. L'attaquant devient simultanément `isLinkedArtisan(uid_de_la_victime)`
   (la fonction ne fait que lire `artisanUid` sur ce document qu'il
   vient de planter) et peut écrire dans
   `clientPortals/{uid_de_la_victime}/workEntries/...` — confirmé
   empiriquement, un faux document de prestation accepté dans ce
   miroir usurpé.

**Ce qu'il lui faut** : un compte authentifié quelconque (auto-inscrit,
trivial) qui n'a **jamais** son propre `clientPortals/{lui-même}` —
donc un autre artisan, ou un compte fraîchement créé sans lien
portail — et connaître l'uid Firebase exact de la victime. Ce dernier
point est la vraie barrière : l'uid n'est affiché nulle part dans
l'app à un tiers non lié à ce compte ; il faudrait l'obtenir hors
bande (capture d'écran, journal, ingénierie sociale, une fuite
ailleurs). Un **client portail légitime connaît l'uid de son propre
artisan** (il figure sur son propre profil, `clientPortals/{lui}.artisanUid`,
lecture normale et nécessaire) — c'est le vecteur le plus réaliste,
mais **fermé par le fix ci-dessous** : un client portail a par
définition déjà son propre `clientPortals/{lui-même}`, donc bloqué.

**Fix appliqué** : `!exists(/databases/$(database)/documents/clientPortals/$(request.auth.uid))`
ajouté à `allow create` — quiconque a déjà son propre profil client
portail ne peut plus en créer un autre, nulle part. Ferme le vecteur le
plus réaliste (un client portail malveillant visant son propre
artisan, dont il connaît légitimement l'uid). Testé empiriquement
avant/après sur la suite complète (144 → 148 tests, aucune régression
sur la création légitime d'un profil par un artisan pour un nouveau
client).

**Ce qui reste ouvert (résiduel, documenté, pas fermé)** : un compte
qui n'est **pas déjà** client portail (typiquement un autre artisan,
ou un compte tout juste créé) et qui connaît l'uid exact d'une cible
peut toujours planter `clientPortals/{cette_cible}` — confirmé
toujours accepté après le fix (tests "RÉSIDUEL DOCUMENTÉ"). **Non
fermable par une rule seule** : il n'existe aucun moyen, côté rules,
de vérifier qu'un compte est "légitimement" un artisan avant sa
première création de portail — le rôle lui-même n'est défini que par
l'absence de document `clientPortals`, une propriété qu'on ne peut pas
transformer en condition positive sans un signal externe (un custom
claim posé côté serveur, donc une Cloud Function avec Admin SDK —
explicitement hors périmètre de ce sprint, voir la décision sur la
création de compte). Documenté ici plutôt que laissé filer sans trace.

**Sévérité — Medium, pas High** : l'impact (verrouillage de rôle
persistant, non réversible sans accès console) est sérieux, mais la
précondition (connaître l'uid Firebase exact d'une cible, un
identifiant qui n'est exposé nulle part dans l'app à un tiers non lié)
limite fortement l'exploitabilité pratique pour un attaquant
extérieur. Le vecteur le plus réaliste (un client portail visant son
propre artisan) est fermé par ce fix.

**Statut : fix partiel déployé dans le repo, non déployé en prod
(comme toutes les rules C-PORTAL). Résiduel accepté et documenté,
pas de Cloud Function prévue pour le fermer complètement dans ce
sprint.**

---

## 2. Low

> **Statut final (2026-09-06) : tous ouverts, non traités.** Le
> périmètre R-SEC.2 n'a jamais couvert que M1-M5 (décision explicite,
> pas un oubli). L1-L6 restent des pistes pour un futur sprint sécurité.

### L1 — Le bloc "deny-all" en tête de `firestore.rules` ne fait rien
**Fichier** : `firestore.rules:8-10`

```
match /{document=**} {
  allow read, write: if false;
}
```

Firestore combine les `allow` d'un même chemin en OR — cette règle ne
peut jamais "bloquer" une règle `allow` plus spécifique définie plus
bas pour le même document ; elle ne s'applique qu'aux chemins qui ne
matchent aucune autre règle (ce qui est déjà le comportement par
défaut de Firestore en l'absence de règle). Inoffensif ici parce que
toutes les collections réelles ont une règle explicite, mais trompeur :
un futur mainteneur peut croire, à tort, que ce bloc protège un chemin
non prévu.

**Fix proposé** : supprimer le bloc, ou le remplacer par un commentaire
expliquant que l'absence de règle est déjà un deny-all.

### L2 — Champs texte libres non bornés (`notes`, `note`, `technicalNotes`, `accessNotes`)
**Fichiers** : `firestore.rules` — `clients`, `projects`, `payments`,
`client_settlements`

`clients.notes`, `projects.notes/technicalNotes/accessNotes`,
`payments.note`, `client_settlements.note` ne sont validés ni en
présence ni en taille. Un document Firestore reste plafonné à 1 Mio
par la plateforme, donc pas de DoS possible, mais un champ non borné
peut gonfler la facturation Firestore (lecture/stockage) sans qu'aucune
limite applicative ne s'applique.

**Fix proposé** : `isValidString(field, N)` avec un plafond raisonnable
(ex. 2000) si le champ est présent — ou accepter le risque
explicitement, il est mineur.

### L3 — `tags` (clients, workEntries) et `attachments` (workEntries, expenses) non validés
**Fichiers** : `firestore.rules` — `clients`, `workEntries`, `expenses`

Ni le type d'éléments (`tags` devrait être `list<string>`), ni la
longueur de liste, ni la structure des objets `attachments` (URL,
type MIME, taille) ne sont vérifiés par les rules. Cohérent avec le
constat déjà fait dans le skill firebase-security-audit : la validation
de forme des attachments demanderait soit des rules plus complexes,
soit une Cloud Function.

**Fix proposé** : plafonner `tags.size()` et valider que chaque élément
est une string ; documenter que la validation fine des attachments
reste hors de portée des rules seules.

### L4 — Aucune vérification que `id` (champ document) == l'ID du document Firestore
**Fichiers** : toutes les collections utilisateur

Le modèle stocke un champ `id` (UUID v4) en plus de l'ID de document
Firestore, sans jamais vérifier leur égalité dans les rules. Un client
buggé pourrait écrire un `id` qui ne correspond pas au nom du document,
cassant toute logique applicative qui ferait confiance à ce champ pour
retrouver le document.

**Fix proposé** : `request.resource.data.id == entryId` (ou équivalent
selon la collection) dans chaque `allow create`.

### L5 — Pas de "closed schema" : champs supplémentaires arbitraires acceptés partout
**Fichiers** : `firestore.rules` (toutes les collections)

Aucune règle ne restreint `request.resource.data.keys()` à un ensemble
fini. Un client peut ajouter n'importe quel champ additionnel à
n'importe quel document. Aucun code actuel ne lit de champ "caché"
comme un flag de privilège, donc pas d'exploitation connue aujourd'hui
— mais c'est une porte ouverte pour un futur champ sensible ajouté par
erreur sans protection.

**Fix proposé** : envisager `request.resource.data.keys().hasOnly([...])`
si la stabilité du schéma le permet (fragile à chaque évolution de
modèle — à peser).

### L6 — `web/firebase-config.js` : fichier mort, dupliqué, non ignoré par Git
**Fichiers** : `web/firebase-config.js`, `web/index.html:46-56`

`web/index.html` définit déjà son propre `firebaseConfig` inline et
l'utilise (`firebase.initializeApp(firebaseConfig)` ligne 56).
`web/firebase-config.js` contient une copie de la même config
(même `apiKey`) mais **n'est importé ni référencé nulle part** — code
mort. La clé qu'il contient est la clé Web publique Firebase (pas un
secret — cf. §4), donc ce n'est pas une fuite, mais c'est un fichier
à supprimer en nettoyage (R-SEC.4).

---

## 3. Informational

> **Statut final (2026-09-06) : tous ouverts, non traités**, sauf I5
> (déjà résolu, rien à faire). I2 et I3 attendent une réponse de
> William (vérification console Firebase) plutôt qu'un fix de code.
> **Mise à jour 2026-09-07 (C-PORTAL.7) : I2 confirmé** — voir la note
> datée dans la section I2 ci-dessous.

### I1 — Storage : `contentType` fourni par le client, spoofable
**Fichier** : `storage.rules:18-23`

Le filtre MIME (`image/.*` ou `application/pdf`) se base sur
`request.resource.contentType`, un en-tête fourni par le client et donc
falsifiable (un `.exe` peut être uploadé avec un `Content-Type:
image/png` forgé). La limite de 10 Mio tient (calculée côté serveur
sur la taille réelle). Couvrir le contenu réel nécessiterait une Cloud
Function de scan post-upload — hors de portée d'une règle Storage
seule. Risque résiduel à accepter en connaissance de cause, pas un bug
des rules actuelles.

### I2 — App Check : activation client confirmée, application au niveau
console à vérifier manuellement
**Fichier** : `lib/main.dart:26-41`

`FirebaseAppCheck.instance.activate()` est bien appelé avant tout accès
Firestore, avec `AndroidProvider.playIntegrity` en release et
`AndroidProvider.debug` uniquement en `kDebugMode` — configuration
correcte côté client. **Mais App Check dans le client ne bloque rien
tant que l'enforcement n'est pas activé dans la console Firebase**
(Firestore/Storage → App Check → Enforce). Cette bascule ne se fait pas
depuis le code — @William, peux-tu confirmer qu'elle est bien activée
côté console pour ce projet (`worklog-pro-2b3fb`) ?

**Confirmé le 2026-09-07 (C-PORTAL.7), par l'échec plutôt que par la
console.** En testant la création de portail sur le build web (jamais
testé sur web avant ce jour), `clientPortalRepository.createPortal()`
a échoué systématiquement avec une erreur App Check
(`appCheck/recaptcha-error` — la clé ReCAPTCHA v3 codée en dur dans
`main.dart` ne vérifie pas pour `localhost`, faute de branche debug
côté web, voir CONTEXT.md § Dette). L'écriture Firestore a été
réellement rejetée, pas seulement un avertissement côté client — donc
l'enforcement App Check est bien actif côté console pour Firestore.
Ce n'est plus une hypothèse à vérifier : l'échec observé EST la
preuve. Root cause du symptôme web = dette de code (pas de branche
debug App Check pour le web), pas un problème d'enforcement.

### I3 — Réinitialisation de mot de passe : protection anti-énumération dépendante d'un réglage console
**Fichier** : `lib/features/auth/data/repositories/auth_repository_impl.dart:132-141`,
`lib/core/errors/auth_exception.dart:21-24`

Bon point relevé : `user-not-found` et `wrong-password` renvoient
déjà le même message générique "Identifiants incorrects." — pas
d'énumération de compte via la connexion. Pour `sendPasswordResetEmail`,
en revanche, le comportement dépend du réglage "Email Enumeration
Protection" de Firebase Auth (activé par défaut sur les projets
récents, mais pas garanti ici) : si désactivé, une adresse inexistante
lèvera `user-not-found` (message d'erreur) alors qu'une adresse
existante affichera "Email envoyé" — ce qui permettrait de deviner les
comptes existants. Impossible à vérifier depuis le code seul.

### I4 — Dépendances Firebase à jour de version mineure, pas de majeure en retard
**Fichier** : `pubspec.yaml`

`flutter pub outdated` : `firebase_auth` 6.1.4 → 6.6.1, `firebase_core`
4.4.0 → 4.14.0, `firebase_storage` 13.0.6 → 13.5.0, `firebase_app_check`
0.4.1+4 → 0.4.7, `google_sign_in` déjà sur la dernière version
résolvable de sa contrainte majeure (6.3.0). Aucune régression de
sécurité connue identifiée, mais plusieurs versions mineures de retard
sur la pile Firebase — mise à jour de routine à envisager hors sprint
sécurité.

### I5 — Aucun secret réel dans l'historique Git
Recherche sur tout l'historique (`git log --all -p`) : aucune clé
privée, aucun `serviceAccountKey`, aucun fichier `.env` commité. Les
seules chaînes ressemblant à des clés (`AIzaSy...`) trouvées dans
`lib/firebase_options.dart`, `web/firebase-config.js` et
`web/index.html` sont les clés Web/Android **publiques** Firebase — pas
des secrets, conformément à la doc Firebase (l'accès réel est
contrôlé par les rules + App Check + Auth, pas par cette clé). Ni
`lib/firebase_options.dart` ni `android/app/google-services.json` ne
sont trackés par Git (correctement ignorés) malgré leur présence sur
disque.

---

## 4. Résumé des scopes déjà couverts (pas de nouveau finding)

- Isolation stricte par `isOwner(userId)` : présente sur les 7
  collections (`users`, `clients`, `projects`, `workEntries`,
  `expenses`, `payments`, `client_settlements`) sans exception.
- `createdAtUnchanged()` vérifié sur tous les `update` qui en ont
  besoin.
- `ExpenseCategory.food` bien dans la whitelist (W-FIX1.1, toujours en
  place).
- Storage : deny-all réel par défaut, un seul chemin ouvert
  (`users/{userId}/attachments/**`), plafond 10 Mio serveur-side réel.

---

## 5. Vérification bidirectionnelle des enums ↔ whitelists rules

| Enum Dart (`enums.dart`) | Champ Firestore | Whitelist rules ? | Statut |
|---|---|---|---|
| `ClientType` (3) | `clients.type` | `['patron','client_particulier','entreprise']` | ✅ 3/3 exact, deux sens |
| `ProjectType` (6) | `projects.type` | **absente** | ❌ M4 — aucune contrainte |
| `ProjectStatus` (3) | `projects.status` | `['actif','termine','en_attente']` | ✅ 3/3 exact |
| `BillingMode` (4) | `workEntries.billingMode` | `['hourly','half_day','day','fixed_job']` | ✅ 4/4 exact |
| `ExpenseCategory` (4) | `expenses.category` | `['materials','travel','food','other']` | ✅ 4/4 exact |
| `MaterialCategory` (8) | `expenses.materialCategory` | **absente** | ❌ M4 — aucune contrainte |
| `TravelMode` (3) | `expenses.travelMode` / `workEntries` (dérivé) | **absente** | ❌ M4 — aucune contrainte |
| `PaymentMethod` (3) | `payments.method` | `['cash','virement','autre']` | ✅ 3/3 exact |
| `PaymentStatus` (4) | — (calculé, jamais stocké) | n/a | ✅ pas de gap, rien à valider |

Aucune valeur de whitelist ne référence une chaîne absente de
`enums.dart` (pas de "surface morte" côté rules). Le seul écart est
dans l'autre sens : trois enums entièrement dépourvus de whitelist
(§M4).

---

## 6. Écarts constatés entre CONTEXT.md et l'état réel du dépôt

CONTEXT.md est daté "post W-FIX1" (avant le commit `sprint-3`). Écarts
trouvés en auditant le code réel plutôt que le document :

1. **Collection `client_settlements` absente de CONTEXT.md.**
   Entièrement implémentée (`ClientSettlement` entity, repository,
   providers, règles Firestore dédiées) — ajoutée par le commit
   `fcfb531 feat(sprint-3): account settlement...`. À documenter dans
   une prochaine mise à jour de CONTEXT.md.
2. **`flutter analyze` : 46 info réels, pas 27.** CONTEXT.md (§9) fige
   le compte à 27 "post W-FIX1". Le sprint-3 a ajouté du code (pages
   `settle_account_dialog.dart`, modifications sur
   `client_form_page.dart`, `expense_detail_page.dart`, etc.) sans que
   le compte d'info ne soit remis à jour. Le delta n'est pas régressif
   en soi (aucun nouveau *warning*/*error*), mais le chiffre documenté
   est obsolète — pertinent pour R-SEC.4.
3. **`web/firebase-config.js` non documenté**, fichier mort (§L6),
   absent de la structure `lib/` décrite en CONTEXT.md §3 (normal,
   il est hors `lib/`, mais CONTEXT.md ne mentionne aucun fichier du
   dossier `web/` du tout).
4. **`test/widget_test.dart` a été supprimé** dans ce sprint (R-SEC.0
   bis) — CONTEXT.md §9 le mentionne encore comme "seul fichier de
   test" ; la section tests de CONTEXT.md est donc également à
   rafraîchir (259 tests désormais, 0 échec, couverture 100 % sur
   Money/WorkDuration/WorkCalculatorService, 98 % sur DateOnly).
5. **`test/core/`, `test/features/`** ne sont plus vides (CONTEXT.md
   §9 les décrit comme vides) — couverts par R-SEC.0.

---

## 7. Clôture du sprint (R-SEC.5, 2026-09-06)

### Ce qui est fait
- **M1** : corrigé et livré (code Dart, dans l'APK release).
- **M2, M3, M4, M5** : corrigés dans le repo, testés sur l'émulateur
  Firestore avant/après chaque fix. Déployés (voir §7bis, mise à jour
  F-SETTINGS.8).

### Ce qui reste ouvert
- **L1-L6, I1-I5** : non traités, hors périmètre de ce sprint (voir
  §2, §3).
- **I2** : App Check — enforcement confirmé actif pour Firestore le
  2026-09-07 (C-PORTAL.7, constaté par l'échec réel d'une écriture sur
  web, pas par la console — voir §3).
- **I3** : email enumeration protection — réglage Firebase Auth à
  vérifier côté console.
- **I4** : dépendances Firebase quelques versions mineures en retard —
  mise à jour de routine, pas urgente.

### Actions qui revenaient à William (faites depuis, voir §7bis)
1. ~~Déployer les rules~~ : fait avant le début du sprint F-SETTINGS.
2. ~~Vérifier/activer l'enforcement App Check en console (I2)~~ :
   confirmé actif le 2026-09-07 par l'échec réel d'une écriture web
   (C-PORTAL.7) — voir §3.
3. Vérifier le réglage "Email Enumeration Protection" en console (I3) —
   toujours ouvert.
4. Décider si L1-L6 méritent un futur sprint sécurité, ou restent
   acceptés en l'état — toujours ouvert.

## 7bis. Mise à jour post-clôture (sprint F-SETTINGS, 2026-09-07)

- **M2, M3, M4, M5 déployés sur `worklog-pro-2b3fb` et vérifiés sur
  appareil par William**, avant le début du sprint F-SETTINGS.
- **M5 étendu** (F-SETTINGS.8) : validation de type ajoutée pour le
  nouveau champ `settings.updatedAt`, déployée et vérifiée — voir le
  détail sous M5 (§1).
- **`users/{userId}/settings` est désormais une collection active** —
  câblée sur `SyncingSettingsRepository`, plus une collection vide
  protégée par des rules inutilisées (constat de clôture R-SEC.5,
  maintenant caduc). Voir `CONTEXT.md` §5 et
  `doc/F-SETTINGS_SPRINT_REPORT.md`.
- **L1-L6, I1-I5 toujours ouverts** — F-SETTINGS était un sprint de
  synchronisation cloud, pas un sprint sécurité ; aucun de ces findings
  n'était dans son périmètre.

## 7ter. Mise à jour post-clôture (sprint C-PORTAL, 2026-09-08)

- **CP1 déployé** sur `worklog-pro-2b3fb` et **vérifié sur appareil par
  William** — parcours réel complet (création de portail, connexion
  client → `ClientHomePage`, connexion artisan → `HomePage` intacte
  avec ses données). Résiduel documenté (§1bis) toujours ouvert, pas
  fermable par une rule seule (voir l'argument détaillé).
- **I2 confirmé actif** pour Firestore — pas par vérification console,
  mais par l'échec réel d'une écriture (`createPortal()`) pendant le
  test terrain du build web, App Check non contourné. Ce constat a lui
  même révélé une dette distincte, non liée à I2 : le web n'a aucune
  branche debug App Check (contrairement à Android,
  `AndroidProvider.debug`), documentée dans `CONTEXT.md` § Dette
  technique plutôt qu'ici — ce n'est pas un finding de sécurité, c'est
  un défaut d'ergonomie de développement qui a caché un vrai problème
  plus longtemps que nécessaire.
- **Nouveau résiduel non-sécurité, documenté dans `CONTEXT.md`** : le
  code qu'une rejection App Check produirait sur une **lecture**
  Firestore (par opposition à l'écriture déjà observée) n'a jamais été
  mesuré. `decideRoleRoute()` ne route vers artisan que sur un code
  réseau précis (`unavailable`/`deadline-exceeded`/`cancelled`) — si
  App Check rejetait un jour une lecture avec un code hors de cette
  liste, un artisan légitime sur web se verrait bloqué. Pas mesuré, pas
  corrigé, décision explicite de William de l'écrire plutôt que de le
  laisser flottant.
- **L1-L6, I1, I3-I5 toujours ouverts** — C-PORTAL était un sprint
  fonctionnel (portail client), pas un sprint sécurité généraliste ;
  seul CP1 (trouvé pendant ce sprint) et I2 (confirmé en cours de
  route) étaient dans son périmètre effectif.

Détail complet du sprint (les 7 étapes, la leçon sur la stratégie de
test) dans `doc/C-PORTAL_SPRINT_REPORT.md`.
