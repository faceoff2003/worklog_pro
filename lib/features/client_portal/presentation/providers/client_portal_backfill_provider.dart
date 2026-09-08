import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_history_backfill_service.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';

final clientPortalHistoryBackfillServiceProvider = Provider<ClientPortalHistoryBackfillService>((ref) {
  return ClientPortalHistoryBackfillService(
    ref.watch(workEntryRepositoryProvider),
    ref.watch(expenseRepositoryProvider),
    ref.watch(clientPortalRepositoryProvider),
  );
});

/// Statut PERSISTÉ (dernière reprise terminée) — voie de lecture séparée de
/// ClientPortal, voir ClientPortalRepository.getBackfillStatus. null = jamais
/// lancé (ex. un portail créé avant C-PORTAL.9, comme le portail BGS), à
/// distinguer d'un BackfillOutcome incomplet — deux états différents à
/// l'écran.
final backfillStatusProvider = FutureProvider.family.autoDispose<BackfillOutcome?, String>((ref, portalUid) {
  final artisanUid = ref.watch(currentUserProvider)!.uid;
  return ref.watch(clientPortalRepositoryProvider).getBackfillStatus(portalUid, artisanUid);
});

/// Déclenche une reprise d'historique — un seul appel en vol à la fois (même
/// garde que ClientPortalProvisioningController). PAS autoDispose : comme
/// PortalInviteResendController, déclenché à la fois depuis le bouton de
/// ClientDetailPage ET depuis le container survivant de
/// create_portal_dialog.dart après une création — un provider autoDispose
/// serait éligible à la destruction entre les deux, avant la fin de l'appel.
class ClientPortalHistoryBackfillController extends StateNotifier<AsyncValue<BackfillOutcome?>> {
  final ClientPortalHistoryBackfillService _service;

  ClientPortalHistoryBackfillController(this._service) : super(const AsyncValue.data(null));

  Future<void> runBackfill({required String portalUid, required String clientId}) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.backfillHistory(portalUid: portalUid, clientId: clientId));
  }
}

final clientPortalHistoryBackfillControllerProvider =
    StateNotifierProvider<ClientPortalHistoryBackfillController, AsyncValue<BackfillOutcome?>>((ref) {
  return ClientPortalHistoryBackfillController(ref.watch(clientPortalHistoryBackfillServiceProvider));
});
