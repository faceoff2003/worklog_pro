# Rapport de sprint (partiel) — F-FIX-SOLDE, étapes 0 à 4

> Arrêté le 2026-11-02 à l'étape 4, comme prévu · Branche `feature/f-fix-solde`,
> créée depuis `feature/f-releve` · Aucun merge, aucune PR, aucun déploiement,
> aucune rule modifiée, aucune écriture en base, script d'audit non lancé en prod
> pendant le sprint (lancé ensuite par William, voir le §2bis).

---

## 1. Résumé en une phrase

Le solde client inclut désormais les déplacements et vaut exactement le « Reste à
percevoir » du PDF ; le relevé signale les lignes saisies en retard ; le solde
partiel est conçu et attend ta validation.

---

## 2. Ce qui a été fait, étape par étape

### Étape 0 — Sauvegarde
Tag `v2-f-releve` poussé, APK copié dans `backups/worklog_v2-f-releve.apk`.

### Étape 1 — Audit des déplacements
`scripts/list-open-travel-entries.mjs`, lecture seule, **à lancer par toi**. Il
reprend les règles du service : coupure `createdAt` stricte, microsecondes
conservées. Écart volontaire avec le script modèle : il ne garde que les chemins
`users/...`, car `workEntries` et `expenses` existent aussi sous `clientPortals/`
et seraient comptées deux fois.

**Validation partielle** : `--self-check` passe sur la logique de calcul, mais les
requêtes Firestore n'ont jamais été exécutées, l'émulateur exigeant Java 21 (la
machine a le JDK 17). Une erreur de lecture est donc possible au premier lancement.

**Lancé en prod par William le 2026-11-03** : voir le §2bis.

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
`doc/F-FIX-SOLDE_PARTIAL_DESIGN.md`. **Aucun code.**

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

1. **Les soldes affichés vont augmenter** pour tout client ayant une prestation
   ouverte avec déplacement. C'est l'objet du script d'audit. En prod, un seul
   solde change (Solamito, +19,20 €, voir le §2bis).
2. **Les soldes passés ne sont pas recalculés.** `balanceAtSettlement` reste une
   archive calculée sans déplacement. Dans une période close, le « Solde : X »
   courant inclut désormais les déplacements et peut donc dépasser le « Solde
   archivé » du séparateur.
3. **Les déplacements antérieurs au dernier solde restent considérés comme soldés.**
4. **Statuts** : une prestation dont seule la main-d'œuvre a été payée passe de
   « Payée » à « Partielle ».

---

## 5. Ce qui reste ouvert

**Écarts d'affichage laissés en l'état, hors de l'étape 2 :**

- `WorkEntriesListPage` et `ClientHomePage` (portail) affichent `laborAmountHT` seul :
  sur une carte de prestation, le montant peut être inférieur au « reste » du badge ;
- le graphique du CA sur 6 mois (`chart_providers`) ne compte que la main-d'œuvre ;
- le détail de `ReportsPage` n'a pas de ligne déplacements : ses lignes ne somment
  pas à « Total Production » quand il y en a ;
- la ligne « Prestations » de `ClientFormPage` inclut désormais les déplacements.

**Autres :**

- D2 et D3 restent ouverts. La conception recommande de corriger D2 avant le report.
- Les paiements ne sont pas mirrorés dans le portail, donc le service n'y est pas
  réutilisable tel quel. Voir le §6 de la conception.
- `c1c11ef` ne protège pas le pivot contre une réécriture par le client.
- **Java 21 est requis** pour les tests de rules de l'étape 5.

---

## 6. Prochaines étapes

1. ~~Lancer le script~~ : fait le 2026-11-03 (§2bis).
2. ~~Trancher le §10 de la conception~~ : fait le 2026-11-03.
3. Installer Java 21, puis lancer les étapes 5 et suivantes.

---

## 7. Commits

```
fd519ff chore(scripts): add read-only audit of open travel entries per client
66ce0b2 fix(clients): include travel amount in client balance and statement
5a22b5c feat(clients): show entry date on statement lines entered late
```

(+ 1 commit de clôture avec la conception, ce rapport et la resynchronisation
de `CONTEXT.md` et du plan F-RELEVE.)
