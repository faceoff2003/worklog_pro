import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/core/constants/enums.dart';

part 'expense.freezed.dart';
part 'expense.g.dart';

/// Représente une [Expense] (Dépense outillage ou matériau) engagée.
///
/// Cette entité est primordiale pour suivre les achats périphériques
/// et facturer le client en conséquence si la dépense est [isBillable].
@freezed
abstract class Expense with _$Expense {
  const factory Expense({
    /// Identifiant unique UUID v4.
    required String id,
    
    /// Date de la dépense.
    required DateOnly date,
    
    /// Client rattaché (ou aucun).
    required String clientId,
    
    /// Chantier concerné.
    String? projectId,
    
    /// Catégorie comptable (matériaux, outillage, sous-traitance, etc.).
    required ExpenseCategory category,
    
    /// Montant Hors Taxes investi (stocké en centimes via [Money]).
    required Money amountHT,
    
    /// Description claire de la dépense (ex: "Peinture murale 10L").
    required String description,
    
    // Optional details
    /// Magasin ou fournisseur.
    String? vendor,
    
    /// Sous-catégorie si c'est du matériel.
    MaterialCategory? materialCategory,
    
    /// Type de transport utilisé si lié au déplacement.
    TravelMode? travelMode,
    
    /// Kilomètres associés si frais de transport externe (péage, essence).
    double? travelDistanceKm,
    
    /// Vrai si la dépense doit être refacturée au client au moment du bilan.
    @Default(true) bool isBillable,
    
    /// Photos des reçus ou factures d'achat.
    @Default([]) List<Attachment> attachments,
    
    /// Date de création de l'enregistrement.
    required DateTime createdAt,
    
    /// Dernière modification de l'enregistrement.
    required DateTime updatedAt,
  }) = _Expense;

  factory Expense.fromJson(Map<String, dynamic> json) => _$ExpenseFromJson(json);
}
