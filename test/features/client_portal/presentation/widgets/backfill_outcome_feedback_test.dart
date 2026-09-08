// C-PORTAL.9, étape 3 — classification pure, sans widget ni Firestore.
//
// Point spécifiquement demandé par William : un client sans AUCUN
// historique (0 prestation, 0 dépense) doit être distingué d'un backfill
// complet générique — sinon "0/0" se confond silencieusement avec un
// succès, ce qu'il a explicitement refusé ("je veux un retour clair, pas un
// silence qui me ferait croire que ça a échoué").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/presentation/widgets/backfill_outcome_feedback.dart';

BackfillOutcome _outcome({
  int totalWorkEntries = 0,
  int mirroredWorkEntries = 0,
  int totalExpenses = 0,
  int mirroredExpenses = 0,
}) =>
    BackfillOutcome(
      totalWorkEntries: totalWorkEntries,
      mirroredWorkEntries: mirroredWorkEntries,
      totalExpenses: totalExpenses,
      mirroredExpenses: mirroredExpenses,
    );

void main() {
  group('classifyBackfillOutcome', () {
    test('0 prestation ET 0 dépense → empty, pas complete', () {
      expect(classifyBackfillOutcome(_outcome()), BackfillSnackbarKind.empty);
    });

    test('0 prestation mais des dépenses réelles → PAS empty (un seul total à 0 ne suffit pas)', () {
      final outcome = _outcome(totalExpenses: 5, mirroredExpenses: 5);
      expect(classifyBackfillOutcome(outcome), BackfillSnackbarKind.complete);
    });

    test('0 dépense mais des prestations réelles → PAS empty', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 20);
      expect(classifyBackfillOutcome(outcome), BackfillSnackbarKind.complete);
    });

    test('tout mirroré → complete', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 20, totalExpenses: 5, mirroredExpenses: 5);
      expect(classifyBackfillOutcome(outcome), BackfillSnackbarKind.complete);
    });

    test('prestations incomplètes → incomplete', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 3, totalExpenses: 5, mirroredExpenses: 5);
      expect(classifyBackfillOutcome(outcome), BackfillSnackbarKind.incomplete);
    });

    test('dépenses incomplètes → incomplete même si les prestations sont complètes', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 20, totalExpenses: 5, mirroredExpenses: 0);
      expect(classifyBackfillOutcome(outcome), BackfillSnackbarKind.incomplete);
    });
  });

  group('backfillOutcomeSnackBar — les deux compteurs apparaissent séparément, jamais un total', () {
    test('message complet mentionne prestations ET dépenses distinctement', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 20, totalExpenses: 5, mirroredExpenses: 5);
      final text = (backfillOutcomeSnackBar(outcome).content as Text).data!;
      expect(text, contains('20/20 prestations'));
      expect(text, contains('5/5 dépenses'));
    });

    test('message incomplet mentionne les deux compteurs réels, pas un agrégat', () {
      final outcome = _outcome(totalWorkEntries: 20, mirroredWorkEntries: 3, totalExpenses: 5, mirroredExpenses: 5);
      final text = (backfillOutcomeSnackBar(outcome).content as Text).data!;
      expect(text, contains('3/20 prestations'));
      expect(text, contains('5/5 dépenses'));
    });

    test('message "empty" est neutre (ni le texte de succès ni celui d\'échec)', () {
      final text = (backfillOutcomeSnackBar(_outcome()).content as Text).data!;
      expect(text, contains('Aucun historique'));
      expect(text, isNot(contains('repris :')));
      expect(text, isNot(contains('incomplète')));
    });
  });
}
