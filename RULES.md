# Règles de développement — Antigravity

> Ces règles s'appliquent à CHAQUE session de développement sans exception.

---

## R01 — Sécurité avant tout
- Firestore rules strictes dès le départ — jamais `allow read, write: if true`
- Vérifier `request.auth != null` sur toutes les collections
- Rôles vérifiés côté Firestore rules, pas uniquement Flutter
- Aucun secret, token ou clé API dans le code ou les commits
- Valider tous les inputs avant d'écrire dans Firestore

## R02 — POO & bonnes pratiques strictes
- SOLID, DRY, KISS — sans exception
- Pas de logique métier dans les widgets Flutter
- Repositories implémentent une interface abstraite (DIP)
- Typage fort partout — interdire `dynamic` sauf cas justifié
- Pas de `setState` dans les features — Riverpod uniquement
- Pas d'appel Firestore direct dans les screens

## R03 — Économie de tokens
- Pas de commentaires évidents
- Pas de code boilerplate inutile
- Réponses concises — uniquement le code demandé + imports nécessaires
- Pas de récapitulatif après chaque bloc de code

## R04 — Une feature = un sprint
- Chaque sprint = une seule feature
- Chaque feature découpée en étapes numérotées : F-AUTH.1, F-AUTH.2...
- Pas de multi-feature en parallèle

## R05 — Validation avant de continuer
- À la fin de chaque étape : **demander explicitement confirmation**
- Format : "Étape X.Y terminée. On passe à X.Z ?"
- Attendre le OK avant de continuer

## R06 — Fin de sprint = debug + test + build
- `flutter analyze` → zéro erreur, zéro warning
- `flutter build apk --release` → build réussi
- Pas de `TODO`, `FIXME` ou `print()` dans le code livré
- Rapport de build présenté avant de demander validation

## R07 — Flutter CLI autonome
- Antigravity installe et utilise Flutter CLI directement
- Crée le projet via `flutter create`
- Ajoute les dépendances via `flutter pub add`
- Ne pas attendre que l'humain fasse des actions manuelles CLI

## R08 — GitHub — une branche par feature
- Créer `feature/nom-feature` depuis `main`
- Commit à chaque étape terminée
- Messages de commit en anglais, format conventionnel :
  `feat(auth): add login screen with email/password`
- PR vers `main` uniquement après validation du build

---

## Prompt type à utiliser pour chaque étape

```
Projet : PrestoTrack (voir CONTEXT.md dans le repo)
Repo : faceoff2003/prestotrack

Feature en cours : [NOM FEATURE]
Étape : [N.X] — [DESCRIPTION COURTE]

Contexte : [ce qui est déjà fait]
Tâche : [ce qu'il doit faire UNIQUEMENT dans cette étape]

Règles : voir RULES.md dans le repo
```

---

## Conventions de nommage

| Élément | Convention | Exemple |
|---|---|---|
| Fichiers | snake_case | `prestation_repository.dart` |
| Classes | PascalCase | `PrestationRepository` |
| Variables/méthodes | camelCase | `getPrestations()` |
| Constantes | kCamelCase | `kMaxPause` |
| Providers Riverpod | camelCase + Provider | `prestationsProvider` |
| Collections Firestore | camelCase pluriel | `prestations`, `chantiers` |

---

## Workflow d'un sprint

1. Créer branche `feature/xxx` depuis `main`
2. Annoncer le plan de l'étape 1
3. Coder l'étape N → commit → demander confirmation
4. Attendre OK → passer à l'étape N+1
5. Fin de sprint : `flutter analyze` + `flutter build` → rapport
6. Ouvrir PR `feature/xxx → main` avec description
7. Attendre merge par William
