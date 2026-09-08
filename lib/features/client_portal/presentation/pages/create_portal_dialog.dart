import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_provisioning_service.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_backfill_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/widgets/backfill_outcome_feedback.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';

/// Ouvre le dialog de création de portail. L'appelant DOIT avoir déjà validé
/// que [client].email n'est ni null ni vide (contrainte côté UI, jamais sur
/// l'entité) — ce dialog part du principe que c'est déjà garanti.
Future<void> showCreatePortalDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Client client,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CreatePortalDialog(client: client),
  );
}

bool _isOrphan(ClientPortalProvisioningOutcome outcome) =>
    outcome == ClientPortalProvisioningOutcome.profileCreationFailedOrphaned ||
    outcome == ClientPortalProvisioningOutcome.inviteEmailFailed;

class _CreatePortalDialog extends ConsumerWidget {
  final Client client;
  const _CreatePortalDialog({required this.client});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clientPortalProvisioningControllerProvider);

    ref.listen<AsyncValue<ClientPortalProvisioningResult?>>(clientPortalProvisioningControllerProvider,
        (previous, next) {
      if (next.hasError) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        messenger.showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: const Text('Erreur inattendue. Réessayez.')),
        );
        return;
      }
      final result = next.valueOrNull;
      if (result == null || _isOrphan(result.outcome)) return; // orphelins : rendu inline, dialog reste ouvert
      final messenger = ScaffoldMessenger.of(context);
      // Le container, pas le ref du dialog : le SnackBarAction (ex. "Renvoyer
      // l'email") se déclenche APRÈS le pop() ci-dessous, quand ce widget
      // (et son ref) est déjà disposé — le container, lui, survit.
      final container = ProviderScope.containerOf(context, listen: false);
      Navigator.of(context).pop();
      _showOutcomeSnackBar(messenger, container, result);

      // Portail utilisable dans les deux cas (le lien Client.portalUid est
      // non bloquant, réparé automatiquement si besoin) — reprise
      // automatique de l'historique existant, best-effort : un échec ici ne
      // remet jamais en cause la création qui vient de réussir, le bouton
      // "Reprendre l'historique" de ClientDetailPage reste toujours là pour
      // réessayer (C-PORTAL.9).
      if (result.outcome == ClientPortalProvisioningOutcome.success ||
          result.outcome == ClientPortalProvisioningOutcome.linkPendingAutomaticRepair) {
        _runInitialBackfillAndNotify(container, messenger, result.portalUid!, client.id);
      }
    });

    final result = state.valueOrNull;
    if (result != null && _isOrphan(result.outcome)) {
      return _OrphanResultDialog(result: result);
    }

    final loading = state.isLoading;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Créer un accès portail'),
      content: Text(
        'Un compte sera créé pour ${client.email}. ${client.name} recevra un email '
        'pour définir son mot de passe.',
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: loading
              ? null
              : () => ref.read(clientPortalProvisioningControllerProvider.notifier).createPortal(
                    clientId: client.id,
                    email: client.email!,
                  ),
          icon: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.check),
          label: const Text('Créer le portail'),
          style: FilledButton.styleFrom(backgroundColor: Colors.indigo),
        ),
      ],
    );
  }
}

void _showOutcomeSnackBar(
  ScaffoldMessengerState messenger,
  ProviderContainer container,
  ClientPortalProvisioningResult result,
) {
  switch (result.outcome) {
    case ClientPortalProvisioningOutcome.success:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.green.shade700,
        content: Text('Portail créé pour ${result.email}. Email d\'accès envoyé.'),
      ));
    case ClientPortalProvisioningOutcome.emailAlreadyInUse:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.orange.shade800,
        content: Text(
          'Un compte existe déjà pour ${result.email} — c\'est probablement déjà le portail de ce client.',
        ),
        action: SnackBarAction(
          label: 'Renvoyer l\'email',
          textColor: Colors.white,
          onPressed: () => container.read(portalInviteResendControllerProvider.notifier).resend(result.email),
        ),
      ));
    case ClientPortalProvisioningOutcome.invalidEmail:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: const Text('Adresse email invalide.'),
      ));
    case ClientPortalProvisioningOutcome.authCreationFailed:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text('Échec de la création du compte. Réessayez. (${result.errorDetail})'),
      ));
    case ClientPortalProvisioningOutcome.profileCreationFailedAndCompensated:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.red.shade700,
        content: Text(
          'Échec après création du compte — le compte créé a été supprimé automatiquement. '
          'Vous pouvez réessayer. (${result.errorDetail})',
        ),
      ));
    case ClientPortalProvisioningOutcome.linkPendingAutomaticRepair:
      messenger.showSnackBar(SnackBar(
        backgroundColor: Colors.amber.shade800,
        content: const Text(
          'Portail créé, email envoyé. Le lien sera réparé automatiquement au prochain lancement.',
        ),
      ));
    case ClientPortalProvisioningOutcome.profileCreationFailedOrphaned:
    case ClientPortalProvisioningOutcome.inviteEmailFailed:
      break; // rendu par _OrphanResultDialog, jamais par SnackBar
  }
}

/// Fire-and-forget délibéré depuis le container survivant (voir le
/// commentaire au point d'appel) — ce SnackBar arrive donc APRÈS et
/// SÉPARÉMENT de celui de _showOutcomeSnackBar, jamais fusionné avec lui :
/// la création peut réussir pendant que la reprise, elle, échoue ou reste
/// incomplète, deux issues indépendantes qui méritent chacune leur message.
Future<void> _runInitialBackfillAndNotify(
  ProviderContainer container,
  ScaffoldMessengerState messenger,
  String portalUid,
  String clientId,
) async {
  final controller = container.read(clientPortalHistoryBackfillControllerProvider.notifier);
  await controller.runBackfill(portalUid: portalUid, clientId: clientId);
  final state = container.read(clientPortalHistoryBackfillControllerProvider);
  messenger.showSnackBar(state.hasError ? backfillErrorSnackBar() : backfillOutcomeSnackBar(state.value!));
}

class _OrphanResultDialog extends StatelessWidget {
  final ClientPortalProvisioningResult result;
  const _OrphanResultDialog({required this.result});

  @override
  Widget build(BuildContext context) {
    final isFullOrphan = result.outcome == ClientPortalProvisioningOutcome.profileCreationFailedOrphaned;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Intervention manuelle nécessaire')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isFullOrphan
                  ? 'Échec après création du compte ET la suppression automatique a échoué. '
                      'Ce compte est orphelin — à supprimer manuellement dans la console Firebase.'
                  : 'Le portail a été créé mais l\'email d\'accès n\'est pas parti. Utilisez '
                      '"Renvoyer l\'email d\'accès" depuis la fiche client, ou notez ces identifiants.',
            ),
            const SizedBox(height: 16),
            _CopyableField(label: 'Email', value: result.email),
            const SizedBox(height: 8),
            _CopyableField(label: 'UID', value: result.portalUid!),
            if (result.errorDetail != null) ...[
              const SizedBox(height: 8),
              _CopyableField(label: 'Code', value: result.errorDetail!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}

class _CopyableField extends StatelessWidget {
  final String label;
  final String value;
  const _CopyableField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              SelectableText(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy, size: 18),
          tooltip: 'Copier',
          onPressed: () {
            // Fire-and-forget : la confirmation à l'écran n'a pas besoin
            // d'attendre l'aller-retour plateforme du presse-papiers.
            Clipboard.setData(ClipboardData(text: value));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label copié'), duration: const Duration(seconds: 1)),
            );
          },
        ),
      ],
    );
  }
}
