import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'work_entry.freezed.dart';
part 'work_entry.g.dart';

/// Représente une [WorkEntry] (Prestation de travail) dans l'application.
///
/// Il s'agit de l'unité fondamentale de temps passé chez un client.
/// Elle comptabilise l'heure d'arrivée, de départ, les pauses, et en
/// déduit une durée ainsi qu'un montant final à facturer (M.O.) basé
/// sur le taux horaire de l'artisan. Elle gère également les frais de déplacement.
@freezed
abstract class WorkEntry with _$WorkEntry {
  const factory WorkEntry({
    /// Identifiant unique UUID v4.
    required String id,
    
    /// Date précise à laquelle la prestation a eu lieu.
    required DateOnly date,
    
    /// Heure d'arrivée sur les lieux (exprimée en minutes écoulées depuis minuit, ex: 480 pour 08h00).
    required int startTime,
    
    /// Heure de départ des lieux (exprimée en minutes écoulées depuis minuit).
    required int endTime,
    
    /// Temps de pause en minutes (ex: repas de midi). Sera déduit du temps total.
    @Default(0) int pauseMinutes,
    
    /// Durée de travail calculée = (endTime - startTime) - pauseMinutes.
    required int durationMinutes,
    
    /// Client lié à la prestation.
    required String clientId,
    
    /// Chantier lié à la prestation (Optionnel).
    String? projectId,
    
    /// Liste des tâches accomplies durant la journée.
    @Default([]) List<String> tasks,
    
    /// Notes ou détails internes pour l'organisation.
    String? notes,
    
    /// Mode de facturation choisi (Horaire ou Forfait).
    required BillingMode billingMode,
    
    /// Taux appliqué pour construire la facture finale.
    required Money rateApplied,
    
    /// Total monétaire (Main d'Oeuvre HT) facturé.
    required Money laborAmountHT,
    
    /// Distance (Aller) parcourue pour le chantier.
    @Default(0.0) double travelDistanceKm,
    
    /// Indemnité facturée par kilomètre.
    @Default(0.20) double travelRatePerKm,
    
    /// Total facturé pour le déplacement : (travelDistanceKm * 2) * travelRatePerKm.
    @Default(Money.zero) Money travelAmountHT,
    
    /// Vrai si la durée a été chronométrée au lieu d'être entrée manuellement.
    @Default(false) bool timerUsed,
    
    /// Étiquettes pour classifier la prestation.
    @Default([]) List<String> tags,
    
    /// Fichiers ou photos associés (Bons de travaux, signatures...).
    @Default([]) List<Attachment> attachments,
    
    /// Date de création.
    required DateTime createdAt,
    
    /// Date de modification.
    required DateTime updatedAt,
  }) = _WorkEntry;

  factory WorkEntry.fromJson(Map<String, dynamic> json) => _$WorkEntryFromJson(json);
}
