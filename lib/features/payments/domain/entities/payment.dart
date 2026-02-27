import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'payment.freezed.dart';
part 'payment.g.dart';

/// Représente un [Payment] (Paiement) reçu par l'artisan.
///
/// Un paiement est associé à un [Client] et permet de suivre
/// l'état des encaissements. Il est utilisé pour calculer la balance
/// globale (Total Produit HT vs Total Encaissé).
@freezed
abstract class Payment with _$Payment {
  const factory Payment({
    /// Identifiant unique UUID v4.
    required String id,
    
    /// Date à laquelle le paiement a été reçu.
    required DateOnly date,
    
    /// Identifiant du client ayant effectué le paiement.
    required String clientId,
    
    /// Chantier concerné (optionnel, permet d'associer un paiement spécifiquement).
    String? projectId,
    
    /// Montant encaissé, stocké en centimes via [Money] pour la précision.
    required Money amount,
    
    /// Méthode utilisée (Espèces, Virement, Chèque, etc.).
    required PaymentMethod method,
    
    /// Notes ou référence bancaire.
    String? note,
    
    /// Date de création.
    required DateTime createdAt,
    
    /// Date de modification.
    required DateTime updatedAt,
  }) = _Payment;

  factory Payment.fromJson(Map<String, dynamic> json) => _$PaymentFromJson(json);
}
