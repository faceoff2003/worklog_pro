import 'package:worklog_pro/features/clients/domain/entities/client_settlement.dart';

/// Interface du dépôt de remises à zéro de comptes clients.
abstract class SettlementRepository {
  /// Stream du dernier solde enregistré pour un client.
  /// Retourne [null] si aucun solde n'a jamais été enregistré.
  Stream<ClientSettlement?> watchLastSettlement(String clientId);

  /// Liste tous les soldes d'un client (historique complet), du plus récent au plus ancien.
  Stream<List<ClientSettlement>> watchAllSettlements(String clientId);

  /// Enregistre un nouveau solde pour un client.
  Future<void> createSettlement(ClientSettlement settlement);

  /// Supprime un solde (si nécessaire pour corriger une erreur).
  Future<void> deleteSettlement(String settlementId);
}
