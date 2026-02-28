import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';

class ExcelExportService {
  /// Génère un fichier Excel (.xlsx) contenant les données du rapport.
  /// Retourne les bytes du fichier généré.
  Future<List<int>> generateExcel(
    ReportData report, {
    Client? client,
    Project? project,
  }) async {
    final excel = Excel.createExcel();
    
    // Supprimer la feuille par défaut "Sheet1" si elle existe
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    _createSummarySheet(excel, report, client, project);
    _createWorkEntriesSheet(excel, report);
    _createExpensesSheet(excel, report);
    _createPaymentsSheet(excel, report);

    // Retourne les bytes (List<int>) du fichier .xlsx
    return excel.encode()!;
  }

  void _createSummarySheet(
    Excel excel,
    ReportData report,
    Client? client,
    Project? project,
  ) {
    final sheet = excel['Résumé'];
    excel.setDefaultSheet('Résumé');

    // Titre
    sheet.appendRow([TextCellValue('Rapport Financier')]);
    
    // Période
    final dateFormat = DateFormat('dd/MM/yyyy');
    final period = 'Du ${dateFormat.format(report.dateRange.start)} au ${dateFormat.format(report.dateRange.end)}';
    sheet.appendRow([TextCellValue('Période'), TextCellValue(period)]);
    
    // Client / Chantier
    if (client != null) {
      sheet.appendRow([TextCellValue('Client'), TextCellValue(client.name)]);
    }
    if (project != null) {
      sheet.appendRow([TextCellValue('Chantier'), TextCellValue(project.label)]);
    }

    sheet.appendRow([TextCellValue('')]); // Ligne vide

    // Totaux
    sheet.appendRow([TextCellValue('Totaux'), TextCellValue('')]);
    sheet.appendRow([TextCellValue('Main d\'œuvre HT'), DoubleCellValue(report.totalLaborAmount.inEuros)]);
    sheet.appendRow([TextCellValue('Déplacements HT'), DoubleCellValue(report.totalTravelAmount.inEuros)]);
    sheet.appendRow([TextCellValue('Dépenses Refacturables HT'), DoubleCellValue(report.totalBillableExpenses.inEuros)]);
    sheet.appendRow([TextCellValue('Production Totale HT'), DoubleCellValue(report.totalProduction.inEuros)]);
    
    sheet.appendRow([TextCellValue('')]); // Ligne vide
    
    sheet.appendRow([TextCellValue('Dépenses Internes HT'), DoubleCellValue(report.totalNonBillableExpenses.inEuros)]);
    sheet.appendRow([TextCellValue('Total Paiements Reçus'), DoubleCellValue(report.totalPayments.inEuros)]);
    
    sheet.appendRow([TextCellValue('')]); // Ligne vide
    
    // Reste à percevoir (Balance théorique)
    sheet.appendRow([TextCellValue('Reste à Percevoir'), DoubleCellValue(report.theoreticalBalance.inEuros)]);
  }

  void _createWorkEntriesSheet(Excel excel, ReportData report) {
    final sheet = excel['Prestations'];
    
    // En-têtes
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Type'),
      TextCellValue('Durée (h)'),
      TextCellValue('Montant MO (HT)'),
      TextCellValue('Montant Dépl (HT)'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final entry in report.workEntries) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(entry.date.toDateTime())),
        TextCellValue(entry.notes ?? ''),
        TextCellValue(entry.billingMode.name),
        DoubleCellValue(entry.durationMinutes / 60.0),
        DoubleCellValue(entry.laborAmountHT.inEuros),
        DoubleCellValue(entry.travelAmountHT.inEuros),
      ]);
    }
  }

  void _createExpensesSheet(Excel excel, ReportData report) {
    final sheet = excel['Dépenses'];
    
    // En-têtes
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Description'),
      TextCellValue('Catégorie'),
      TextCellValue('Refacturable'),
      TextCellValue('Montant (HT)'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final expense in report.expenses) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(expense.date.toDateTime())),
        TextCellValue(expense.description),
        TextCellValue(expense.category.name),
        TextCellValue(expense.isBillable ? 'Oui' : 'Non'),
        DoubleCellValue(expense.amountHT.inEuros),
      ]);
    }
  }

  void _createPaymentsSheet(Excel excel, ReportData report) {
    final sheet = excel['Paiements'];
    
    // En-têtes
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Montant'),
      TextCellValue('Méthode'),
      TextCellValue('Référence'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (final payment in report.payments) {
      sheet.appendRow([
        TextCellValue(dateFormat.format(payment.date.toDateTime())),
        DoubleCellValue(payment.amount.inEuros),
        TextCellValue(payment.method.name),
        TextCellValue(payment.note ?? ''),
      ]);
    }
  }
}
