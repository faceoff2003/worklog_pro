import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'client_settlement.freezed.dart';
part 'client_settlement.g.dart';

/// Représente une remise à zéro du compte d'un [Client].
///
/// Lorsqu'un solde est enregistré, le calcul de la balance courante ne tient
/// compte que des données saisies après lui (`createdAt` strictement postérieur,
/// jamais [date]), plus le [carriedOverAmount]. Les données antérieures restent
/// archivées et consultables.
@freezed
abstract class ClientSettlement with _$ClientSettlement {
  const factory ClientSettlement({
    /// Identifiant unique UUID v4.
    required String id,

    /// Identifiant du client concerné.
    required String clientId,

    /// Date de remise à zéro (format YYYY-MM-DD).
    /// Sert à choisir le dernier solde et à l'affichage, sans effet sur le
    /// montant : la coupure se fait sur [createdAt].
    required DateOnly date,

    /// Montant soldé en centimes au moment de la remise à zéro.
    /// Enregistré à titre d'information / archivage.
    required Money balanceAtSettlement,

    /// Reste reporté sur la période suivante, en centimes : positif, le client
    /// doit ; négatif, avance du client. Absent ou `null` en base : 0, soit un
    /// solde à zéro (tous les documents antérieurs au solde partiel).
    @Default(Money.zero) Money carriedOverAmount,

    /// Note libre (ex: "Règlement final chantier Rue de la Loi").
    String? note,

    /// Date de création de l'enregistrement.
    required DateTime createdAt,
  }) = _ClientSettlement;

  factory ClientSettlement.fromJson(Map<String, dynamic> json) =>
      _$ClientSettlementFromJson(json);
}
