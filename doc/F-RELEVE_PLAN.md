# F-RELEVE — Constats d'exploration (étape 1)

> Lecture seule du code au tag `v1-avant-releve` (`f60bbca`).

## 1. Où le solde est calculé

Un seul endroit : `clientBalanceProvider`
(`lib/features/clients/presentation/providers/client_balance_providers.dart`),
consommé par `ClientDetailPage`, `ClientFormPage` et `settle_account_dialog`.

```
solde = Σ laborAmountHT + Σ amountHT (isBillable) − Σ amount (paiements)
```

## 2. Règle de coupure : `createdAt`, PAS `date`

Le fix "balance cutoff" (sprint-3, `fcfb531`) a remplacé la coupure par date
par une coupure sur l'instant de saisie :

```dart
final cutoffTime = lastSettlement?.createdAt;
.where((e) => e.createdAt.isAfter(cutoffTime))   // strict
```

Conséquences (toutes conservées par ce sprint) :

- `client_settlements.date` n'a **aucun effet** sur le calcul du montant. Elle
  sert à choisir le "dernier" solde et à l'affichage.
- **Prestation datée le jour même d'un solde : c'est son `createdAt` qui
  décide.** Saisie après le solde → compte dans le solde courant. Saisie avant
  → archivée. `createdAt` égal à la milliseconde → archivée (`isAfter` strict).
- Une ligne saisie après le solde compte **quelle que soit sa date métier**,
  même antérieure au solde (paiement antérieur saisi en retard). Inversement,
  une ligne datée dans le futur mais saisie avant le solde reste archivée.
- La modification d'une prestation préserve `createdAt` : elle ne change pas
  de côté.

La documentation est périmée : le docstring de `ClientBalance`,
`ClientSettlement.date` et CONTEXT.md §5 parlent encore d'entrées "postérieures
à la date". Le code fait foi.

## 3. Choix du "dernier" solde

`SettlementRepositoryImpl.watchLastSettlement` trie par `date` décroissante et
prend le premier. `date` vaut `DateOnly.today()`, donc **deux soldes le même
jour sont à égalité** : le gagnant dépend de l'ordre des documents Firestore
(UUID, donc arbitraire), pas de l'ordre de création. Voir §7, D2.

## 4. `PaymentStatus`

`lib/core/constants/enums.dart` : déclaré "calculated, not stored", mais **aucun
code ne le calcule ni ne le lit**. Ses valeurs (`a_facturer`, `facture`, ...)
ne correspondent pas aux statuts demandés (pas de notion de facture dans le
relevé). Il n'est donc pas réutilisé ; un enum dédié non persisté est ajouté.

## 5. Dépenses

Seules les dépenses `isBillable == true` entrent dans le solde, et le filtre
`createdAt` s'applique comme aux autres lignes.

## 6. Conception du service

**Époques plutôt que tri global par date.** Comme la coupure est sur
`createdAt`, un tri purement par date placerait une ligne saisie en retard
avant le séparateur alors qu'elle compte dans le solde courant : le dernier
solde courant affiché serait faux. Donc :

1. les lignes sont réparties entre époques selon `createdAt` et les soldes ;
2. chaque époque est triée par date, le solde courant repart de 0 ;
3. le solde qui ferme l'époque vient en dernier.

Conséquence visible et assumée : une ligne saisie en retard apparaît après le
séparateur, avec une date antérieure à celui-ci.

**Ordre à date égale** (total, indépendant de l'ordre d'entrée) : prestation,
dépense, paiement, puis `createdAt`, puis `id`.

**FIFO** : le total des paiements de l'époque courante couvre les prestations
de cette époque, de la plus ancienne à la plus récente, sans regarder la date
du paiement (un acompte couvre une prestation ultérieure). Les dépenses ne
consomment pas de paiement : une prestation peut être "payée" alors que le
solde reste positif à cause d'une dépense. Les prestations des époques closes
sont "soldées", même si le solde a été enregistré avec un reste dû.

## 7. Défauts constatés, NON corrigés (hors périmètre, décision de William)

| # | Constat | Effet |
|---|---|---|
| D1 | Le solde ignore `travelAmountHT`, alors que `ReportData.totalProduction` l'inclut | Pour une prestation avec déplacement, le solde client est inférieur au "Reste à percevoir" des rapports et de la facture |
| D2 | Deux soldes le même jour : "dernier" arbitraire (§3) | Le second solde du jour peut être ignoré ; le solde courant affiché est alors faux |
| D3 | `watchLastSettlement` renvoie `null` si **un** document est illisible, `watchAllSettlements` l'ignore seulement | Un document corrompu remet le solde à "jamais soldé" sans erreur, et le relevé (qui lit tous les soldes) peut alors différer de la carte Compte |

Le service reproduit D1 et D2 à l'identique (condition d'arrêt du sprint).

**Mise à jour F-FIX-SOLDE.2 (2026-11-02)** : D1 est corrigé, le §1 et le test de
caractérisation associé ne décrivent plus le comportement actuel. Le solde inclut
désormais `travelAmountHT`.
