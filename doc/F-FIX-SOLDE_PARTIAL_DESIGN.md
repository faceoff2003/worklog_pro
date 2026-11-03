# F-FIX-SOLDE — Conception du solde partiel (étape 4)

> Décisions validées par William le 2026-11-03 (§10). **Implémenté** le 2026-11-03
> sur `feature/f-fix-solde-partiel` (étapes 5.0 à 5.7), non mergé, rule non
> déployée : voir le §8 de `doc/F-FIX-SOLDE_SPRINT_REPORT.md`.

## 1. Le besoin

Aujourd'hui, solder un compte remet le solde à 0 €, même s'il reste de l'argent
dû ou une avance. Le reste disparaît du solde courant et n'existe plus que dans
le champ d'archive `balanceAtSettlement`. Le solde partiel permet de clore la
période en reportant ce reste sur la suivante.

## 2. Modèle : `carriedOverAmount`

Nouveau champ de `client_settlements`.

| Propriété | Valeur |
|---|---|
| Type en base | int, en centimes |
| Signe | positif : le client doit ; négatif : avance du client |
| Absent ou `null` | 0, soit le comportement actuel |
| Dart | `@Default(Money.zero) Money carriedOverAmount` dans `ClientSettlement` |

- **Pas de migration** : les anciens documents restent immuables et valent 0.
- **Modèle Freezed persisté** : `build_runner` à relancer. La lecture d'un `null`
  explicite par le code généré est à vérifier par un test, pas à supposer.
- **Sens de `balanceAtSettlement` inchangé** : le solde au moment de la clôture.

## 3. Rule `client_settlements`

Ajout au `allow create` uniquement :

```
&& (!('carriedOverAmount' in request.resource.data)
    || request.resource.data.carriedOverAmount == null
    || request.resource.data.carriedOverAmount is int)
```

`allow update: if false` et `allow delete: if false` restent intacts (M2).

**Pourquoi cette rule compte vraiment** : le `create` actuel n'a pas de liste
blanche de clés, donc un `carriedOverAmount` de n'importe quel type passerait
aujourd'hui. Or `watchLastSettlement` renvoie `null` dès qu'un document ne se lit
pas (D3) : **un seul champ mal typé ferait passer le compte à "jamais soldé"**,
sans erreur et sans correction possible puisque le document est immuable.

**Tests rules attendus** : acceptés : absent, `null`, 0, positif, négatif.
Refusés : chaîne, décimal, booléen, et l'ajout du champ par `update`.

**Prérequis** : `firebase-tools` exige désormais Java 21 et la machine a le
JDK 17. L'émulateur ne démarre pas tant que ce n'est pas réglé.

## 4. `AccountStatementService`

- **Nouveau type de ligne** `StatementLineType.carryOver`, affiché « Report à
  nouveau ». Il n'est **jamais persisté**, donc sans contrainte de format.
- **Position** : première ligne de l'époque ouverte par le solde, quelle que soit
  sa date, avant toute prestation.
- **Solde courant** : l'époque démarre à X au lieu de 0. Aucune ligne si X = 0 :
  l'affichage des anciens comptes ne change pas.
- **Total** : `balance = report + totalWork + totalExpenses − totalPayments`.
  `AccountStatement` et `ClientBalance` exposent le report à part. Les totaux
  existants ne changent pas de sens.
- **FIFO** : un report positif est la dette la plus ancienne, les paiements le
  couvrent en premier. Un report négatif (avance) s'ajoute aux paiements
  disponibles.
- **Soldes non retenus** (égalité de date, D2) : leur report est ignoré. Voir le §8.

## 5. Impacts hors du service

Ce point dépasse la liste initiale, mais la fonctionnalité serait fausse sans lui.

**Rapports, PDF et Excel.** `ReportData.theoreticalBalance` ignore le report. Le
test posé à l'étape 2 (« Reste à percevoir » = solde du relevé) échouerait donc
dès le premier report, et une facture afficherait un reste faux. Proposition :

- `ReportData` (Freezed, non persisté) reçoit le report, **uniquement en mode
  « Depuis le dernier solde »** ; une période libre n'a pas de report défini ;
- ligne « Report à nouveau » dans les templates PDF et l'export Excel, si non nul ;
- **avec un filtre chantier** : pas de report, car il n'appartient à aucun chantier.
  Le reste à percevoir par chantier diffère alors légitimement du solde client.

**Dialog de solde et contrôleur** : `settle()` reçoit le report. Le texte actuel
(« repart de 0€ ») devient faux en cas de report (voir le §7).

## 6. C-PORTAL.10

`c1c11ef` ajoute `ClientPortal.lastSettlementCreatedAt` et l'écrit en best-effort.

1. **Le client a besoin du report** : avec le pivot seul, son espace ignorerait
   le reste à payer. Il faut un second champ, par exemple
   `lastSettlementCarriedOverAmount`, écrit **dans le même `update`** que le pivot.
   Deux écritures séparées pourraient donner un pivot neuf avec un report périmé.
2. **Ces deux champs doivent être immuables pour le client.** La branche
   `allow update: if isOwner(portalUid)` ne protège que les champs listés, et
   `c1c11ef` ne modifie pas `firestore.rules` : aujourd'hui, le client pourrait
   réécrire le pivot sur son propre document. L'effet reste limité à son affichage,
   mais c'est à fermer comme pour les compteurs `backfill*`.
3. **Le service n'est pas réutilisable tel quel côté client** : les paiements ne
   sont pas mirrorés dans `clientPortals`. Le client ne peut donc calculer ni son
   solde ni le FIFO. **Cela corrige ce que visait le brief F-RELEVE** (« réutilisé
   tel quel »). Options : mirrorer les paiements, ou mirrorer des résultats
   calculés. Décision à prendre avant C-PORTAL.10 étape 3, pas dans ce sprint.
4. **Échec du best-effort** : le portail garderait l'ancien pivot et l'ancien
   report. Limite déjà admise pour le pivot, elle porte désormais sur un montant.
5. **Montants du portail** : `ClientHomePage` affiche `laborAmountHT` seul, donc
   sans déplacement, ce qui ne colle plus au solde depuis l'étape 2.

## 7. Interface

Le dialog « Remettre le compte à zéro » propose, si le solde n'est pas nul :

- ( ) **Solder à zéro** : le reste est abandonné (comportement actuel) ;
- ( ) **Solder avec report de X €** : X est le solde exact, repris sur la période
  suivante. En cas d'avance : « Solder avec report de l'avance de X € ».

Solde nul : pas de choix. La note d'archivage indique ce qui se passera vraiment.
Le séparateur du relevé ajoute « Reporté : X € ».

## 8. Le document est immuable : une erreur ne se corrige pas

Un report erroné ne peut être ni modifié ni supprimé (M2). La seule correction
est un nouveau solde, le plus souvent le même jour, **ce qui tombe exactement sur
D2** : le « dernier » solde d'une même journée dépend de l'ordre des documents, le
correctif peut donc être ignoré et le mauvais report rester actif.

**D2 doit être corrigé avant ou avec le report** : à date égale, `createdAt` le
plus récent gagne, dans `watchLastSettlement` et dans le service. Ce changement
ne concerne que les comptes soldés deux fois le même jour.

## 9. Retour en arrière

**Un ancien APK ignore le champ** (le code généré ne lit pas les clés inconnues) :

- **Lecture** : le report n'est pas compté, le solde affiché est trop bas d'un
  montant X (ou trop haut s'il s'agit d'une avance), sans message. Réinstaller le
  nouvel APK rétablit le bon chiffre, car rien n'a été modifié en base.
- **Écriture : perte définitive.** Un solde enregistré depuis un ancien APK n'a
  pas de report, soit 0, et ce solde est immuable. **La dette reportée sort
  silencieusement du calcul**, sans autre correction qu'un nouveau report.
- **Rule** : elle n'a pas à être retirée, les anciens documents restent acceptés.

**Consigne proposée** : pas de retour à un ancien APK une fois un report créé ; si
c'est inévitable, aucune clôture de compte depuis cet APK. Tous les appareils
doivent être mis à jour avant le premier report.

**Ordre de déploiement** : tests à l'émulateur, déploiement des rules, puis APK,
puis premier report. L'inverse fonctionnerait techniquement, puisque le `create`
accepte déjà les champs inconnus, mais sans validation de type (§3).

## 10. Décisions — validées par William le 2026-11-03

| # | Question | Décision |
|---|---|---|
| 1 | Le montant reporté est-il modifiable ? | **Non, X = le solde exact.** Pour un paiement partiel : on saisit le paiement, puis on reporte le reste. |
| 2 | Choix présélectionné dans le dialog ? | **Aucun**, le bouton reste inactif tant qu'on n'a pas choisi. |
| 3 | Statut des prestations d'une période close avec report ? | **« Soldée »**, le report reste visible en ligne dédiée, sans répartition par prestation. |
| 4 | Corriger D2 dans ce sprint ? | **Oui, en premier** (§8). |
| 5 | Report dans les PDF, Excel et rapports inclus ? | **Oui, en étapes séparées** : service, puis relevé, puis PDF/Excel (§5). |
| 6 | Portail : mirrorer les paiements ou des résultats calculés ? | **Tranché dans C-PORTAL.10**, avec un penchant pour les résultats calculés. |

**Ajout au périmètre de l'étape 5, validé par William le 2026-11-03** : les cartes
de prestation et le graphique du CA incluent les déplacements.

## 11. Hors périmètre

Aucune reprise de l'existant : les anciens soldes restent à 0 de report, y compris
ceux enregistrés avec un reste dû.
