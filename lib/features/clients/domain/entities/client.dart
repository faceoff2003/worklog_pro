import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';

part 'client.freezed.dart';
part 'client.g.dart';

/// Représente un [Client] dans l'application.
///
/// Le client est l'entité racine à laquelle sont rattachés
/// les [Project]s (Chantiers), [WorkEntry]s (Prestations),
/// [Payment]s (Paiements) et [Expense]s (Dépenses).
@freezed
abstract class Client with _$Client {
  const factory Client({
    /// Identifiant unique UUID v4.
    required String id,
    
    /// Nom ou raison sociale (ex: "Entreprise Dupont", "M. Jean").
    required String name,
    
    /// Type de client (Particulier ou Professionnel).
    required ClientType type,
    
    /// Numéro de téléphone.
    String? phone,
    
    /// Adresse e-mail.
    String? email,
    
    /// Notes internes.
    String? notes,
    
    /// Tarifs par défaut appliqués aux prestations de ce client.
    required DefaultRates defaultRates,
    
    /// Étiquettes pour filtrer ou rechercher plus facilement.
    @Default([]) List<String> tags,

    /// uid Firebase Auth du compte portail de ce client, si un accès lui a
    /// été créé (C-PORTAL). Null = pas de portail. Sert de clé vers
    /// clientPortals/{portalUid} — jamais l'inverse, ce document ne connaît
    /// jamais son propre portail avant qu'on le lui attribue explicitement.
    String? portalUid,

    /// Date de création de la fiche.
    required DateTime createdAt,
    
    /// Date de dernière modification.
    required DateTime updatedAt,
  }) = _Client;

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
}

/// [DefaultRates] encapsule la grille tarifaire préférentielle d'un client.
/// 
/// Utilisés lors de la création d'une intervention pour préremplir les tarifs.
@freezed
abstract class DefaultRates with _$DefaultRates {
  const factory DefaultRates({
    /// Tarif appliqué pour 1 heure de travail en centimes.
    Money? hour,
    
    /// Tarif appliqué pour une demi-journée en centimes.
    Money? halfDay,
    
    /// Tarif appliqué pour une journée complète en centimes.
    Money? day,
    
    /// Tarif au forfait (sans notion de durée).
    Money? fixedJob,
  }) = _DefaultRates;

  factory DefaultRates.fromJson(Map<String, dynamic> json) => _$DefaultRatesFromJson(json);

  factory DefaultRates.empty() => const DefaultRates();
}
