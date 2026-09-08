# Rapport de fin de sprint — C-PORTAL

> Clôturé le 2026-09-08 · Branche `feature/c-portal` · 19 commits
> Rules déployées par William pendant le sprint (bloc `clientPortals`,
> avec la garde CP1) — jamais par moi, comme convenu.

---

## 1. Résumé en une phrase

Un client peut désormais recevoir un accès portail créé par son
artisan (compte provisionné, email d'accès, jamais de mot de passe
transmis par l'artisan) et se connecter dans la même app pour atterrir
sur un espace séparé et minimal — et trois bugs réels, tous à la
frontière entre le code et Firebase réel, ont été trouvés par des
parcours sur appareil, jamais par la suite automatisée.

---

## 2. Ce qui a été fait, étape par étape

### C-PORTAL.1 — Conception (aucun code)
Décisions non négociables actées avant la moindre ligne : espace
miroir complet, séparé de l'espace artisan ("ce qu'il ne doit pas voir
n'existe pas chez lui") ; une seule app, deux rôles, routés après
connexion ; client lecture seule sauf commentaires/réservations/ses
propres réglages ; disponibilité = créneaux manuels + blocage
automatique par les prestations existantes.

### C-PORTAL.2-3 — Rules `clientPortals` (profil, miroir, commentaires)
Écrites et testées avant tout code Dart. Deux corrections faites en
cours de route après vérification empirique contre l'émulateur, jamais
supposées :
- Une règle `list` qui référence `resource.data` ne peut pas filtrer
  document par document (Firestore exige une preuve sur tout le
  résultat potentiel) ; une règle `list` qui n'utilise que `get()` est
  évaluée une seule fois par requête, pas une fois par document. Un
  premier design avec un champ `portalEnabled` dénormalisé a été
  construit puis **entièrement retiré** après avoir découvert
  l'inverse de l'hypothèse de départ sur le coût réel.
- **CP1** (Medium, SECURITY_AUDIT.md) : `allow create` ne vérifiait pas
  quel `portalUid` pouvait être revendiqué — un client portail pouvait
  planter le profil d'un artisan et écrire dans son miroir. Trouvé via
  deux tests empiriques demandés explicitement avant d'être supposé,
  corrigé par `!exists(clientPortals/{request.auth.uid})`, résiduel
  documenté (pas fermable par une rule seule sans Admin SDK).

### C-PORTAL.4 — Entités et miroir depuis les repositories artisan
`ClientPortal` (entité), `ClientPortalRepository` (côté artisan),
`ClientPortalMirrorService` — écrit le miroir après chaque
création/modification/suppression de prestation ou dépense
refacturable, en best-effort (un échec d'ajout reste silencieux, un
échec de retrait est loggé — un retrait raté laisse une donnée exposée
côté client, un ajout raté ne fait que retarder une mise à jour).

### C-PORTAL.5 — Provisioning du compte client
Séquence à 4 étapes (compte Auth via une app Firebase secondaire
jetable, profil `clientPortals`, lien `Client.portalUid`, email
d'accès), compensée uniquement à l'étape 1 en cas d'échec de l'étape 2.
Mot de passe généré en interne (`Random.secure()`, aucun seam
injectable), jamais transmis par l'artisan — le client le définit via
un email de réinitialisation. Vérifié empiriquement sur AVD réel : le
pattern app-secondaire ne fait fuiter aucun événement vers la session
artisan (`authStateChanges()` vide pendant la création), et `dispose()`
libère bien chaque app secondaire (deux créations consécutives dans la
même session réussissent toutes les deux).

### C-PORTAL.6 — Écran de création côté artisan
Dialog sur `ClientDetailPage`, un retour distinct pour chacune des 8
issues du service (jamais un SnackBar générique), les deux cas
orphelins en dialog persistant avec email/uid copiables, garde
anti-double-tap sur la création et le renvoi d'email. Un code d'erreur
technique brut a été ajouté après coup sur les issues génériques, à la
demande explicite de William en plein débogage terrain — deux causes
différentes ne doivent jamais produire le même message.

### C-PORTAL.7 — Routage par rôle
`PostAuthRoleRouter`, seul point de décision de rôle de toute l'app,
branché dans `AuthWrapper` en une ligne. Écrans minimaux
(`ClientHomePage`, `ClientDisabledPage`, `RoleCheckBlockedPage`). Deux
bugs réels trouvés et corrigés en cours de route (détail en §5, "Ce qui
a été trouvé par le terrain").

---

## 3. Ce qui a été trouvé par le terrain, pas par la suite de tests

Trois bugs réels ce sprint, et un constat qui dépasse ce sprint :

1. **Rules jamais déployées.** Le bloc `clientPortals` complet, testé
   149/149 sur l'émulateur depuis plusieurs étapes, n'avait jamais été
   poussé sur `worklog-pro-2b3fb` — la base ne contenait que la version
   pré-C-PORTAL. Trouvé en confirmant l'hypothèse la plus simple avant
   d'en chercher une plus compliquée, à la demande de William.
2. **`createdAt` en `Timestamp`, pas en `String`.** `createPortal()`
   écrivait un `DateTime` Dart brut dans un `Map` à la main — converti
   en `Timestamp` Firestore par le SDK, illisible par
   `ClientPortal.fromJson()` (qui attend une String ISO8601, comme
   `Client`/`WorkEntry`/tout le reste du repo). Le `TypeError` résultant
   était absorbé par la règle de routage et faisait atterrir
   silencieusement un compte client sur l'espace artisan — trouvé en
   se connectant avec un vrai compte client sur un vrai build web.
3. **La règle de routage elle-même était trop large.** Le bug n°2 a
   révélé que "tout sauf `permission-denied` → artisan" masquait aussi
   les erreurs de CODE, pas seulement les pannes réseau visées. Révisée
   en "seules les erreurs réseau identifiées → artisan, tout le reste
   bloque" — un bug de code doit être visible, jamais masqué par un
   filet de secours conçu pour autre chose.

**Constat sur la stratégie de test, pas une anecdote** : ces trois bugs
— et le bug F-SETTINGS du sprint précédent (`updatedAt` gelé après le
premier stamp cloud) — partagent tous la même caractéristique : ils se
situent exactement à la frontière entre le code et le comportement
réel de Firebase (déploiement effectif d'une règle, conversion de type
réelle par le SDK Firestore, comportement réseau réel d'un appareil).
Cette frontière est structurellement invisible aux fakes — un fake
simule le contrat qu'on *croit* correct, jamais le comportement réel du
service qu'il remplace. Plus de 400 tests unitaires/widgets et 149
tests de rules n'ont trouvé aucun de ces quatre bugs ; un parcours réel
sur appareil ou navigateur les a tous trouvés, chaque fois. Ce n'est
pas un argument contre les tests unitaires (ils ont, par ailleurs,
prouvé exactement ce qu'ils devaient prouver ce sprint : séquencement,
compensation, non-fuite du mot de passe, isolation de rôle) — c'est un
argument pour ne jamais fermer un sprint touchant Firebase sans un
parcours réel, quelle que soit la couverture automatisée par ailleurs.

---

## 4. Chiffres finaux

| Mesure | Avant sprint | Après sprint |
|---|---|---|
| Tests automatisés (`flutter test`) | 325 | **401**, tous verts |
| Tests rules Firestore (émulateur, `firestore-tests/`) | 98 | **149** (+51, bloc `clientPortals` complet + CP1) |
| Tests intégration (émulateur + AVD réel, `integration_test/`) | 8 | **13** (+5 : provisioning secondaire, round-trip `createPortal`/`getPortal`) |
| `flutter analyze` | 12 info | **12 info** (inchangé) |
| Collection `clientPortals` | inexistante | **active**, rules déployées et vérifiées sur appareil |
| Findings sécurité (SECURITY_AUDIT.md) | 0 lié au portail | **CP1** (Medium, fix déployé, résiduel documenté) + **I2 confirmé** actif (App Check) |
| Build APK release | — | ✅ réussi |

---

## 5. Documents mis à jour

- **`CONTEXT.md`** — §5 (nouvelle collection `clientPortals` +
  sous-collections), §6 (nouveaux écrans, routage `AuthWrapper`), §7
  (`PostAuthRoleRouter`), §9 (fixes du sprint + dette : résiduel du
  routage réseau, App Check web sans branche debug — préexistante mais
  découverte ce sprint), §10 (rules déployées, I2 confirmé), §12
  (chiffres, prochaines étapes).
- **`SECURITY_AUDIT.md`** — CP1 passé de "corrigé, non déployé" à
  "déployé et vérifié" ; I2 passé de "à confirmer" à "confirmé, par
  l'échec plutôt que la console" ; nouvelle section 7ter de clôture.
- **`doc/C-PORTAL_SPRINT_REPORT.md`** — ce document.

---

## 6. Ce qui reste ouvert

- **Vraie liste de prestations dans `ClientHomePage`** (depuis le
  miroir `clientPortals/{monUid}/workEntries`) : périmètre et preuve
  d'isolation entre deux clients déjà discutés avec William, pas encore
  codé — étape séparée à venir.
- **Dépenses côté client** : explicitement reportée à une étape encore
  ultérieure (décision R04, "une étape = une chose").
- **CP1, résiduel** (SECURITY_AUDIT.md §1bis) : un compte qui n'est pas
  déjà client portail (un autre artisan, ou un compte tout juste créé)
  connaissant l'uid exact d'une cible peut toujours planter son profil.
  Non fermable par une rule seule sans un signal de rôle côté serveur
  (Admin SDK, hors périmètre).
- **App Check web sans branche debug** (dette préexistante, découverte
  ce sprint) : le web utilise systématiquement la vraie clé ReCAPTCHA,
  même en dev, contrairement à Android (`AndroidProvider.debug`).
  Bloque toute écriture Firestore depuis un build web local tant que ce
  n'est pas corrigé. Fix proposé, non appliqué (touche à la sécurité,
  décision de William).
- **Code qu'une rejection App Check produit sur une lecture** : jamais
  mesuré (seule une écriture a été observée en échec). Si ce code
  tombait un jour hors de la liste réseau de `decideRoleRoute()`, un
  artisan légitime sur web se verrait bloqué à tort — résiduel non
  quantifié, écrit explicitement plutôt que laissé flottant.
- **Effet de bord accepté du routage réseau → artisan** : un client
  hors ligne (ou en erreur réseau) atterrit sur `HomePage` et pourrait
  y créer des documents sous `users/{son_propre_uid}/...` — n'ouvre
  aucun trou de sécurité (scopé par `isOwner`), mais laisse des
  documents orphelins si un rôle artisan réel était attribué à ce uid
  plus tard.
- **Findings L1-L6, I1, I3-I5** (`SECURITY_AUDIT.md`) : toujours
  ouverts, hors périmètre de ce sprint fonctionnel.
- **Couverture de tests** : le portail client est désormais couvert
  (service, provider de rôle, routage, rules), mais les repositories
  artisan restants et la plupart des pages historiques restent à 0%.

---

## 7. Actions qui reviennent à William

1. **Décider du sort de la vraie liste de prestations côté client**
   (périmètre déjà validé) — prochaine étape à lancer ou reporter.
2. **Corriger la branche debug App Check pour le web**, ou accepter le
   résiduel — décision de sécurité, pas la mienne.
3. **Nettoyer manuellement** les éventuels documents `clientPortals`
   restants avec `createdAt` en `Timestamp` créés avant le fix
   (marche à suivre déjà donnée : document → compte Auth → champ
   `Client.portalUid`, dans cet ordre).
4. **Décider du sort de L1-L6 et I1, I3-I5** (`SECURITY_AUDIT.md`) — un
   futur sprint sécurité, ou acceptés en l'état.
5. **Merge de la PR** : pas de PR ouverte sans confirmation explicite,
   comme convenu tout le long de ce sprint.

---

## 8. Commits du sprint (19)

Du plus ancien au plus récent, sur `feature/c-portal` :

```
a57119c feat(security): add clientPortals rules for C-PORTAL (profile, workEntries mirror, comments)
35e7841 fix(security): drop portalEnabled denormalization, use get()-only list rule
5fab3c1 feat(client-portal): add ClientPortal entity + best-effort mirroring from workEntries/expenses
eaff927 fix(client-portal): log removal failures, keep add failures silent
48304cd feat(security): add artisan-scoped list() on clientPortals, separated from get()
622572c fix(security): block create when caller already has a portal (CP1)
e97340d feat(client-portal): add reconciliation sweep for missing/conflicting Client.portalUid
d7f880c fix(client-portal): never cache a failed reconciliation attempt
a02e0cc feat(client-portal): add account provisioning sequence (C-PORTAL.5, sequencing only)
df893c5 feat(client-portal): add real Firebase-backed PortalAccountProvisioner
86890de feat(client-portal): generate password internally, send invite email, never transmit via artisan
d1dc8fc docs(client-portal): add missing I3 doc comment on resendInvite
82fde73 feat(client-portal): create-portal screen on ClientDetailPage (C-PORTAL.6)
7502587 test(rules): prove get() on an artisan's own nonexistent portalUid succeeds
5937daa docs(security): confirm App Check enforcement (I2), log web debt found in C-PORTAL.7
72b914a feat(client-portal): surface raw technical error code on generic failures
520c638 feat(client-portal): role-decision provider for C-PORTAL.7 (routing next)
98d5da1 feat(client-portal): wire role routing into AuthWrapper (C-PORTAL.7)
aa948d4 fix(client-portal): write createPortal() via toJson(), not a raw Map
9b43662 fix(client-portal): only network errors route to artisan, not every error
```

(+ commits de clôture : resync `CONTEXT.md`/`SECURITY_AUDIT.md` et ce
rapport — voir l'historique pour leurs hashes exacts, ajoutés après la
rédaction de cette liste.)
