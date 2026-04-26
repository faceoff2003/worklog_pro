# CONTEXT.md — Audit complet du projet worklog_pro
> Généré le 2026-04-26 · Mis à jour post W-FIX1 le 2026-04-26
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
├── presentation/
│   └── widgets/       ← DOSSIER VIDE (reliquat)
└── services/          ← DOSSIER VIDE (reliquat)
```

**Verdict** : Structure feature-first raisonnablement propre. Deux dossiers vides (`lib/presentation/`, `lib/services/`) trahissent un refactoring inachevé. L'absence de `use_cases` est un choix délibéré ou un oubli — dans les deux cas, c'est à documenter.

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
1. `workEntryStreamProvider` (pour un seul item par ID) retourne `Stream.value(null)` — `watchWorkEntry` non implémenté dans le repository.
2. Import commenté dans `work_entries_provider.dart` ligne 2 : dead code mineur.
3. `ReportsPage` mute `reportFilterProvider.notifier.state` directement depuis l'UI sans contrôleur dédié.

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

### `users/{userId}/settings/{settingId}`
Contient un document `Settings` (Freezed) avec les préférences de l'artisan (tarifs, PDF header, etc.). Pas de validation stricte dans les rules (write libre pour le propriétaire).

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
| ClientDetailPage | clients | ✅ |
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

### Résiduelle (connue, non bloquante)

#### Code mort / incomplet
- **`workEntryStreamProvider`** : retourne `Stream.value(null)` — `watchWorkEntry` non implémenté. Impact : aucun écran actuel n'en dépend.
- **`lib/presentation/widgets/`** et **`lib/services/`** : dossiers vides — vestiges d'un ancien refactoring.
- **`lib/core/migrations/`** : vide. `schemaVersion: 1` dans `Settings` suggère une mécanique de migration prévue mais non implémentée.
- Import commenté ligne 2 de `work_entries_provider.dart`.

#### Logique métier dans les widgets
- **`WorkEntryFormPage._save()`** : calcule les montants et construit `WorkEntry` directement dans le `State`. Devrait être dans un contrôleur ou service.
- **`ReportsPage`** : mute `reportFilterProvider.notifier.state` directement depuis des callbacks UI.

#### `flutter analyze` (post W-FIX1)
**0 erreur · 0 warning** — 27 `info` acceptés :
| Type | Count | Nature |
|---|---|---|
| `constant_identifier_names` | 11 | Enums snake_case dans `enums.dart` — volontaire (Firestore-safe) |
| `use_build_context_synchronously` | 5 | Async UI forms — dette connue |
| `prefer_const_*` | 8 | Style mineur |
| `depend_on_referenced_packages` | 2 | `path_provider` maintenant déclaré (résolu) |
| `dart:html` deprecated | 1 | `file_saver_util.dart` — migration `package:web` à planifier |
| `withOpacity` deprecated | 1 | → `.withValues()` à migrer |
| `unnecessary_to_list_in_spreads` | 1 | Style mineur |

#### Tests
- **1 seul fichier de test** : `test/widget_test.dart` (test généré automatiquement, inutilisable tel quel).
- Les sous-dossiers `test/core/`, `test/features/`, `test/services/` existent mais sont **vides**.
- **Couverture de tests : 0%** sur la logique métier. Point de dette le plus critique. Priorité : tester `WorkCalculatorService`.

#### Navigation
- Navigator 1.0 basique → pas de deep linking, URLs web non partageables.

---

## 10. Sécurité Firestore

### Rules présentes
✅ `firestore.rules` est présent et bien structuré.

### Qualité des rules
- **Deny-all par défaut** : ✅
- **Isolation stricte par utilisateur** : ✅ toutes les opérations vérifient `isOwner(userId)`
- **Validation des champs** : ✅ types, longueurs max, valeurs d'enum vérifiés
- **Immuabilité de `createdAt`** : ✅ `createdAtUnchanged()` vérifié sur les updates
- **`ExpenseCategory.food`** : ✅ **corrigé en W-FIX1.1** — `food` dans la whitelist
- **Dead code `isOptionalString`** : ✅ **supprimé en W-FIX1.6**

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
| Tests automatisés | ❌ Aucun (priorité sprint suivant) |
| Deep linking / navigation web | ❌ Navigator 1.0 basique |
| `flutter analyze` | ✅ 0 erreur · 0 warning · 27 info acceptés |

### Niveau de stabilité
**Beta avancée / production-candidat** — Stable et sécurisé pour le déploiement Firebase Hosting / Play Store.

Blocants restants avant prod réelle :
- Couverture de tests 0% → risque sur les refactorings
- Navigation web non déclarative → URLs non partageables

### Prochaines étapes suggérées
1. **Tests unitaires** : `WorkCalculatorService` en priorité (logique de facturation critique)
2. **Sprint fonctionnel** : selon roadmap produit (ex: module Devis)
3. **Migration `dart:html`** → `package:web` dans `file_saver_util.dart`
4. **CI/CD GitHub Actions** : lint + build automatisés sur chaque PR
