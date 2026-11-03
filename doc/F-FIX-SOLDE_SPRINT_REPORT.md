# Rapport de sprint — F-FIX-SOLDE, étapes 0 à 5.7

> **Étapes 0 à 4** : arrêtées le 2026-11-02 comme prévu, branche
> `feature/f-fix-solde`, mergées dans `main` par la PR #7 le 2026-11-03 (tag
> `v3-f-releve-merge`), après l'audit en prod et le test sur appareil (§2bis).
> **Étapes 5.0 à 5.7** (solde partiel, §8) : 2026-11-03, branche
> `feature/f-fix-solde-partiel` poussée, **ni PR, ni merge, ni déploiement** ;
> la rule modifiée n'est **pas déployée**.

---

## 1. Résumé en une phrase

Le solde client inclut désormais les déplacements et vaut exactement le « Reste à
percevoir » du PDF ; le relevé signale les lignes saisies en retard ; le solde
partiel (report à nouveau) est implémenté, testé à l'émulateur, pas encore déployé
ni testé sur appareil (§8).

---

## 2. Ce qui a été fait, étape par étape

### Étape 0 — Sauvegarde
Tag `v2-f-releve` poussé, APK copié dans `backups/worklog_v2-f-releve.apk`.

### Étape 1 — Audit des déplacements
`scripts/list-open-travel-entries.mjs`, lecture seule, lancé par William. Il
reprend les règles du service : coupure `createdAt` stricte, microsecondes
conservées. Écart volontaire avec le script modèle : il ne garde que les chemins
`users/...`, car `workEntries` et `expenses` existent aussi sous `clientPortals/`
et seraient comptées deux fois.

**Pendant le sprint**, seul `--self-check` a été exécuté, sur la logique de calcul :
l'émulateur exige Java 21 (la machine a le JDK 17). **Lancé en prod par William le
2026-11-03**, sans erreur de lecture : voir le §2bis.

### Étape 2 — Déplacements dans le solde
Vérifié dans le code : `ReportData.theoreticalBalance` = main-d'œuvre + déplacements
+ dépenses facturables − paiements, repris par les PDF et Excel. Le service s'aligne
dessus. Les libellés « Total M.O. + dépenses » de `ClientDetailPage` et du dialog
de solde mentionnent maintenant les déplacements.

**Tests de caractérisation remplacés** (changement voulu, seuls ces deux-là ont
changé, annoncés dans le commit `66ce0b2`) :

| Fichier | Ancien test | Attendait | Nouveau test | Attend |
|---|---|---|---|---|
| `client_balance_providers_test` | `D1 : travelAmountHT ignoré par le solde` | 10000 | `travelAmountHT inclus dans le solde, comme dans le PDF` | 11234 |
| `account_statement_service_test` | `déplacement exclu, comme clientBalanceProvider` | 10000 | `déplacement inclus dans la ligne, le solde courant et le total` | 11234 |

**Nouveaux** : `balance_matches_report_test` prouve l'égalité au centime entre
« Reste à percevoir », solde du relevé et solde du compte, avec et sans solde
antérieur. **L'égalité vaut en mode « Depuis le dernier solde » sans filtre chantier** :
une période libre porte par nature sur un autre périmètre.

### Étape 3 — Mention « saisie le JJ/MM »
`StatementLine.enteredOn`, calculé par le service et seulement affiché par la page.
Renseigné si la date de la ligne est antérieure à celle du solde qui la précède,
pour tous les types de ligne et aussi dans les périodes closes. Affichage seul.

### Étape 4 — Conception du solde partiel
`doc/F-FIX-SOLDE_PARTIAL_DESIGN.md`. **Aucun code.** Décisions du §10 validées par
William le 2026-11-03.

---

## 2bis. Résultats après le sprint (2026-11-03)

**Audit en prod**, lancé par William : 3 clients scannés, aucune anomalie. Un seul
solde change : Solamito, +19,20 €, pour 2 déplacements dont la facturation à part
est confirmée.

**Test sur appareil** avec l'APK `74d8783` : relevé, séparateur, badges et
paiement OK, pas de crash.

---

## 3. Chiffres

| | Avant | Après |
|---|---|---|
| `flutter test` | 490 | 500, tous verts |
| `flutter analyze` | 12 info | 0 erreur, 0 warning, 12 info |
| Couverture `account_statement_service` | 86/86 | 87/87 lignes |

Pas de build pendant les étapes 0 à 4. L'APK de test
`backups/worklog_f-fix-solde-74d8783.apk`, construit ensuite, contient le correctif.

---

## 4. Conséquences du correctif à connaître

1. **Les soldes affichés augmentent** pour tout client ayant une prestation
   ouverte avec déplacement. En prod, d'après l'audit, un seul solde change
   (Solamito, +19,20 €, voir le §2bis).
2. **Les soldes passés ne sont pas recalculés.** `balanceAtSettlement` reste une
   archive calculée sans déplacement. Dans une période close, le « Solde : X »
   courant inclut désormais les déplacements et peut donc dépasser le « Solde
   archivé » du séparateur.
3. **Les déplacements antérieurs au dernier solde restent considérés comme soldés.**
4. **Statuts** : une prestation dont seule la main-d'œuvre a été payée passe de
   « Payée » à « Partielle ».

---

## 5. Ce qui reste ouvert

**Écarts d'affichage :**

- ~~`WorkEntriesListPage` affiche `laborAmountHT` seul~~ : corrigé en 5.6.
  `ClientHomePage` (portail) affiche toujours la main-d'œuvre seule, à traiter en
  C-PORTAL.10 ;
- ~~le graphique du CA sur 6 mois ne compte que la main-d'œuvre~~ : corrigé en 5.6 ;
- le détail de `ReportsPage` n'a pas de ligne déplacements : ses lignes ne somment
  pas à « Total Production » quand il y en a ;
- la ligne « Prestations » de `ClientFormPage` inclut désormais les déplacements.

**Autres :**

- ~~D2~~ : corrigé en 5.1. **D3 reste ouvert.**
- Les paiements ne sont pas mirrorés dans le portail, donc le service n'y est pas
  réutilisable tel quel. Décision reportée à C-PORTAL.10, avec un penchant pour des
  résultats calculés (§6 et §10 de la conception).
- `c1c11ef` ne protège pas le pivot contre une réécriture par le client : finding
  **CP2** de `SECURITY_AUDIT.md` (Low, ouvert, à corriger en C-PORTAL.10).

---

## 6. Prochaines étapes

1. ~~Lancer le script~~ : fait le 2026-11-03 (§2bis).
2. ~~Trancher le §10 de la conception~~ : fait le 2026-11-03.
3. ~~Installer Java 21, puis lancer les étapes 5 et suivantes~~ : fait le
   2026-11-03 (§8).
4. Déployer la rule, installer l'APK et tester sur appareil : liste ordonnée au §8.6.

---

## 7. Commits

```
fd519ff chore(scripts): add read-only audit of open travel entries per client
66ce0b2 fix(clients): include travel amount in client balance and statement
5a22b5c feat(clients): show entry date on statement lines entered late
```

Clôture et suivi documentaire :

```
74d8783 docs(f-fix-solde): add partial settlement design and partial sprint report
7e8bd85 docs(security): add CP2, portal settlement pivot writable by client
ab38134 docs(f-fix-solde): record validated partial settlement decisions
6fc97c2 docs(f-fix-solde): record production audit and device test results
1a66a2f docs(f-fix-solde): mark partial settlement decisions as done in sprint report
```

(+ le commit qui resynchronise ce rapport.)

---

## 8. Étapes 5.0 à 5.7 — solde partiel (2026-11-03)

Référence : `doc/F-FIX-SOLDE_PARTIAL_DESIGN.md`, décisions du §10.

### 8.1 Ce qui a été fait

| Étape | Contenu | Commit |
|---|---|---|
| 5.0 | Tag `v3-f-releve-merge`, APK `backups/worklog_v3-main-pr7.apk`, branche, `CONTEXT.md` | `65b58c5` |
| 5.1 | **D2** : à date égale, `createdAt` le plus récent gagne, puis `id`. Un seul comparateur (`AccountStatementService.latestFirst`) pour `watchLastSettlement`, `watchAllSettlements` et le service | `c9b98bc` |
| 5.2 | `ClientSettlement.carriedOverAmount` (`@Default(Money.zero)`), rule `create` typée | `333a45d`, `3e14df5` |
| 5.3 | Service : ligne `carryOver`, FIFO avec report positif et négatif, `carriedOver` exposé par `AccountStatement` et `ClientBalance` | `615ce0c` |
| 5.4 | Dialog à choix obligatoire, « Reporté : X € » au séparateur, ligne de report sur les cartes Compte | `ab11db2` |
| 5.5 | `ReportData.carriedOverAmount`, ligne « Report à nouveau » dans le PDF facture, le PDF simple, l'Excel et le détail des rapports | `9294e34` |
| 5.6 | Déplacements dans les cartes de `WorkEntriesListPage` et le graphique du CA | `465f7d3` |

**Choix d'implémentation à connaître :**

- `SettlementsController.settle` reçoit un booléen `carryOver`, pas un montant : le
  report ne peut valoir que le solde exact (décision 1), même appelé d'ailleurs.
- **Tout nouveau solde écrit désormais `carriedOverAmount`**, à 0 pour « Solder à
  zéro ». La rule actuellement déployée accepte déjà ce champ (pas de liste blanche).
- Le report n'apparaît dans les rapports qu'en mode « Depuis le dernier solde » sans
  filtre chantier. Ailleurs, « Reste à percevoir » ne le contient pas, par conception.
- Le devis PDF n'a pas de reste à payer : inchangé.
- Le portail client ignore le report (C-PORTAL.10).

### 8.2 Tests de caractérisation modifiés

Un seul, annoncé au §8 de la conception (commit `c9b98bc`) :

| Ancien test | Attendait | Nouveau test | Attend |
|---|---|---|---|
| `D2 : deux soldes le même jour, le premier en entrée est retenu même s'il est plus ancien` | solde retenu `first`, solde 300 | `D2 corrigé : deux soldes le même jour, le plus récent en createdAt est retenu` | `second`, 200 |

Un test `enteredOn` renommé (« solde non retenu (égalité de date) » devient « deux
soldes le même jour »), assertions inchangées. Aucun autre test existant n'a changé.

### 8.3 Chiffres

| | Début (5.0) | Fin (5.7) |
|---|---|---|
| `flutter test` | 500 | 536, tous verts |
| `flutter analyze` | 0 erreur, 0 warning, 12 info | identique |
| Suite rules (émulateur, Java 21) | 154 | 165, tous verts |
| Couverture `account_statement_service` | 87/87 | 103/103 lignes |

- **Rules** : contre l'ancienne rule, exactement les 3 cas mal typés (chaîne,
  décimal, booléen) passaient. Contre la nouvelle, les 165 tests passent.
- **Mutations** : 4 altérations du FIFO et du total, toutes détectées. Les tests des
  cartes et du graphique échouent sur l'ancien code.
- **Non couvert automatiquement** : le rendu des lignes « Report à nouveau » dans les
  deux PDF. Seul l'Excel est relu par un test.
- **APK** : `backups/worklog_f-fix-solde-partiel.apk` (git-ignoré).

### 8.4 Conséquences à connaître

1. **D2 peut changer un solde affiché** : pour un client soldé deux fois le même
   jour, c'est désormais le dernier saisi qui compte. L'audit du 2026-11-03 ne
   vérifiait pas ce cas.
2. **Les cartes de prestation et le graphique du CA augmentent** du montant des
   déplacements.
3. **Un report est définitif** (M2) : la seule correction est un nouveau solde, qui
   grâce à D2 l'emporte même le même jour.
4. **Retour à un ancien APK après un premier report** : le report est ignoré à la
   lecture, et un solde enregistré depuis cet APK l'abandonne définitivement
   (conception §9).

### 8.5 Reste ouvert

- D3 (document de solde illisible : compte « jamais soldé »).
- Portail : report, déplacements, CP2, choix du mirroring (C-PORTAL.10).
- Le détail de `ReportsPage` n'a toujours pas de ligne déplacements.

### 8.6 Ce que William doit faire, dans l'ordre

1. **Déployer la rule**, depuis la racine du dépôt, sur `feature/f-fix-solde-partiel` :
   `firebase deploy --only firestore:rules`
2. **Vérifier le déploiement** : dans la console Firebase (Firestore > Règles), le
   bloc `client_settlements` contient la clause `carriedOverAmount`, avec l'heure de
   publication du jour.
3. **Mettre à jour tous les appareils** avec `backups/worklog_f-fix-solde-partiel.apk`
   **avant le premier report**, et ne plus réinstaller d'APK antérieur ensuite.
4. **Tester sur appareil**, de préférence sur un client de test :
   1. relevé et carte Compte d'un client existant : mêmes montants qu'avant, sauf
      déplacements sur les cartes de prestation et le graphique du CA ;
   2. dialog avec solde dû : aucun choix coché, bouton « Confirmer » grisé ; choisir
      « Solder avec report de X € » et confirmer ;
   3. relevé : « Reporté : X € » au séparateur, ligne « Report à nouveau » en tête,
      solde actuel = X ; carte Compte : ligne « Report du solde précédent » ;
   4. ajouter une prestation puis un paiement inférieur à X : la prestation reste
      « Impayée » (le paiement couvre d'abord le report) ;
   5. rapports, client choisi, « Depuis le dernier solde », sans chantier : ligne
      « Report à nouveau » ; reste à percevoir = solde du relevé ; exporter le PDF
      facture, le PDF simple et l'Excel, et y retrouver la ligne ;
   6. même rapport avec un chantier : pas de report ;
   7. avance : solder un client qui a trop payé avec « report de l'avance » ; le
      solde repart négatif ;
   8. solde nul : pas de choix, bouton actif ;
   9. « Solder à zéro » sur un solde dû : comportement d'avant, solde à 0 €.

Branche à merger ensuite par PR, après ces vérifications.
