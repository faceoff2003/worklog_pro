import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/core/constants/enums.dart';

/// Template simple : tableau de toutes les prestations + dépenses + totaux
class PdfSimpleTemplate {
  static pw.Document build({
    required ReportData report,
    Client? client,
    Project? project,
    pw.ThemeData? theme,
  }) {
    final doc = pw.Document(theme: theme);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final periodLabel =
        '${dateFormat.format(report.dateRange.start)} – ${dateFormat.format(report.dateRange.end)}';

    // Color palette
    final headerColor = PdfColor.fromHex('#3F51B5');
    final lightBlue = PdfColor.fromHex('#E8EAF6');
    final darkText = PdfColor.fromHex('#212121');
    final subtleText = PdfColor.fromHex('#757575');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (ctx) => _buildHeader(
          ctx,
          periodLabel: periodLabel,
          client: client,
          project: project,
          headerColor: headerColor,
          darkText: darkText,
          subtleText: subtleText,
        ),
        footer: (ctx) => _buildFooter(ctx, subtleText: subtleText),
        build: (ctx) => [
          // Work Entries section
          if (report.workEntries.isNotEmpty) ...[
            _sectionTitle('Prestations', headerColor),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E0E0E0'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: headerColor),
                  children: [
                    _tableHeader('Date'),
                    _tableHeader('Prestation'),
                    _tableHeader('Durée'),
                    _tableHeader('Montant HT', align: pw.TextAlign.right),
                  ],
                ),
                // Data rows
                ...report.workEntries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F5F5');
                  String taskLabel;
                  if (e.notes != null && e.notes!.trim().isNotEmpty) {
                    taskLabel = e.notes!.trim();
                  } else if (project != null) {
                    taskLabel = project.label;
                  } else if (e.tasks.isNotEmpty) {
                    taskLabel = e.tasks.join(', ');
                  } else {
                    taskLabel = _billingLabel(e.billingMode);
                  }
                  final hours = e.durationMinutes ~/ 60;
                  final mins = e.durationMinutes % 60;
                  final duration = hours > 0
                      ? '${hours}h${mins.toString().padLeft(2, '0')}'
                      : '${mins}min';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableCell(dateFormat.format(e.date.toDateTime()), darkText),
                      _tableCell(taskLabel, darkText),
                      _tableCell(duration, darkText),
                      _tableCell(e.laborAmountHT.toEurosString(), darkText, align: pw.TextAlign.right),
                    ],
                  );
                }),
                // Subtotal row
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: lightBlue),
                  children: [
                    _tableCell('', darkText, span: 3),
                    _tableCell(report.totalLaborAmount.toEurosString(), headerColor,
                        align: pw.TextAlign.right, bold: true),
                    // placeholder for span — PDF lib doesn't have colspan, use trick
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Expenses section
          if (report.expenses.isNotEmpty) ...[
            _sectionTitle('Dépenses', headerColor),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColor.fromHex('#E0E0E0'),
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: headerColor),
                  children: [
                    _tableHeader('Date'),
                    _tableHeader('Description'),
                    _tableHeader('Type'),
                    _tableHeader('Montant HT', align: pw.TextAlign.right),
                  ],
                ),
                ...report.expenses.asMap().entries.map((entry) {
                  final i = entry.key;
                  final e = entry.value;
                  final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F5F5');
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bg),
                    children: [
                      _tableCell(dateFormat.format(e.date.toDateTime()), darkText),
                      _tableCell(e.description, darkText),
                      _tableCell(e.isBillable ? 'Refacturable' : 'Interne', darkText),
                      _tableCell(e.amountHT.toEurosString(), darkText, align: pw.TextAlign.right),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 16),
          ],

          // Summary section
          _buildSummary(report, headerColor, darkText, lightBlue),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildHeader(
    pw.Context ctx, {
    required String periodLabel,
    Client? client,
    Project? project,
    required PdfColor headerColor,
    required PdfColor darkText,
    required PdfColor subtleText,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Récapitulatif de Prestations',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                    color: headerColor,
                  ),
                ),
                pw.SizedBox(height: 4),
                if (client != null)
                  pw.Text('Client : ${client.name}',
                      style: pw.TextStyle(fontSize: 11, color: darkText)),
                if (project != null)
                  pw.Text('Chantier : ${project.label}',
                      style: pw.TextStyle(fontSize: 11, color: darkText)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Période', style: pw.TextStyle(fontSize: 10, color: subtleText)),
                pw.Text(periodLabel,
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkText)),
              ],
            ),
          ],
        ),
        pw.Divider(color: headerColor, thickness: 2),
        pw.SizedBox(height: 8),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, {required PdfColor subtleText}) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColor.fromHex('#E0E0E0')),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Généré par WorkLog Pro',
                style: pw.TextStyle(fontSize: 9, color: subtleText)),
            pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: subtleText)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: color,
      ),
    );
  }

  static pw.Widget _tableHeader(String text, {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(
    String text,
    PdfColor color, {
    pw.TextAlign align = pw.TextAlign.left,
    bool bold = false,
    int span = 1,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummary(
    ReportData report,
    PdfColor headerColor,
    PdfColor darkText,
    PdfColor lightBlue,
  ) {
    final balanceColor = report.theoreticalBalance.amountCents > 0
        ? PdfColor.fromHex('#D32F2F')
        : (report.theoreticalBalance.amountCents < 0
            ? PdfColor.fromHex('#7B1FA2')
            : PdfColor.fromHex('#388E3C'));

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightBlue,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: headerColor, width: 0.5),
      ),
      child: pw.Column(
        children: [
          pw.Text('Résumé Financier',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: headerColor)),
          pw.SizedBox(height: 10),
          _summaryRow('Main d\'œuvre (HT)', report.totalLaborAmount.toEurosString(), darkText),
          if (report.totalTravelAmount.amountCents > 0)
            _summaryRow('Frais de déplacement (HT)', report.totalTravelAmount.toEurosString(), darkText),
          _summaryRow('Dépenses refacturables (HT)', report.totalBillableExpenses.toEurosString(), darkText),
          pw.Divider(color: headerColor, thickness: 0.5),
          _summaryRow('Total Production (HT)', report.totalProduction.toEurosString(), headerColor, bold: true),
          pw.SizedBox(height: 4),
          _summaryRow('Frais internes', report.totalNonBillableExpenses.toEurosString(), darkText),
          pw.SizedBox(height: 4),
          pw.Divider(color: PdfColor.fromHex('#9E9E9E'), thickness: 0.5),
          _summaryRow('Paiements Reçus', report.totalPayments.toEurosString(), PdfColor.fromHex('#388E3C')),
          pw.Divider(color: PdfColor.fromHex('#9E9E9E'), thickness: 0.5),
          _summaryRow('Reste à Percevoir', report.theoreticalBalance.toEurosString(), balanceColor, bold: true, fontSize: 13),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value, PdfColor valueColor,
      {bool bold = false, double fontSize = 11}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: PdfColor.fromHex('#424242'))),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: fontSize,
                  fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: valueColor)),
        ],
      ),
    );
  }

  static String _billingLabel(BillingMode mode) {
    switch (mode) {
      case BillingMode.hourly:
        return 'Prestation horaire';
      case BillingMode.half_day:
        return 'Prestation demi-journée';
      case BillingMode.day:
        return 'Prestation à la journée';
      case BillingMode.fixed_job:
        return 'Forfait';
    }
  }
}
