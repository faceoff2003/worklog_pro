import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'client_settlement.freezed.dart';
part 'client_settlement.g.dart';

/// Représente une remise à zéro du compte d'un [Client].
///
/// Lorsqu'un solde est enregistré, le calcul de la balance courante
/// ne tient compte que des données **postérieures** à [date].
/// Les données antérieures restent archivées et consultables.
@freezed
abstract class ClientSettlement with _$ClientSettlement {
  const factory ClientSettlement({
    /// Identifiant unique UUID v4.
    required String id,

    /// Identifiant du client concerné.
    required String clientId,

    /// Date de remise à zéro (format YYYY-MM-DD).
    /// Seules les entrées strictement postérieures à cette date
    /// sont comptabilisées dans la balance courante.
    required DateOnly date,

    /// Montant soldé en centimes au moment de la remise à zéro.
    /// Enregistré à titre d'information / archivage.
    required Money balanceAtSettlement,

    /// Note libre (ex: "Règlement final chantier Rue de la Loi").
    String? note,

    /// Date de création de l'enregistrement.
    required DateTime createdAt,
  }) = _ClientSettlement;

  factory ClientSettlement.fromJson(Map<String, dynamic> json) =>
      _$ClientSettlementFromJson(json);
}
