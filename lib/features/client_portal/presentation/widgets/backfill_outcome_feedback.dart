import 'package:flutter/material.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';

/// Un client sans aucune prestation ni dépense donne totalWorkEntries == 0
/// ET totalExpenses == 0 — indiscernable de isComplete par les seuls
/// compteurs (0/0 est "complet"). "empty" existe pour que ce cas ait un
/// message dédié, ni un succès générique ni un échec (William, C-PORTAL.9
/// étape 3) : "je veux un retour clair, pas un silence qui me ferait croire
/// que ça a échoué".
enum BackfillSnackbarKind { empty, complete, incomplete }

BackfillSnackbarKind classifyBackfillOutcome(BackfillOutcome outcome) {
  if (outcome.totalWorkEntries == 0 && outcome.totalExpenses == 0) return BackfillSnackbarKind.empty;
  return outcome.isComplete ? BackfillSnackbarKind.complete : BackfillSnackbarKind.incomplete;
}

/// Réutilisé par create_portal_dialog.dart (backfill automatique à la
/// création) et ClientDetailPage (bouton "Reprendre l'historique") — un seul
/// endroit pour les 3 messages, pour qu'ils ne divergent jamais entre les
/// deux points d'entrée.
SnackBar backfillOutcomeSnackBar(BackfillOutcome outcome) {
  switch (classifyBackfillOutcome(outcome)) {
    case BackfillSnackbarKind.empty:
      return SnackBar(
        backgroundColor: Colors.blueGrey.shade600,
        content: const Text('Aucun historique à reprendre pour ce client (0 prestation, 0 dépense refacturable).'),
      );
    case BackfillSnackbarKind.complete:
      return SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text(
          'Historique repris : ${outcome.mirroredWorkEntries}/${outcome.totalWorkEntries} prestations, '
          '${outcome.mirroredExpenses}/${outcome.totalExpenses} dépenses.',
        ),
      );
    case BackfillSnackbarKind.incomplete:
      return SnackBar(
        backgroundColor: Colors.orange.shade800,
        content: Text(
          'Reprise incomplète : ${outcome.mirroredWorkEntries}/${outcome.totalWorkEntries} prestations, '
          '${outcome.mirroredExpenses}/${outcome.totalExpenses} dépenses. Relancez depuis la fiche client.',
        ),
      );
  }
}

SnackBar backfillErrorSnackBar() => SnackBar(
      backgroundColor: Colors.red.shade700,
      content: const Text('Échec de la reprise de l\'historique. Réessayez depuis la fiche client.'),
    );
