# CONTEXT.md — Audit complet du projet worklog_pro
> Généré le 2026-04-26 · Mis à jour post W-FIX1 le 2026-04-26
> **Resynchronisé post-sprint R-SEC le 2026-09-06** (le document était resté
> figé post W-FIX1 pendant tout le sprint-3 et le sprint R-SEC — voir §9, §10,
> §12 pour ce qui a changé)
> Basé exclusivement sur le code source réel

---

## 1. Identité du projet

- **Nom** : worklog_pro
- **Version** : 1.0.0+1
- **But** : Application mobile de gestion d'activité professionnelle pour **électriciens artisans** (et tout artisan à facturation horaire). Elle permet de tracer les prestations de travail (heures, déplacements), gérer les clients et chantiers, enregistrer les dépenses et paiements, générer des rapports PDF/Excel et sauvegarder des documents sur Google Drive.
- **Utilisateurs cibles** : Électriciens indépendants ou petites équipes en Belgique (indices : `country: 'BE'`, TVA Intracommunautaire, références aux normes Vinçotte, norme Belge).

---

## 2. Stack technique

### SDK / Flutter
- Dart SDK : `>=3.2.0 <4.0.0`
- Flutter : non verrouillé explicitement (suit le SDK Dart)

### Dépendances principales (post W-FIX1.5)
| Package | Version | Rôle |
|---|---|---|
| firebase_core | ^4.4.0 | Firebase init |
| firebase_auth | ^6.1.4 | Authentification |
| cloud_firestore | ^6.1.2 | Base de données |
| firebase_storage | ^13.0.6 | Stockage fichiers |
| firebase_app_check | ^0.4.1+4 | Protection API (**actif** — PlayIntegrity Android + ReCaptchaV3 Web) |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Génération providers |
| freezed_annotation | ^3.1.0 | Immutabilité modèles |
| json_annotation | ^4.9.0 | Sérialisation JSON |
| pdf | ^3.11.1 | Génération PDF |
| printing | ^5.13.4 | Impression/partage PDF |
| excel | ^4.0.6 | Export Excel |
| googleapis | ^15.0.0 | Client Google Drive |
| google_sign_in | ^6.2.1 | Auth Google |
| intl | ^0.20.2 | Dates/nombres |
| file_picker | ^10.3.10 | Sélection fichiers |
| image_picker | ^1.1.2 | Photos |
| collection | ^1.18.0 | Utilitaires listes (firstWhereOrNull) |
| connectivity_plus | ^7.0.0 | État réseau |
| uuid | ^4.5.1 | Génération UUIDs |
| path_provider | ^2.1.0 | Chemins système (PDF/fichiers temp) |
| shared_preferences | ^2.5.3 | Préférences locales |
| table_calendar | ^3.2.0 | Widget calendrier |
| share_plus | ^10.1.4 | Partage fichiers |
| fl_chart | ^0.70.2 | Graphiques |
| flutter_local_notifications | ^18.0.1 | Notifications locales |
| timezone | ^0.9.4 | Fuseaux horaires |
| http | ^1.2.1 | Requêtes HTTP |
| google_fonts | ^6.3.2 | Typographie |

> **Supprimées en W-FIX1.5** : `rxdart`, `local_auth`, `flutter_secure_storage` (non utilisées dans le code).

### Cibles de build configurées
- **Android** : ✅ Configuré (`flutter_launcher_icons.android: true`, `min_sdk_android: 21`)
- **Web** : ✅ Présent (dossier `web/`, `firebase_options.dart` inclut config web)
- **iOS** : ❌ Non configuré (`firebase_options.dart` lève `UnsupportedError` pour iOS)
- **macOS / Windows / Linux** : ❌ Non configurés

### Firebase
- **Project ID** : `worklog-pro-2b3fb`
- **Auth domain** : `worklog-pro-2b3fb.firebaseapp.com`
- **Storage bucket** : `worklog-pro-2b3fb.firebasestorage.app`

---

## 3. Architecture actuelle

### Pattern déclaré vs réalité
Le projet **tente** une Clean Architecture feature-first avec séparation `data / domain / presentation`. La structure est globalement respectée mais **incomplète** : il n'y a **aucune couche `use_cases`**. La logique métier passe directement des repositories aux providers de présentation, ce qui est un écart notable par rapport à la Clean Architecture stricte.

### Structure de `lib/`
```
lib/
├── firebase_options.dart          ← Config Firebase générée
├── main.dart                      ← Point d'entrée (Riverpod ProviderScope, MaterialApp)
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── constants.dart         ← barrel file
│   │   └── enums.dart             ← Tous les enums domaine (très fourni, 369 lignes)
│   ├── errors/
│   │   └── auth_exception.dart
│   ├── migrations/                ← VIDE
│   ├── providers/
│   │   └── theme_provider.dart
│   ├── services/
│   │   ├── google_drive_service.dart
│   │   └── notification_service.dart
│   ├── utils/
│   ├── value_objects/
│   │   ├── address.dart
│   │   ├── attachment.dart + .freezed + .g
│   │   ├── date_only.dart
│   │   ├── money.dart
│   │   ├── value_objects.dart     ← barrel file
│   │   └── work_duration.dart
│   └── widgets/
├── features/
│   ├── auth/          data/domain/presentation
│   ├── clients/       data/domain/presentation
│   ├── expenses/      data/domain/presentation
│   ├── home/          presentation (pas de data/domain propre)
│   ├── payments/      data/domain/presentation
│   ├── pdf/           domain/presentation (pas de data)
│   ├── projects/      data/domain/presentation
│   ├── reports/       domain/presentation (pas de data)
│   ├── settings/      data/domain/presentation
│   ├── timer/         data/domain/presentation
│   └── work_entries/  data/domain/presentation
```
> `lib/presentation/widgets/` et `lib/services/` (dossiers vides, reliquats)
> ont été supprimés en R-SEC.3 (2026-09-06).
>
> `features/settings/` a rejoint le pattern des autres features en
> sprint F-SETTINGS (2026-09-07) : `domain/repositories/settings_repository.dart`
> (interface abstraite, absente jusque-là) + trois implémentations
> concrètes dans `data/repositories/` — voir §5 et
> `doc/F-SETTINGS_SPRINT_REPORT.md` pour le détail.

**Verdict** : Structure feature-first raisonnablement propre. L'absence de
`use_cases` est un choix délibéré ou un oubli — dans les deux cas, c'est à
documenter.

---

## 4. State management

### Outil utilisé
**Riverpod 2.x** (`flutter_riverpod: ^2.6.1` + `riverpod_annotation: ^2.6.1`).

### Comment c'est utilisé concrètement
- Les **repositories** sont exposés via `Provider<Repository>` qui dépend de `authStateProvider` pour injecter le `userId`.
- Les **streams Firestore** sont exposés via `StreamProvider` et `StreamProvider.family.autoDispose`.
- Les **mutations** (create/update/delete) passent par des `StateNotifier` dans des `StateNotifierProvider`. Pattern `AsyncValue.guard()` utilisé proprement.
- Le **thème** utilise un `StateNotifierProvider` avec persistence via `SharedPreferences`.
- Le **timer** utilise un `StateNotifierProvider` avec persistence via repository local.

### Incohérences résiduelles
Toutes résolues en R-SEC.3 (2026-09-06) :
1. ~~`workEntryStreamProvider` retournait `Stream.value(null)`~~ — supprimé (aucun écran n'en dépendait, confirmé par grep avant suppression).
2. ~~Import commenté dans `work_entries_provider.dart` ligne 2~~ — supprimé.
3. ~~`ReportsPage` mutait `reportFilterProvider.notifier.state` directement depuis l'UI~~ — extrait vers `ReportFilterController` (`updateDateRange`/`updateClient`/`updateProject`), testé par caractérisation avant/après (`test/features/reports/presentation/providers/report_providers_test.dart`).

Nouveau, à surveiller : `WorkEntryFormPage._save()` a été refactoré en
R-SEC.3 étape 2 vers `WorkEntryBuilderService`
(`lib/features/work_entries/domain/services/work_entry_builder_service.dart`,
fourni via `workEntryBuilderServiceProvider`) — la construction du
`WorkEntry` (durée, taux appliqué, montant déplacement) n'est plus dans
le widget. La lecture des controllers/providers et la persistance
restent dans `_save()`.

---

## 5. Modèles de données Firestore

Toutes les collections sont **sous-collections de l'utilisateur** : `users/{userId}/{collection}/{docId}`.

### `users/{userId}`
| Champ | Type | Notes |
|---|---|---|
| email | string | |
| displayName | string? | |
| photoUrl | string? | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/clients/{clientId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4, stocké comme doc ID |
| name | string | max 200 chars |
| type | string | `patron` / `client_particulier` / `entreprise` |
| phone | string? | |
| email | string? | |
| notes | string? | |
| defaultRates | map | `{hour, halfDay, day, fixedJob}` — valeurs en **centimes** (int) |
| tags | string[] | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/projects/{projectId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| clientId | string | FK → clients |
| label | string | max 200 chars |
| address | map | objet `Address` |
| type | string | `nouvelle_installation` / `mise_en_conformite` / `depannage` / `renovation` / `domotique` / `autre` |
| status | string | `actif` / `termine` / `en_attente` |
| notes | string? | |
| technicalNotes | string? | |
| accessNotes | string? | |
| distanceKm | double? | distance aller simple |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/workEntries/{entryId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| date | string | format `YYYY-MM-DD` (DateOnly) |
| startTime | int | minutes depuis minuit (0–1439) |
| endTime | int | minutes depuis minuit (0–1439) |
| pauseMinutes | int | défaut 0 |
| durationMinutes | int | calculé |
| clientId | string | FK → clients |
| projectId | string? | FK → projects |
| tasks | string[] | liste de tâches |
| notes | string? | |
| billingMode | string | `hourly` / `half_day` / `day` / `fixed_job` |
| rateApplied | int | centimes (Money) |
| laborAmountHT | int | centimes (Money) |
| travelDistanceKm | double | défaut 0.0 |
| travelRatePerKm | double | défaut 0.20 |
| travelAmountHT | int | centimes (Money) |
| timerUsed | bool | |
| tags | string[] | |
| attachments | map[] | liste `Attachment` |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/expenses/{expenseId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| date | string | YYYY-MM-DD |
| clientId | string | FK → clients |
| projectId | string? | FK → projects |
| category | string | `materials` / `travel` / `food` / `other` (**W-FIX1.1 ✅** : `food` ajouté aux rules) |
| amountHT | int | centimes |
| description | string | max 500 chars |
| vendor | string? | |
| materialCategory | string? | |
| travelMode | string? | |
| travelDistanceKm | double? | |
| isBillable | bool | défaut true |
| attachments | map[] | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/payments/{paymentId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| date | string | YYYY-MM-DD |
| clientId | string | FK → clients |
| projectId | string? | FK → projects |
| amount | int | centimes |
| method | string | `cash` / `virement` / `autre` |
| note | string? | |
| createdAt | timestamp | |
| updatedAt | timestamp | |

### `users/{userId}/settings/main`
**Collection active depuis le sprint F-SETTINGS (2026-09-07)** — ID de
document **fixe** (`main`, pas un ID variable comme les autres
collections : un artisan a un seul jeu de réglages). Rule Firestore
validée par champ connu (fix R-SEC.2 M5, 2026-09-06), étendue en
F-SETTINGS.8 pour couvrir le nouveau champ `updatedAt`
(`optionalString(request.resource.data, 'updatedAt', 40)`, même
pattern que `lastBackupAt`) — **déployée et vérifiée sur appareil**.

| Champ | Type | Notes |
|---|---|---|
| dayHours, halfDayHours, defaultPauseMinutes, roundingMinutes | int | |
| minBillingHours | double | |
| minBillingAmountCents, travelRatePerKmCents | int | centimes |
| currency, country | string | |
| quickTasks, quickVendors | string[] | plafond 200 éléments (rule) |
| pdfHeader | map | `PdfHeader` (nom, tél, email, adresse, TVA, mention HT) |
| autoBackupEnabled | bool | |
| lastBackupAt | timestamp? | |
| schemaVersion | int | prévu pour `lib/core/migrations/` (toujours vide, non utilisé) |
| updatedAt | timestamp? | **ajouté F-SETTINGS.4** — nullable, arbitre les conflits de synchronisation (le plus récent gagne) |

**Architecture — trois repositories, tous `implements SettingsRepository`**
(`lib/features/settings/domain/repositories/settings_repository.dart`,
interface introduite en F-SETTINGS.3) :
- `LocalSettingsRepository` — `SharedPreferences`, source de vérité
  immédiate, jamais bloquante. Expose en interne (pas dans l'interface
  publique) `loadWithStatus()` → `LocalSettingsStatus { absent, loaded,
  corrupted }`, pour distinguer un compte neuf d'un JSON local corrompu.
- `FirestoreSettingsRepository` / `FirestoreCloudSettingsGateway` —
  accès Firestore pur, aucune logique de réconciliation.
- `SyncingSettingsRepository` — celui réellement branché sur
  `settingsRepositoryProvider`. Combine les deux : `loadSettings()` lit
  le local en priorité (non bloquant, sauf branche `corrupted` qui
  attend une réponse du cloud avec un timeout de 4s) pendant qu'une
  réconciliation tourne en tâche de fond (une seule fois par session) ;
  `saveSettings()` écrit local d'abord et toujours, cloud en
  best-effort. Arbitrage de conflit par `updatedAt` le plus récent.
  Détail complet de l'arbre de décision et des deux limites connues
  (controllers UI non resynchronisés après un changement de fond,
  fenêtre de course réduite mais non totalement fermée) dans
  `doc/F-SETTINGS_SPRINT_REPORT.md`.

Avant ce sprint, `Settings` était persisté exclusivement en local
(`SharedPreferences`, clé `app_settings`) — un changement d'appareil,
une réinstallation ou une perte de téléphone effaçait silencieusement
tous les réglages de l'artisan. Dette notée en R-SEC (§9), **résolue**.

### `users/{userId}/client_settlements/{settlementId}`
**Absente de ce document jusqu'ici** — ajoutée par le commit
`sprint-3` (`fcfb531`), jamais reportée dans un audit avant ce
resync (2026-09-06). Représente une remise à zéro du solde d'un
client : les prestations/paiements antérieurs à `date` restent
archivés mais ne comptent plus dans le solde courant affiché.

| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| clientId | string | FK → clients |
| date | string | YYYY-MM-DD — seules les entrées **postérieures** comptent dans le solde courant |
| balanceAtSettlement | int | centimes (Money), solde au moment de la remise à zéro (archivage) |
| note | string? | libre |
| createdAt | timestamp | |

**Immuabilité** : `allow update: if false` (jamais modifiable). `allow
delete` était initialement ouvert au propriétaire — **verrouillé en
R-SEC.2 (`allow delete: if false`)** après confirmation que
`deleteSettlement()` existe dans `settlement_repository_impl.dart`
mais n'est appelé par aucune page/widget (voir SECURITY_AUDIT.md M2).

---

## 6. Features existantes

### Auth
- ✅ Inscription email/password
- ✅ Connexion email/password
- ✅ Connexion Google (OAuth)
- ✅ Déconnexion
- ✅ Réinitialisation mot de passe
- ✅ `AuthWrapper` gère le routage auth/home automatiquement

### Écrans / Pages
| Page | Feature | Status |
|---|---|---|
| LoginPage | auth | ✅ |
| RegisterPage | auth | ✅ |
| HomePage | home | ✅ (dashboard KPIs + graphique CA 6 mois) |
| ClientsListPage | clients | ✅ |
| ClientFormPage | clients | ✅ |
| ClientDetailPage | clients | ✅ (+ remise à zéro du solde — `showSettleAccountDialog`, sprint-3) |
| ProjectsListPage | projects | ✅ |
| ProjectFormPage | projects | ✅ |
| ProjectDetailPage | projects | ✅ |
| WorkEntriesListPage | work_entries | ✅ |
| WorkEntryFormPage | work_entries | ✅ (firstWhere protégés — W-FIX1.2) |
| WorkEntryDetailPage | work_entries | ✅ |
| CalendarPage | work_entries | ✅ |
| ExpensesListPage | expenses | ✅ |
| ExpenseFormPage | expenses | ✅ |
| ExpenseDetailPage | expenses | ✅ |
| PaymentsListPage | payments | ✅ |
| PaymentFormPage | payments | ✅ |
| PaymentDetailPage | payments | ✅ |
| ReportsPage | reports | ✅ (filtres date/client/projet) |
| SettingsPage | settings | ✅ (profil artisan + thème) |

### Actions disponibles
- CRUD complet : clients, projets, prestations, dépenses, paiements
- Calcul automatique de durée et coût M.O. via `WorkCalculatorService`
- Chronomètre persistant (survit à la fermeture de l'app via `SharedPreferences`)
- Génération PDF (facture, devis, rapport simple) avec templates distincts
- Export Excel du rapport filtré
- Partage PDF via `share_plus` ou upload Google Drive
- Vue calendrier des prestations
- Dashboard avec graphique CA 6 derniers mois (fl_chart)
- Mode sombre/clair/système persisté

---

## 7. Routes / Navigation

### Système de navigation
**Navigator 1.0** (push/pop impératif). Pas de GoRouter, pas de Navigator 2.0.

### Routes nommées (dans `main.dart`)
```dart
routes: {
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
}
```
Seules deux routes nommées. **Tout le reste navigue via `MaterialPageRoute` direct** depuis les widgets.

**Conséquence** : pas de deep linking, pas de navigation déclarative, URLs web inutilisables en production.

---

## 8. Conventions de code observées

### Nommage des fichiers
- `snake_case` systématique → ✅ cohérent

### Nommage des classes
- `PascalCase` systématique → ✅ cohérent
- Suffixes clairs : `Page`, `Controller`, `Repository`, `RepositoryImpl`, `Provider`, `Service`

### Enums
- Noms en `snake_case` dans les valeurs (`client_particulier`, `half_day`, `en_attente`) → Style non-idiomatique Dart mais cohérent avec les valeurs Firestore, ce qui évite une couche de mapping supplémentaire. Acceptable mais inhabituel.

### Style des imports
- Imports par package complet (`package:worklog_pro/...`) → ✅ pas d'imports relatifs
- Pas de barrel files globaux sauf `core/constants/constants.dart` et `core/value_objects/value_objects.dart`

### Code generation
- Freezed + json_serializable pour tous les modèles → ✅ cohérent
- Fichiers `.freezed.dart` et `.g.dart` présents et commités dans le repo → acceptable pour ce type de projet

### Commentaires
- Documentation en français dans les entités (docstrings Dart `///`) → ✅ bonne pratique, bien maintenu sur les entités core

### Logging
- **Post W-FIX1.4** : plus aucun `debugPrint` en production. `auth_repository_impl.dart` utilise `dev.log(..., name: 'Auth')` conditionné par `kDebugMode`. ✅

---

## 9. Dette technique

### Résolue en W-FIX1 (2026-04-26)
| # | Problème | Fix |
|---|---|---|
| W-FIX1.1 | `ExpenseCategory.food` rejeté silencieusement par Firestore | `food` ajouté à la whitelist dans `firestore.rules` ✅ |
| W-FIX1.2 | `firstWhere` non protégés dans `WorkEntryFormPage` → crash potentiel | Remplacés par `firstWhereOrNull` + guards + SnackBar ✅ |
| W-FIX1.3 | Firebase App Check déclaré mais non initialisé | `activate()` dans `main.dart` (PlayIntegrity + ReCaptchaV3) ✅ |
| W-FIX1.4 | 18 `debugPrint` actifs en production dans auth | `dev.log` conditionné par `kDebugMode` ✅ |
| W-FIX1.5 | `rxdart`, `local_auth`, `flutter_secure_storage` inutilisés | Supprimés de `pubspec.yaml` ✅ |
| W-FIX1.6 | `isOptionalString` dead-code dans `firestore.rules` | Supprimé ✅ |

### Résolue en sprint R-SEC (2026-09-06)
Sprint sécurité + refactoring, 6 étapes (R-SEC.0 à R-SEC.5). Détail
complet des findings de sécurité dans `SECURITY_AUDIT.md`. **Rules
M2-M5 déployées et vérifiées sur appareil par William avant le début du
sprint F-SETTINGS** (2026-09-07).

| # | Problème | Fix |
|---|---|---|
| R-SEC M1 | `WorkCalculatorService.calculateDuration` pouvait renvoyer une durée négative (endTime==startTime+pause, ou pause > durée brute) → `laborAmountHT` négatif rejeté en silence par Firestore | Lève `ArgumentError` ; validation live ajoutée sur le champ Pause (`WorkEntryFormPage._validatePause`) ✅ |
| R-SEC M2 | `client_settlements` : `allow delete` ouvert au propriétaire, contournait l'immuabilité (delete + recreate) | `allow delete: if false` — confirmé coût fonctionnel nul (`deleteSettlement()` inutilisé par l'UI) ✅ déployé |
| R-SEC M3 | `clients.defaultRates` non validé (taux négatif ou mal typé possible) | Validation "absent/null ou positif" par clé (`hour/halfDay/day/fixedJob`) ✅ déployé |
| R-SEC M4 | `project.type`, `expense.materialCategory`, `expense.travelMode` sans whitelist | Whitelists ajoutées (pattern absent/null/liste — critique car données réelles avec `materialCategory`/`travelMode` à `null`) ✅ déployé |
| R-SEC M5 | `settings` : écriture libre, zéro validation | Validation par champ connu + plafonds de taille ✅ déployé — étendue en F-SETTINGS.8 (champ `updatedAt`), voir plus bas |
| R-SEC (structurel) | Import mort, dossiers vides, provider mort (`workEntryStreamProvider`), logique métier dans `WorkEntryFormPage._save()` et `ReportsPage` | Nettoyés / extraits (`WorkEntryBuilderService`, `ReportFilterController`) ✅ |
| R-SEC.4 | 48 `info` `flutter analyze` (dérive depuis les 27 post W-FIX1, jamais retracée avant ce resync) | Nettoyé à 12 (voir tableau plus bas) ✅ |

### Résolue en sprint F-SETTINGS (2026-09-07)
Sprint synchronisation cloud des réglages, 8 étapes (F-SETTINGS.1 à
F-SETTINGS.8). Détail complet dans `doc/F-SETTINGS_SPRINT_REPORT.md`.

| # | Problème | Fix |
|---|---|---|
| F-SETTINGS (besoin initial) | `Settings` persisté exclusivement en local — changement d'appareil/réinstallation = perte silencieuse de tous les réglages | `SyncingSettingsRepository` : local d'abord, synchronisation Firestore en tâche de fond, `SharedPreferences` conservé comme cache offline ✅ |
| F-SETTINGS M5 (rule) | Champ `updatedAt` (nouveau) non validé par les rules — un type invalide aurait arbitré un conflit de synchronisation dans le mauvais sens | `optionalString(request.resource.data, 'updatedAt', 40)` ajouté, testé sur l'émulateur avant/après (98/98) ✅ déployé |
| F-SETTINGS (bug diagnostiqué en prod) | `updatedAt` gelé après le premier stamp reçu du cloud — l'arbitrage "le plus récent gagne" cessait de refléter la réalité après la première synchronisation | Stamp inconditionnel à chaque `saveSettings()`, un seul objet daté réutilisé pour le local et le cloud ✅ |
| F-SETTINGS (course diagnostiquée) | La réconciliation de fond pouvait écraser une sauvegarde utilisateur plus récente, décidée sur un état local périmé | Relecture fraîche + revérification juste avant chaque écriture locale de la réconciliation — réduit la fenêtre, ne la ferme pas totalement (voir Résiduelle ci-dessous) ✅ |

### Résiduelle (connue, non bloquante)

#### Code mort / incomplet
- **`lib/core/migrations/`** : toujours vide. `schemaVersion: 1` existe sur `Settings` mais aucune migration n'a été nécessaire pour l'ajout du champ `updatedAt` en F-SETTINGS.4 (nullable, sans `@Default` — un JSON local existant reste lisible tel quel). Reste en attente d'un futur changement de schéma qui en aurait réellement besoin.

#### Résiduel du sprint F-SETTINGS (2026-09-07) — connu, non corrigé

**Fenêtre de course réduite, pas fermée** (`SyncingSettingsRepository._reconcile()`) :
le fix F-SETTINGS.8 relit l'état local juste avant chaque écriture pour
éviter d'écraser une sauvegarde utilisateur plus récente, mais
l'intervalle entre cette relecture et l'écriture qui suit n'est protégé
par aucun verrou (`SharedPreferences` n'en fournit pas) — documenté
explicitement en commentaire dans le code plutôt que présenté comme une
garantie absolue. Détail dans `doc/F-SETTINGS_SPRINT_REPORT.md`.

#### `SettingsPage` — controllers non resynchronisés après le premier build (F-SETTINGS, 2026-09-07)
**Problème** : `_SettingsPageState._initControllers()`
(`lib/features/settings/presentation/pages/settings_page.dart`) fait
`if (_initialized) return;` en première ligne, et n'est appelée que
depuis `build()`. Les `TextEditingController` de l'en-tête PDF ne sont
donc peuplés qu'à la toute première valeur reçue de `settingsProvider`
— si cette valeur change ensuite (typiquement : la réconciliation de
fond de `SyncingSettingsRepository` ramène une valeur cloud différente
après le premier affichage), les champs affichés restent figés sur
l'ancienne valeur, silencieusement désynchronisés de l'état réel.

**Pourquoi non bloquant pour l'instant** : avec un seul appareil, la
réconciliation ne fait converger le local vers le cloud que dans des
cas déjà couverts par le flux normal (premier lancement, restauration
après corruption) — la fenêtre où l'utilisateur a l'écran Réglages
ouvert pendant qu'une valeur *différente* arrive du cloud est étroite.
Devient visible et gênant avec un second appareil qui aurait modifié
les réglages entre-temps : l'appareil resté ouvert sur l'écran
Réglages afficherait des valeurs obsolètes sans le savoir.

**Non corrigé délibérément** (décision du 2026-09-07, diagnostic
F-SETTINGS.6) — nécessiterait de resynchroniser les controllers à
chaque changement de valeur (`ref.listen` plutôt que le
`if (_initialized) return`), hors périmètre du diagnostic en cours.

#### App Check — aucune branche debug pour le web (découvert C-PORTAL.7, 2026-09-07)
**Problème** : `lib/main.dart:34-41` (`FirebaseAppCheck.instance.activate()`)
a une branche `kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity`
pour Android, mais le `webProvider` utilise systématiquement
`ReCaptchaV3Provider(...)`, même en dev — aucun équivalent du token
debug Android côté web.

**Découvert en testant C-PORTAL.7 sur web pour la première fois**
(jamais testé sur cette plateforme avant ce jour) : `createPortal()`
échouait systématiquement avec `FirebaseError: AppCheck: ReCAPTCHA
error (appCheck/recaptcha-error)` sur `localhost` — la clé ReCAPTCHA
codée en dur n'est probablement pas configurée pour ce domaine, et
l'enforcement App Check est confirmé actif côté console pour Firestore
(voir `SECURITY_AUDIT.md` I2, mis à jour le 2026-09-07). Bloque **toute**
écriture Firestore depuis le web en local, pas seulement le
provisioning de portail — préexistant à C-PORTAL, jamais vu faute
d'avoir testé le web avant.

**Contournement utilisé pour tester C-PORTAL.7** : ajout temporaire
(non commis) dans `main.dart` d'un bloc `useFirestoreEmulator`/
`useAuthEmulator` gardé par `--dart-define=USE_EMULATOR=true`, pour
pointer le build web sur les émulateurs locaux sans toucher à la
config App Check réelle.

**Fix proposé, non appliqué** : ajouter une branche debug côté web,
symétrique à Android — soit un token de debug App Check enregistré en
console (mécanisme standard Firebase pour le dev web), soit
conditionner `webProvider` sur `kDebugMode` comme pour Android. Touche
à la sécurité (`main.dart`, activation App Check) — décision de
William avant tout fix, hors périmètre C-PORTAL.

#### Routage de rôle C-PORTAL.7 — un client mal routé peut écrire dans son propre espace artisan (2026-09-08)
**Problème** : `decideRoleRoute()` (`lib/features/client_portal/presentation/providers/user_role_provider.dart`)
route vers `HomePage` (artisan) sur une erreur de `getPortal(uid)`
identifiée comme réseau (`unavailable`, `deadline-exceeded`,
`cancelled`, ou le `TimeoutException` du filet 15s) — décision prise
après mesure empirique (AVD réel, document jamais mis en cache, backend
injoignable : le SDK Firestore met ~11,7s avant de lâcher
`unavailable`, un blocage dur aurait rendu l'app inutilisable hors
ligne pour l'usage réel de William, cave/vide sanitaire).

**Révisé le même jour** : la version initiale routait TOUTE erreur sauf
`permission-denied` vers artisan — trop large. Un vrai bug de
désérialisation (`TypeError` sur `clientPortals/{uid}.createdAt`, voir
plus bas) a montré qu'une erreur de CODE prenait le même chemin qu'une
panne réseau, silencieusement. Depuis, seules les erreurs réseau
listées ci-dessus routent vers artisan ; tout le reste (y compris
`permission-denied`, `unauthenticated`, une erreur de désérialisation,
ou un type imprévu) route vers l'écran de blocage.

**Effet de bord accepté, pas corrigé** : un CLIENT dont la vérification
échoue pour une raison RÉSEAU (typiquement hors ligne) atterrit sur
`HomePage` et pourrait y créer des documents sous
`users/{son_propre_uid}/...` — autorisé par les rules (`isOwner(uid)`,
c'est son propre espace). Ça ne pollue les données d'aucun artisan réel
et n'ouvre aucun trou de sécurité (voir CONTEXT.md ci-dessus sur le
même sujet — un uid client n'a jamais accès à `users/{uid_artisan}/...`
d'un autre), mais laisse des documents orphelins sous cet uid si un
rôle artisan réel lui était attribué plus tard.

**Non corrigé délibérément** — décision de William (2026-09-08) :
router vers le blocage sur une vraie panne réseau serait pire (un
artisan hors ligne bloqué en production) que ce résiduel (des documents
orphelins sous un uid qui n'a jamais eu de compte artisan légitime).

#### App Check web (I2) — code d'erreur inconnu sur une lecture, risque non mesuré pour un artisan (2026-09-08)
**Problème** : App Check est confirmé actif côté console pour Firestore
(SECURITY_AUDIT.md, I2), et le web n'a toujours aucune branche debug
(voir l'entrée juste en dessous) — dette déjà connue. Ce qui est NOUVEAU
ici : `decideRoleRoute()` ne route vers artisan que sur un code d'erreur
réseau précis (`unavailable`/`deadline-exceeded`/`cancelled`). Le code
qu'une vraie rejection App Check produit sur une LECTURE Firestore n'a
jamais été mesuré empiriquement — seul l'échec d'une ÉCRITURE (la
création de portail) a été observé, et le test terrain du 2026-09-08
qui a trouvé le bug `Timestamp` a justement vu une lecture RÉUSSIR
malgré App Check actif sur ce même build web.

**Conséquence** : on ne peut pas garantir aujourd'hui qu'un artisan sur
web, un jour, ne se fera jamais bloquer par ce chemin précis si App
Check venait à rejeter une lecture avec un code hors de la liste réseau
(`permission-denied` par exemple, plausible pour ce genre de rejet).

**Pas de mesure faite maintenant, décision explicite de William** : dette
écrite ici pour ne pas rester un risque flottant non documenté — la
mesure et un fix éventuel restent à faire, pas dans ce sprint.

#### Tâche à part — migration `dart:html` → `package:web`
**Problème** : `lib/features/reports/presentation/utils/file_saver_web.dart`
(et non `file_saver_util.dart`, comme indiqué par erreur plus bas dans
ce document — corrigé ici) utilise `dart:html` (`html.Blob`,
`html.Url.createObjectUrlFromBlob`, `html.AnchorElement(...).click()`)
pour déclencher le téléchargement d'un fichier (PDF/Excel) côté Web.
`dart:html` est déprécié en faveur de `package:web`.

**Ce que ça implique** : ce n'est pas un renommage mécanique comme les
autres infos de `flutter analyze` (R-SEC.4) — `package:web` a des
types différents (`web.Blob`, `web.URL.createObjectURL`,
`web.HTMLAnchorElement`) et demande de l'interop JS
(`dart:js_interop`) pour convertir la liste d'octets Dart en objet JS.
Ce code n'est actif que sur Web (`if (kIsWeb)` dans
`file_saver_util.dart`), une cible secondaire de l'app (Android est la
cible principale — voir §2 et §12). Non testable dans cet
environnement : pas de navigateur permettant de vérifier le
téléchargement réel. Sortie du périmètre R-SEC.4 (décision du
2026-09-06) — à traiter en tâche dédiée, avec un test manuel du
téléchargement web avant/après.

#### `flutter analyze` (post R-SEC.4, 2026-09-06)
**0 erreur · 0 warning · 12 `info`** (était 27 post W-FIX1, dérivé à 48
pendant sprint-3 sans jamais être retracé — la principale cause de la
dérive était `DropdownButtonFormField.value` déprécié par une mise à
jour du SDK Flutter, 17 occurrences, absente de l'ancien tableau
ci-dessous car survenue après) :

| Type | Count | Nature |
|---|---|---|
| `constant_identifier_names` | 11 | Enums snake_case dans `enums.dart` — **volontaire**, ne jamais toucher (Firestore-safe) |
| `dart:html` deprecated | 1 | `file_saver_web.dart` — migration `package:web`, tâche à part (voir plus haut), pas un nettoyage mécanique |

Tout le reste (17 `value`→`initialValue`, 10 `prefer_const_*`, 5
`use_build_context_synchronously`, 2 `unrelated_type_equality_checks`,
1 `withOpacity`, 1 `unnecessary_to_list_in_spreads` — 36 au total)
nettoyé en R-SEC.4, un commit par catégorie. Les 2
`unrelated_type_equality_checks` restants dans les tests Money/DateOnly
sont volontaires et désormais suppressés par `// ignore:` documenté
(sinon comptés — voir `test/core/value_objects/`).

Ancien tableau (post W-FIX1, 27 info — historique, dépassé) :
| Type | Count | Nature |
|---|---|---|
| `constant_identifier_names` | 11 | Enums snake_case dans `enums.dart` — volontaire (Firestore-safe) |
| `use_build_context_synchronously` | 5 | Async UI forms — dette connue |
| `prefer_const_*` | 8 | Style mineur |
| `depend_on_referenced_packages` | 2 | `path_provider` maintenant déclaré (résolu) |
| `dart:html` deprecated | 1 | migration `package:web` à planifier |
| `withOpacity` deprecated | 1 | → `.withValues()` à migrer |
| `unnecessary_to_list_in_spreads` | 1 | Style mineur |

#### Tests (post F-SETTINGS, 2026-09-07)
**325 tests, tous verts** (`flutter test`). Ajouts du sprint F-SETTINGS
par rapport au dernier resync (291, post R-SEC) : caractérisation de
`LocalSettingsRepository` (F-SETTINGS.2/.3), tests de l'arbre de
réconciliation complet de `SyncingSettingsRepository` avec un
`FakeCloudSettingsGateway` en mémoire — y compris hors ligne, timeout,
et la course réconciliation/sauvegarde reproduite via un `Completer`
contrôlé (F-SETTINGS.5/.8) —, réactivité de
`settingsRecoveryFailedProvider` et rendu réel du bandeau dans
`SettingsPage` (F-SETTINGS.7). Complétés par
`integration_test/firestore_cloud_gateway_test.dart` (3 tests, émulateur
réel, AVD Android `test_avd_medium` — la traduction absent/loaded/refus
par `FirestoreCloudSettingsGateway`, hors du compte `flutter test`
ci-dessus) et `firestore-tests/rules.test.mjs` (98 tests contre
l'émulateur Firestore, rules réelles, y compris le nouveau champ
`settings.updatedAt`).

Répartis dans `test/core/value_objects/`,
`test/features/*/domain/services/`, `test/features/*/data/repositories/`,
`test/features/*/presentation/pages/`,
`test/features/*/presentation/providers/` et
`test/features/reports/presentation/providers/`. `test/widget_test.dart`
(smoke test généré, inutilisable) supprimé en R-SEC.0.

**Couverture globale (lignes, `flutter test --coverage`) : ~31 % au
dernier calcul (R-SEC, pas recalculé pendant F-SETTINGS)** — chiffre
trompeur si lu seul : la logique argent-critique est à 100 % (`Money`,
`WorkDuration`, `WorkCalculatorService`, `WorkEntryBuilderService`),
`DateOnly` à 98 % (1 ligne : un `catch` mort, voir
`SECURITY_AUDIT.md`), `work_entry_form_page.dart` à ~84 % grâce aux
tests widgets de caractérisation (4 modes de facturation × avec/sans
déplacement + divergence création/édition). Les trois repositories de
`settings` sont désormais couverts (F-SETTINGS, voir plus haut) — les
autres repositories (`ClientRepositoryImpl`, `WorkEntryRepositoryImpl`,
etc.), les providers Firestore et la plupart des autres pages restent à
0 % — **priorité suivante si le sprint continue**.

#### Navigation
- Navigator 1.0 basique → pas de deep linking, URLs web non partageables.

---

## 10. Sécurité Firestore

> **Audit complet** : `SECURITY_AUDIT.md` (R-SEC.1, 2026-09-06). Ce qui
> suit est un résumé — se référer à ce document pour le détail par
> finding et leur statut de déploiement exact.

### Rules présentes
✅ `firestore.rules` est présent et bien structuré.

### Qualité des rules
- **Deny-all par défaut** : ✅ (le bloc `match /{document=**} { allow read, write: if false; }` en tête ne fait rien en pratique — Firestore combine les `allow` en OR — mais inoffensif ici, toutes les collections réelles ont une règle explicite)
- **Isolation stricte par utilisateur** : ✅ toutes les opérations vérifient `isOwner(userId)`
- **Validation des champs** : ✅ types, longueurs max, valeurs d'enum vérifiés — étendue en R-SEC.2 à `clients.defaultRates` (M3), `project.type`/`expense.materialCategory`/`expense.travelMode` (M4), `settings` (M5) ; étendue en F-SETTINGS.8 au champ `settings.updatedAt`
- **Immuabilité de `createdAt`** : ✅ `createdAtUnchanged()` vérifié sur les updates
- **Immuabilité de `client_settlements`** : ✅ `allow update: if false` **et** `allow delete: if false` depuis R-SEC.2 (M2) — le `delete` était ouvert au propriétaire avant, contournement possible de l'immuabilité par delete+recreate
- **`ExpenseCategory.food`** : ✅ **corrigé en W-FIX1.1** — `food` dans la whitelist
- **Dead code `isOptionalString`** : ✅ **supprimé en W-FIX1.6**

Les fixes R-SEC.2 (M2/M3/M4/M5) et l'extension F-SETTINGS.8 (validation
de `settings.updatedAt`) sont **déployés sur le projet Firebase
`worklog-pro-2b3fb` et vérifiés sur appareil par William**.

### Storage rules
✅ présentes, deny-all par défaut, lecture/écriture limitées au propriétaire, limite 10MB, types MIME restreints images/PDF.

### App Check
✅ **Actif depuis W-FIX1.3** :
- Android debug : `AndroidProvider.debug`
- Android release : `AndroidProvider.playIntegrity`
- Web : `ReCaptchaV3Provider` (clé publique `6Lcj3Mss...`)

---

## 11. Points forts

1. **Value Objects métier exemplaires** : `Money` (centimes, opérateurs arithmétiques, sérialisation correcte), `DateOnly` (anti-timezone-bug), `WorkDuration`.
2. **Firestore rules sérieuses** : deny-all, validation des champs, isolation stricte par utilisateur.
3. **Modèles Freezed bien documentés** : chaque champ a un commentaire `///` en français.
4. **Enums Firestore-safe** : `toJson()`/`fromJson()` indépendants de Freezed — protège contre les renommages accidentels.
5. **Séparation repository/provider cohérente** : les widgets ne touchent jamais Firestore directement.
6. **Timer persistant** : survit à la fermeture de l'app, gestion correcte des pauses.
7. **Dashboard** : KPIs + graphique CA 6 mois — UX professionnelle.
8. **Export double format** : PDF (multiple templates) + Excel dans la même vue rapports.
9. **Logging production-safe** (post W-FIX1.4) : aucun `debugPrint` en production.
10. **Sécurité Git** : `.gitignore` complet excluant tous les secrets Firebase, keystores, `.env`.
11. **Filet de tests sur le code argent-critique** (R-SEC, 2026-09-06) : 100 % sur `Money`/`WorkDuration`/`WorkCalculatorService`/`WorkEntryBuilderService`, tests de caractérisation avant chaque refactoring (`_save()`, filtres de rapports), tests widgets sur `WorkEntryFormPage` (4 modes de facturation × avec/sans déplacement, validation live, création/édition).
12. **Suite de tests rules Firestore contre l'émulateur** (`firestore-tests/`, `@firebase/rules-unit-testing`) : chaque fix M2-M5 vérifié avant/après sur l'émulateur, jamais déployé sans preuve.

---

## 12. État actuel résumé

| Critère | Status |
|---|---|
| App compilable (Android) | ✅ |
| App compilable (Web) | ✅ |
| App compilable (iOS) | ❌ Non configuré |
| Auth fonctionnelle | ✅ |
| CRUD toutes entités | ✅ |
| PDF/Excel export | ✅ |
| Firebase App Check | ✅ **Actif** (W-FIX1.3) |
| Logging production-safe | ✅ **Propre** (W-FIX1.4) |
| Firestore rules cohérentes | ✅ **Corrigées** (W-FIX1.1 + W-FIX1.6) |
| `firstWhere` protégés | ✅ **Sécurisés** (W-FIX1.2) |
| Dépendances nettoyées | ✅ **Allégé** (W-FIX1.5) |
| Tests automatisés | ✅ **325 tests** (voir §9 Tests) — 0% → couverture ciblée sur deux sprints (R-SEC, F-SETTINGS) |
| Deep linking / navigation web | ❌ Navigator 1.0 basique |
| `flutter analyze` | ✅ 0 erreur · 0 warning · **12 info** (dont 11 volontaires) |
| Rules Firestore M2-M5 + F-SETTINGS.8 (SECURITY_AUDIT.md) | ✅ **Déployées et vérifiées sur appareil** (M1 est un fix de code Dart, pas une rule, déjà inclus dans l'APK release) |
| Réglages artisan synchronisés cloud (F-SETTINGS) | ✅ `SyncingSettingsRepository`, local-first + réconciliation Firestore |
| Build APK release | ✅ Réussi (F-SETTINGS.8, 2026-09-07) |

### Niveau de stabilité
**Beta avancée / production-candidat** — Stable et sécurisé pour le
déploiement Firebase Hosting / Play Store. Les rules R-SEC.2 et
l'extension F-SETTINGS.8 sont déployées et vérifiées.

Blocants restants avant prod réelle :
- Navigation web non déclarative → URLs non partageables
- Couverture de tests concentrée sur le chemin argent-critique et,
  depuis F-SETTINGS, les réglages — les autres repositories/providers
  Firestore et la plupart des pages restent à 0%
- Résiduel F-SETTINGS non bloquant : controllers `SettingsPage` non
  resynchronisés après le premier build, fenêtre de course
  réconciliation/sauvegarde réduite mais non totalement fermée (voir §9
  et `doc/F-SETTINGS_SPRINT_REPORT.md`)

### Prochaines étapes suggérées
1. **Migration `dart:html`** → `package:web` dans `file_saver_web.dart` (voir § Dette — tâche à part, sortie de R-SEC.4).
2. **Étendre la couverture de tests** aux repositories restants (ex. `WorkEntryRepositoryImpl` contre l'émulateur Firestore) et aux pages à 0%.
3. **Findings L1-L6 et I1-I5** (SECURITY_AUDIT.md) : décider s'ils méritent un futur sprint sécurité ou restent acceptés en l'état.
4. **Sprint fonctionnel** : selon roadmap produit (ex: module Devis).
5. **CI/CD GitHub Actions** : lint + build automatisés sur chaque PR.
