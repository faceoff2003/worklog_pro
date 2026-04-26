# CONTEXT.md — Audit complet du projet worklog_pro
> Généré le 2026-04-26 · Basé exclusivement sur le code source réel

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

### Dépendances principales
| Package | Version | Rôle |
|---|---|---|
| firebase_core | ^4.4.0 | Firebase init |
| firebase_auth | ^6.1.4 | Authentification |
| cloud_firestore | ^6.1.2 | Base de données |
| firebase_storage | ^13.0.6 | Stockage fichiers |
| firebase_app_check | ^0.4.1+4 | Protection API |
| flutter_riverpod | ^2.6.1 | State management |
| riverpod_annotation | ^2.6.1 | Génération providers |
| freezed_annotation | ^3.1.0 | Immutabilité modèles |
| json_annotation | ^4.9.0 | Sérialisation JSON |
| pdf | ^3.11.1 | Génération PDF |
| printing | ^5.13.4 | Impression/partage PDF |
| excel | ^4.0.6 | Export Excel |
| flutter_secure_storage | ^10.0.0 | Stockage sécurisé |
| local_auth | ^2.3.0 | Biométrie (déclaré, usage non confirmé dans UI) |
| googleapis | ^15.0.0 | Client Google Drive |
| google_sign_in | ^6.2.1 | Auth Google |
| intl | ^0.20.2 | Dates/nombres |
| file_picker | ^10.3.10 | Sélection fichiers |
| image_picker | ^1.1.2 | Photos |
| collection | ^1.18.0 | Utilitaires listes |
| connectivity_plus | ^7.0.0 | État réseau |
| uuid | ^4.5.1 | Génération UUIDs |
| shared_preferences | ^2.5.3 | Préférences locales |
| table_calendar | ^3.2.0 | Widget calendrier |
| rxdart | ^0.28.0 | Extensions Rx (déclaré, usage non confirmé) |
| share_plus | ^10.1.4 | Partage fichiers |
| fl_chart | ^0.70.2 | Graphiques |
| flutter_local_notifications | ^18.0.1 | Notifications locales |
| timezone | ^0.9.4 | Fuseaux horaires |
| http | ^1.2.1 | Requêtes HTTP |
| google_fonts | ^6.3.2 | Typographie |

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
│   │   └── notification_service.dart  ← présent dans les fichiers ouverts
│   ├── utils/                     ← contenu non inventorié
│   ├── value_objects/
│   │   ├── address.dart
│   │   ├── attachment.dart + .freezed + .g
│   │   ├── date_only.dart
│   │   ├── money.dart
│   │   ├── value_objects.dart     ← barrel file
│   │   └── work_duration.dart
│   └── widgets/                   ← contenu non inventorié
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
│   └── widgets/       ← DOSSIER VIDE (reliquat ?)
└── services/          ← DOSSIER VIDE (reliquat ?)
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

### Incohérences
1. `workEntryStreamProvider` (pour un seul item par ID) est déclaré mais retourne `Stream.value(null)` avec un commentaire qui admet que l'implémentation est manquante (`watchWorkEntry` non implémenté dans le repository).
2. Un import commenté subsiste dans `work_entries_provider.dart` ligne 2 : `// import 'package:worklog_pro/core/value_objects/value_objects.dart';` — dead code.
3. `rxdart` est déclaré dans `pubspec.yaml` mais aucun usage trouvé dans le code.
4. Le fichier `reports_page.dart` manipule directement `ref.read(reportFilterProvider.notifier).state = ...` depuis le widget (mutation de state dans l'UI) sans passer par un contrôleur dédié.

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

> ⚠️ **Incohérence rules vs Dart** : `firestore.rules` valide `laborAmountHT` comme `int >= 0` mais dans le code Dart, `travelAmountHT` et `rateApplied` ne sont pas validés par les rules. Aussi, `food` est une catégorie valide dans le code Dart (`ExpenseCategory.food`) mais la rule expenses n'autorise que `['materials', 'travel', 'other']` → **rupture de contrat** : un enregistrement avec `category: 'food'` sera rejeté par Firestore en production.

### `users/{userId}/expenses/{expenseId}`
| Champ | Type | Notes |
|---|---|---|
| id | string | UUID v4 |
| date | string | YYYY-MM-DD |
| clientId | string | FK → clients |
| projectId | string? | FK → projects |
| category | string | `materials` / `travel` / `food` / `other` (**voir incohérence ci-dessus**) |
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
| ClientFormPage (à vérifier) | clients | à vérifier |
| ClientDetailPage (à vérifier) | clients | à vérifier |
| ProjectsListPage | projects | ✅ |
| ProjectFormPage | projects | ✅ |
| ProjectDetailPage | projects | ✅ |
| WorkEntriesListPage | work_entries | ✅ |
| WorkEntryFormPage | work_entries | ✅ (518 lignes) |
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
**Navigator 1.0** (push/pop impératif). Pas de GoRouter, pas de go_router, pas de Navigator 2.0.

### Routes nommées (dans `main.dart`)
```dart
routes: {
  '/login': (context) => const LoginPage(),
  '/register': (context) => const RegisterPage(),
}
```
Seules deux routes nommées. **Tout le reste navigue via `MaterialPageRoute` direct** depuis les widgets (ex: `Navigator.of(context).push(MaterialPageRoute(builder: (_) => ProjectDetailPage(...)))`).

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
- Fichiers `.freezed.dart` et `.g.dart` présents et committé dans le repo → acceptable pour ce type de projet

### Commentaires
- Documentation en français dans les entités (docstrings Dart `///`) → ✅ bonne pratique, bien maintenu sur les entités core

---

## 9. Dette technique identifiée

### TODOs / FIXMEs
**Aucun** `TODO`, `FIXME`, `HACK` ou `XXX` trouvé dans le code. ✅

### Code mort / incomplet
- **`workEntryStreamProvider`** (`work_entries_provider.dart` L47–60) : retourne `Stream.value(null)` avec un long commentaire admettant que `watchWorkEntry` n'est pas implémenté. Fonctionnalité manquante si un écran a besoin d'un stream sur une entrée unique.
- **`lib/presentation/widgets/`** : dossier vide → vestige d'une ancienne structure.
- **`lib/services/`** : dossier vide → idem.
- **`lib/core/migrations/`** : dossier vide. Le champ `schemaVersion: 1` dans `Settings` suggère qu'une mécanique de migration était prévue mais n'est pas implémentée.
- Import commenté ligne 2 de `work_entries_provider.dart`.

### Logique métier dans les widgets
- **`WorkEntryFormPage._save()`** : calcule les montants, résout les clients, construit l'objet `WorkEntry` — logique métier directement dans `State`. Devrait être dans un contrôleur ou service.
- **`WorkEntryFormPage._recalculate()`** : appelle `ref.read(clientsStreamProvider.future)` directement depuis un widget pour récupérer les tarifs → couplage fort entre UI et data.
- **`ReportsPage`** : mute `reportFilterProvider.notifier.state` directement depuis des `onChanged` de widgets — sans contrôleur intermédiaire.

### Appels Firestore directs dans les UI
- Non, les appels Firestore sont correctement encapsulés dans les `RepositoryImpl`. ✅

### Typage
- Pas de champs `dynamic` dans les modèles Freezed. ✅
- Le modèle `Address` (dans `value_objects/`) n'a pas été audité en détail — **à vérifier**.

### Gestion des erreurs
- Les `firstWhere(...)` dans `WorkEntryFormPage._save()` (L186) et `_recalculate()` (L120) peuvent lever `StateError` si le client n'est pas trouvé. Le `try/catch` de `_recalculate` absorbe silencieusement l'erreur. Dans `_save()`, pas de protection → crash possible en production si Firestore et le state sont désynchronisés.
- `_createUserInFirestore()` (auth) catch toutes les exceptions sans les remonter → une erreur de création de profil Firestore passe silencieusement.
- Beaucoup de `debugPrint` de développement encore en place dans `auth_repository_impl.dart` (18 appels `debugPrint`). À supprimer ou remplacer par un logger structuré avant production.

### Tests
- **1 seul fichier de test** : `test/widget_test.dart` (test généré automatiquement par Flutter, inutilisable tel quel).
- Les sous-dossiers `test/core/`, `test/features/`, `test/services/` existent mais sont **vides**.
- **Couverture de tests : 0%** sur la logique métier. C'est le point de dette technique le plus critique du projet.

### Dépendances inutilisées (suspects)
- `rxdart: ^0.28.0` : déclaré, aucun import trouvé dans le code.
- `local_auth: ^2.3.0` : déclaré pour la biométrie, usage UI non trouvé dans les pages auditées.
- `flutter_secure_storage: ^10.0.0` : déclaré, usage non confirmé dans le code audité.
- `firebase_app_check: ^0.4.1+4` : déclaré mais aucun appel à `FirebaseAppCheck.instance.activate()` trouvé dans `main.dart` → **App Check non initialisé**, probablement inefficace.

### Incohérence critique : `ExpenseCategory.food` vs Firestore rules
Le code Dart accepte `ExpenseCategory.food` mais `firestore.rules` n'autorise que `['materials', 'travel', 'other']`. Toute dépense de catégorie `food` sera **rejetée silencieusement par Firestore** en production.

---

## 10. Sécurité Firestore

### Rules présentes
✅ `firestore.rules` est présent et bien structuré (194 lignes).

### Qualité des rules
- **Deny-all par défaut** : ✅ `match /{document=**} { allow read, write: if false; }`
- **Isolation stricte par utilisateur** : ✅ toutes les opérations vérifient `isOwner(userId)`
- **Validation des champs** : ✅ types, longueurs max, valeurs d'enum vérifiés
- **Immuabilité de `createdAt`** : ✅ `createdAtUnchanged()` vérifié sur les updates
- **Pas de règle cross-user** : ✅ aucun utilisateur ne peut lire les données d'un autre

### Storage rules
✅ présentes, deny-all par défaut, lecture/écriture limitées au propriétaire, limite de taille 10MB, types MIME restreints aux images et PDF.

### Problèmes
1. **`ExpenseCategory.food`** : incohérence code/rules décrite en §9.
2. **Firebase App Check non initialisé** dans `main.dart` → le SDK est déclaré mais `activate()` jamais appelé → protection contre les appels abusifs non effective.

---

## 11. Points forts

1. **Value Objects métier exemplaires** : `Money` (stockage en centimes, opérateurs arithmétiques, sérialisation correcte), `DateOnly` (évite les bugs de timezone), `WorkDuration` — niveau professionnel rarement atteint dans des projets de ce stade.
2. **Firestore rules sérieuses** : peu de projets Flutter solo ont des rules aussi strictes et validées. Le deny-all par défaut est une bonne pratique.
3. **Modèles Freezed bien documentés** : chaque champ a un commentaire `///` explicatif en français — excellent pour la maintenabilité.
4. **Enums Firestore-safe** : les enums ont leurs propres `toJson()`/`fromJson()` indépendants de Freezed, ce qui protège contre les renommages accidentels.
5. **Séparation repository/provider cohérente** : les widgets ne touchent jamais Firestore directement, passent tous par les interfaces repository.
6. **Timer persistant** : le chronomètre survit à la fermeture de l'app, avec gestion correcte des pauses accumulées.
7. **Dashboard home lisible** : KPIs, graphique 6 mois, navigation en grille — UX professionnelle.
8. **Export double format** : PDF (multiple templates) + Excel dans la même vue rapports.

---

## 12. État actuel résumé

| Critère | Status |
|---|---|
| App compilable (Android) | ✅ Oui (build.log présent) |
| App compilable (Web) | ✅ Oui (web/ configuré) |
| App compilable (iOS) | ❌ Non configuré |
| Auth fonctionnelle | ✅ |
| CRUD toutes entités | ✅ |
| PDF/Excel export | ✅ |
| Tests automatisés | ❌ Aucun |
| App Check actif | ❌ Non initialisé |
| Deep linking / navigation web | ❌ Navigator 1.0 basique |

### Niveau de stabilité
**Beta avancée / dev** — Pas production-ready pour les raisons suivantes :
- Zéro test = aucun filet de sécurité pour les refactorings
- `ExpenseCategory.food` va crasher silencieusement en production
- `debugPrint` de debug encore en place
- App Check déclaré mais inactif
- `firstWhere` non protégé peut crash en production

### Ce qui marche bien
- Le flux principal : créer un client → un chantier → une prestation → un rapport → exporter PDF
- L'isolation des données par utilisateur (architecture Firestore + rules)
- La modélisation du domaine (entités, value objects)

### Ce qui marche mal / est incomplet
- Tests : inexistants
- `workEntryStreamProvider` pour un item unique : non implémenté (retourne null)
- Biométrie (`local_auth`) : déclarée, non intégrée dans l'UI visible
- Firebase App Check : déclaré, non initialisé
- `ExpenseCategory.food` : incohérence code/rules → bug production
- Navigation web : URLs non partageables, pas de deep linking
- `lib/core/migrations/` vide : migration de schema non implémentée malgré `schemaVersion` dans le modèle
