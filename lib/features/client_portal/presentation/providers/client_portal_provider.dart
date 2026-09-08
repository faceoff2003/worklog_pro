import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/data/services/firebase_portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/data/services/firebase_portal_invite_email_sender.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_provisioning_service.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_account_provisioner.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';

/// Un provider par collaborateur (pas un seul provider construisant tout en
/// dur) pour que les tests widgets puissent overrider chacun indépendamment,
/// exactement comme ClientPortalProvisioningService les prend déjà en
/// injection séparée.
final portalAccountProvisionerFactoryProvider = Provider<PortalAccountProvisioner Function()>((ref) {
  return () => FirebasePortalAccountProvisioner();
});

final clientPortalRepositoryProvider = Provider<ClientPortalRepository>((ref) {
  return ClientPortalRepositoryImpl();
});

final portalInviteEmailSenderProvider = Provider<PortalInviteEmailSender>((ref) {
  return FirebasePortalInviteEmailSender();
});

final clientPortalProvisioningServiceProvider = Provider<ClientPortalProvisioningService>((ref) {
  return ClientPortalProvisioningService(
    provisionerFactory: ref.watch(portalAccountProvisionerFactoryProvider),
    clientPortalRepository: ref.watch(clientPortalRepositoryProvider),
    clientRepository: ref.watch(clientRepositoryProvider),
    inviteEmailSender: ref.watch(portalInviteEmailSenderProvider),
  );
});

/// Crée un portail pour un client — un seul appel en vol à la fois : le
/// garde est dans le controller (pas seulement désactivé côté widget), donc
/// même deux taps avant le premier rebuild ne déclenchent qu'un seul appel
/// réel (la 2e vérification de state.isLoading a lieu après l'assignation
/// synchrone du 1er appel, avant tout await).
class ClientPortalProvisioningController extends StateNotifier<AsyncValue<ClientPortalProvisioningResult?>> {
  final ClientPortalProvisioningService _service;
  final String _artisanUid;

  ClientPortalProvisioningController(this._service, this._artisanUid) : super(const AsyncValue.data(null));

  Future<void> createPortal({required String clientId, required String email}) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _service.createPortalAccount(artisanUid: _artisanUid, clientId: clientId, email: email),
    );
  }
}

final clientPortalProvisioningControllerProvider = StateNotifierProvider.autoDispose<
    ClientPortalProvisioningController, AsyncValue<ClientPortalProvisioningResult?>>((ref) {
  final artisanUid = ref.watch(currentUserProvider)?.uid;
  if (artisanUid == null) {
    throw Exception('User must be authenticated to provision a client portal');
  }
  return ClientPortalProvisioningController(ref.watch(clientPortalProvisioningServiceProvider), artisanUid);
});

/// Renvoi indépendant de l'email d'accès — pas de portalUid requis (voir
/// ClientPortalProvisioningService.resendInvite). Même garde anti-double-tap
/// que la création, séparé car les deux actions n'ont aucun état en commun.
class PortalInviteResendController extends StateNotifier<AsyncValue<bool?>> {
  final ClientPortalProvisioningService _service;

  PortalInviteResendController(this._service) : super(const AsyncValue.data(null));

  Future<void> resend(String email) async {
    if (state.isLoading) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.resendInvite(email: email));
  }
}

/// PAS autoDispose (comme ClientsController/AuthController) : déclenché
/// depuis un SnackBarAction dont le dialog appelant est déjà fermé au
/// moment du clic — un provider autoDispose serait éligible à la
/// destruction avant la fin de l'appel, puisque plus personne ne
/// l'observerait entre le pop() et le clic sur l'action.
final portalInviteResendControllerProvider =
    StateNotifierProvider<PortalInviteResendController, AsyncValue<bool?>>((ref) {
  return PortalInviteResendController(ref.watch(clientPortalProvisioningServiceProvider));
});
