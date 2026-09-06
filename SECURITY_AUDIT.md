# SECURITY_AUDIT.md — worklog_pro

> Sprint R-SEC.1 — audit lecture seule. Aucun fichier modifié à part celui-ci.
> Audité sur le code réel (`firestore.rules`, `storage.rules`, `lib/`, historique
> Git complet), le 2026-09-06. CONTEXT.md utilisé comme piste de départ
> uniquement — voir §7 pour les écarts constatés avec l'état réel du repo.

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

**Statut (2026-09-06)** : fix appliqué (validation de type par champ
connu + plafonds, voir commit `f2bb600`). **Mais l'audit prod a
trouvé 0 document dans `users/{userId}/settings`** — pas une base
vide par accident : `SettingsRepository`
(`lib/features/settings/data/repositories/settings_repository.dart:6-25`)
persiste `Settings` exclusivement via `SharedPreferences` (clé
`app_settings`, JSON local). Aucun code de l'app n'écrit jamais sur
`users/{userId}/settings` — la rule (et son fix M5) protège une
collection Firestore qui n'a jamais reçu un seul document en
production.

**Décision (William, 2026-09-06)** : on garde les rules M5 en l'état
(elles ne coûtent rien tant que la collection reste vide, et seront
immédiatement utiles le jour où `SettingsRepository` sera câblé sur
Firestore) mais on ne câble pas Firestore maintenant. Conséquence
produit documentée dans `CONTEXT.md` (réglages perdus au changement
d'appareil) et suivi de la dette dans `CONTEXT.md` § Dette (sprint
`F-SETTINGS` à planifier, hors périmètre R-SEC).

---

## 2. Low

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

## 7. Prochaine étape

Aucun fix appliqué dans cette phase. En attente de ta sélection des
findings à corriger avant R-SEC.2 (tests emulator d'abord, puis fix,
règle du skill firebase-security-audit).
