# SPRINT BACKUP — Système de sauvegarde & restauration

> Créé le 2026-07-13
> Status : 📋 Planifié — En attente de développement

---

## Objectif

Permettre à l'artisan de **sauvegarder automatiquement toutes ses données** (clients, chantiers, prestations, dépenses, paiements, soldes de compte) dans un fichier chiffré, stocké localement sur l'appareil ET uploadé automatiquement sur Google Drive. En cas de perte de données Firebase, l'utilisateur peut **restaurer** l'intégralité de ses données directement depuis l'app.

---

## Décisions de conception

| Critère | Décision retenue |
|---|---|
| Chiffrement | ✅ AES-256 avec **mot de passe défini par l'utilisateur** dans les paramètres |
| Fréquence | ✅ **Automatique, tous les jours** (via WorkManager en arrière-plan) |
| Stockage local | ✅ Fichier `.wlb` sauvegardé dans le dossier Documents du téléphone |
| Stockage distant | ✅ **Google Drive** (dossier `WorkLog Pro Backups/`) |
| Restauration | ✅ **Depuis l'app** : choisir le fichier → déchiffrer → réimporter |
| Stratégie de restauration | ✅ **Fusion** : on ajoute les données manquantes, on ne supprime rien d'existant |
| Identification des doublons | Par `id` UUID de chaque document (pas d'écrasement si l'UUID existe déjà) |

---

## Format du fichier de backup

- **Extension** : `.wlb` (WorkLog Backup)
- **Nom du fichier** : `worklog_backup_YYYY-MM-DD_HH-mm.wlb`
- **Contenu brut (avant chiffrement)** : JSON structuré comme suit :

```json
{
  "version": 1,
  "exportedAt": "2026-07-13T22:00:00.000Z",
  "userId": "firebase_user_id",
  "collections": {
    "clients": [...],
    "projects": [...],
    "workEntries": [...],
    "expenses": [...],
    "payments": [...],
    "clientSettlements": [...],
    "settings": {...}
  }
}
```

- **Chiffrement** : AES-256-CBC avec le mot de passe utilisateur comme clé (dérivé via PBKDF2)
- Le fichier final est binaire, illisible sans le mot de passe

---

## Architecture technique

### Nouveaux packages à ajouter

| Package | Rôle |
|---|---|
| `encrypt` | Chiffrement/déchiffrement AES-256 |
| `workmanager` | Tâche de backup automatique en arrière-plan |
| `pointycastle` | Dérivation de clé PBKDF2 (dépendance d'`encrypt`) |

> **Note** : `googleapis`, `google_sign_in`, `path_provider`, `file_picker`, `share_plus` sont déjà dans le projet ✅

---

### Nouveaux fichiers à créer

```
lib/
└── features/
    └── backup/
        ├── domain/
        │   ├── entities/
        │   │   └── backup_manifest.dart        ← Modèle Freezed du manifeste JSON
        │   └── services/
        │       ├── backup_service.dart          ← Orchestre export + chiffrement
        │       └── restore_service.dart         ← Orchestre déchiffrement + import
        ├── data/
        │   └── services/
        │       ├── encryption_service.dart      ← AES-256 + PBKDF2
        │       └── drive_backup_service.dart    ← Upload/download Google Drive
        └── presentation/
            ├── pages/
            │   └── backup_page.dart             ← Page dédiée dans Paramètres
            ├── widgets/
            │   ├── backup_status_card.dart      ← Carte "Dernière sauvegarde le..."
            │   ├── backup_password_dialog.dart  ← Dialog pour définir le mot de passe
            │   └── restore_dialog.dart          ← Dialog de confirmation de restauration
            └── providers/
                └── backup_providers.dart        ← Providers Riverpod
```

### Fichiers existants à modifier

| Fichier | Modification |
|---|---|
| `lib/features/settings/presentation/pages/settings_page.dart` | Ajouter un bouton/section "Sauvegardes" qui navigue vers `BackupPage` |
| `pubspec.yaml` | Ajouter `encrypt`, `workmanager`, `pointycastle` |
| `android/app/src/main/AndroidManifest.xml` | Ajouter permission `INTERNET` si absente + déclaration WorkManager |
| `firestore.rules` | Aucun changement nécessaire (backup lit les données existantes) |

---

## Détail des tâches (Stories)

### 🏗️ Étape 1 — Infrastructure chiffrement
- [ ] Ajouter les packages `encrypt` + `workmanager` dans `pubspec.yaml`
- [ ] Créer `encryption_service.dart` avec méthodes `encrypt(String json, String password)` et `decrypt(Uint8List data, String password)`
- [ ] Tester le chiffrement/déchiffrement en isolation
- [ ] Stocker le mot de passe backup dans `shared_preferences` (hashé, pas en clair)

### 📦 Étape 2 — Export des données
- [ ] Créer `backup_manifest.dart` (modèle Freezed + toJson)
- [ ] Créer `BackupService.export()` :
  - Lit toutes les sous-collections Firestore de l'utilisateur connecté
  - Sérialise en JSON
  - Chiffre avec `EncryptionService`
  - Sauvegarde le fichier `.wlb` localement via `path_provider`
  - Retourne le chemin du fichier créé

### ☁️ Étape 3 — Upload Google Drive
- [ ] Créer `DriveBackupService` (s'appuie sur `GoogleDriveService` existant)
- [ ] Créer (si inexistant) le dossier `WorkLog Pro Backups/` dans le Drive de l'utilisateur
- [ ] Uploader le fichier `.wlb` après chaque backup local réussi
- [ ] Conserver uniquement les **30 derniers backups** sur Drive (suppression des plus anciens)

### ♻️ Étape 4 — Restauration
- [ ] Créer `RestoreService.restore(Uint8List encryptedFile, String password)` :
  - Déchiffre le fichier
  - Parse le JSON
  - Pour chaque collection : vérifie les UUIDs existants → n'écrit que les documents manquants (fusion)
  - Barre de progression pendant l'import
- [ ] Gérer les erreurs : mauvais mot de passe, fichier corrompu, version incompatible

### 🔄 Étape 5 — Backup automatique quotidien
- [ ] Configurer `WorkManager` pour déclencher `BackupService.export()` toutes les nuits (ex: 03h00)
- [ ] Déclencher uniquement si l'utilisateur est connecté et a défini un mot de passe
- [ ] Afficher une notification locale après backup réussi (optionnelle, configurable)
- [ ] Gérer les cas : pas de réseau (backup local uniquement, Drive à la prochaine occasion)

### 🖥️ Étape 6 — Interface utilisateur
- [ ] Créer `BackupPage` accessible depuis `SettingsPage`
- [ ] `BackupStatusCard` : date/heure du dernier backup réussi, indicateur Drive ☁️ / Local 📱
- [ ] `BackupPasswordDialog` : définir/changer le mot de passe (avec confirmation)
- [ ] Bouton **"Sauvegarder maintenant"** (backup manuel immédiat)
- [ ] Bouton **"Restaurer"** : ouvre `FilePicker` pour choisir un `.wlb` → demande le mot de passe → lance la restauration
- [ ] Bouton **"Voir les backups Drive"** : liste les fichiers `.wlb` disponibles sur Drive
- [ ] Ajouter l'entrée "Sauvegardes" dans `SettingsPage`

---

## Ordre de développement recommandé

```
Étape 1 (Chiffrement)
      ↓
Étape 2 (Export)
      ↓
Étape 4 (Restauration)   ← Tester le cycle complet export/restore avant d'automatiser
      ↓
Étape 3 (Drive)
      ↓
Étape 5 (WorkManager)
      ↓
Étape 6 (UI)
```

---

## Règles de sécurité

- Le **mot de passe** n'est **jamais stocké en clair** — seulement un hash bcrypt pour vérification
- Si l'utilisateur **oublie son mot de passe**, les anciens backups sont irrécupérables (comportement attendu et documenté dans l'UI)
- Le fichier `.wlb` ne contient **aucune donnée lisible** sans le mot de passe
- L'accès Google Drive se fait avec le **scope minimal** (`drive.file` : accès uniquement aux fichiers créés par l'app)

---

## Critères de validation (Definition of Done)

- [ ] Export d'un compte complet → fichier `.wlb` lisible localement
- [ ] Fichier uploadé sur Google Drive dans le bon dossier
- [ ] Restauration depuis un fichier local → données réimportées sans doublons
- [ ] Restauration depuis un fichier Drive → idem
- [ ] Mauvais mot de passe → message d'erreur clair, pas de crash
- [ ] Fichier corrompu → message d'erreur clair, pas de crash
- [ ] WorkManager déclenche le backup quotidien même quand l'app est fermée
- [ ] L'interface affiche la date du dernier backup réussi

---

## Sprints précédents

| Sprint | Contenu | Status |
|---|---|---|
| W-FIX1 | Corrections critiques (App Check, rules, firstWhere, debugPrint, deps) | ✅ Terminé |
| Sprint Tests | Tests unitaires Money (77 tests) + DateOnly (88 tests) — 100% coverage | ✅ Terminé |
| Sprint 3 | Remise à zéro de compte client + fix PDF description + fix balance cutoff | ✅ Terminé |
| **Sprint Backup** | **Système de backup/restauration chiffré + Google Drive** | 📋 **Planifié** |
