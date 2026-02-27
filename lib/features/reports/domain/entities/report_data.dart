import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:worklog_pro/core/value_objects/money.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';

part 'report_data.freezed.dart';

/// [ReportData] est une entité d'agrégation immuable (Value Object).
///
/// Elle sert uniquement à regrouper et transporter les résultats 
/// des rapports financiers (filaires ou PDF) sur une liste de prestations
/// et dépenses filtrées par date ou client.
@freezed
abstract class ReportData with _$ReportData {

  const factory ReportData({
    /// Total de la main d'ouvre accumulée.
    required Money totalLaborAmount,
    
    /// Total des frais de déplacements accumulés.
    required Money totalTravelAmount,

    /// Total des dépenses qui peuvent être refacturées au client.
    required Money totalBillableExpenses,
    
    /// Total des dépenses internes de fonctionnement (non refacturables).
    required Money totalNonBillableExpenses,
    
    /// Somme totale de tous les encaissements perçus.
    required Money totalPayments,
    
    /// Les entrées de travail détaillées intégrées dans le rapport.
    required List<WorkEntry> workEntries,
    
    /// Les dépenses détaillées intégrées.
    required List<Expense> expenses,
    
    /// Les paiements détaillés intégrés.
    required List<Payment> payments,
    
    /// Période de validité des filtres du rapport.
    required DateTimeRange dateRange,
  }) = _ReportData;

  const ReportData._();

  /// Volume total du "Produit" (Production effective de valeur) 
  /// = Main d'œuvre + Déplacements + Dépenses Refacturables.
  Money get totalProduction => totalLaborAmount + totalTravelAmount + totalBillableExpenses;
  
  /// Balance Théorique pour ce rapport : Combien a été produit vs Combien a été encaissé.
  /// Un nombre positif indique de l'argent dû, un négatif indique un trop-perçu ou acompte.
  Money get theoreticalBalance => totalProduction - totalPayments;
}
