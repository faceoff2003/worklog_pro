import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'project.freezed.dart';
part 'project.g.dart';

/// Représente un [Project] (Chantier) dans l'application.
///
/// Un chantier est obligatoirement lié à un [Client] via son [clientId].
/// Il centralise l'historique des travaux, des factures, des dépenses
/// et optionnellement une distance kilométrique servant au calcul des frais
/// de déplacement pour les interventions associées.
@freezed
class Project with _$Project {
  const factory Project({
    /// Identifiant unique UUID v4.
    required String id,
    
    /// Identifiant du client auquel appartient ce chantier.
    required String clientId,
    
    /// Nom ou titre descriptif du chantier (ex: "Rénovation Cuisine Dupont").
    required String label,
    
    required Address address,
    required ProjectType type,
    required ProjectStatus status,
    String? notes,
    String? technicalNotes,
    String? accessNotes,
    
    /// Distance (Aller simple) en kilomètres depuis le siège/domicile vers le chantier.
    /// Sera multipliée par 2 pour les frais de déplacement.
    double? distanceKm,
    
    /// Date et heure de la création du dossier chantier.
    required DateTime createdAt,
    
    /// Date et heure de la dernière modification des informations du chantier.
    required DateTime updatedAt,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}
