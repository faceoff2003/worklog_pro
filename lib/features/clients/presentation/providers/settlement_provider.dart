import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:worklog_pro/core/value_objects/date_only.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/clients/data/repositories/settlement_repository_impl.dart';
import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';
import 'package:worklog_pro/features/clients/domain/repositories/settlement_repository.dart';

/// Provider du [SettlementRepository].
final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepositoryImpl();
});

/// Stream du dernier solde pour un client donné (null si aucun).
final lastSettlementProvider =
    StreamProvider.family.autoDispose<ClientSettlement?, String>(
  (ref, clientId) {
    final repo = ref.watch(settlementRepositoryProvider);
    return repo.watchLastSettlement(clientId);
  },
);

/// Stream de tous les soldes d'un client (historique complet).
final allSettlementsProvider =
    StreamProvider.family.autoDispose<List<ClientSettlement>, String>(
  (ref, clientId) {
    final repo = ref.watch(settlementRepositoryProvider);
    return repo.watchAllSettlements(clientId);
  },
);

/// Controller pour les opérations de solde.
class SettlementsController extends StateNotifier<AsyncValue<void>> {
  final SettlementRepository _repository;

  SettlementsController(this._repository) : super(const AsyncData(null));

  /// Enregistre un solde pour le client [clientId] avec la balance actuelle [currentBalance].
  /// À partir de la date d'aujourd'hui, la balance courante redémarrera de zéro.
  Future<void> settle({
    required String clientId,
    required Money currentBalance,
    String? note,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final settlement = ClientSettlement(
        id: const Uuid().v4(),
        clientId: clientId,
        date: DateOnly.today(),
        balanceAtSettlement: currentBalance,
        note: note,
        createdAt: DateTime.now(),
      );
      await _repository.createSettlement(settlement);
    });
  }

  /// Supprime un solde (correction d'erreur).
  Future<void> deleteSettlement(String settlementId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.deleteSettlement(settlementId),
    );
  }
}

/// Provider du [SettlementsController].
final settlementsControllerProvider =
    StateNotifierProvider<SettlementsController, AsyncValue<void>>((ref) {
  return SettlementsController(ref.watch(settlementRepositoryProvider));
});
