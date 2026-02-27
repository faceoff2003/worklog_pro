import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/core/constants/enums.dart';

/// Template Facture professionnel
class PdfInvoiceTemplate {
  static pw.Document build({
    required ReportData report,
    Client? client,
    Project? project,
    required String invoiceNumber,
    String? companyName,
    String? companySiret,
    String? companyPhone,
    String? companyEmail,
    pw.ThemeData? theme,
  }) {
    final doc = pw.Document(theme: theme);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final invoiceDate = dateFormat.format(DateTime.now());
    final periodLabel =
        '${dateFormat.format(report.dateRange.start)} – ${dateFormat.format(report.dateRange.end)}';

    final headerColor = PdfColor.fromHex('#1A237E');
    final accentColor = PdfColor.fromHex('#3F51B5');
    final lightBg = PdfColor.fromHex('#E8EAF6');
    final darkText = PdfColor.fromHex('#212121');
    final subtleText = PdfColor.fromHex('#757575');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => _buildFooter(ctx, subtleText: subtleText, invoiceNumber: invoiceNumber),
        build: (ctx) => [
          // Header : Artisan info + FACTURE label
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Left: Company info
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: headerColor,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        companyName ?? 'Artisan',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (companySiret != null)
                      pw.Text('SIRET: $companySiret',
                          style: pw.TextStyle(fontSize: 10, color: subtleText)),
                    if (companyPhone != null)
                      pw.Text('Tél: $companyPhone',
                          style: pw.TextStyle(fontSize: 10, color: subtleText)),
                    if (companyEmail != null)
                      pw.Text('Email: $companyEmail',
                          style: pw.TextStyle(fontSize: 10, color: subtleText)),
                  ],
                ),
              ),
              // Right: FACTURE + number + date
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'FACTURE',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  pw.Text('N° $invoiceNumber',
                      style: pw.TextStyle(fontSize: 14, color: darkText)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date : $invoiceDate',
                      style: pw.TextStyle(fontSize: 11, color: darkText)),
                  pw.Text('Période : $periodLabel',
                      style: pw.TextStyle(fontSize: 10, color: subtleText)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Client info box
          if (client != null)
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('FACTURÉ À',
                      style: pw.TextStyle(
                          fontSize: 9, color: subtleText, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text(client.name,
                      style: pw.TextStyle(
                          fontSize: 13, fontWeight: pw.FontWeight.bold, color: darkText)),
                  if (client.phone != null)
                    pw.Text('Tél: ${client.phone}',
                        style: pw.TextStyle(fontSize: 10, color: darkText)),
                  if (client.email != null)
                    pw.Text('Email: ${client.email}',
                        style: pw.TextStyle(fontSize: 10, color: darkText)),
                  if (project != null)
                    pw.Text('Chantier: ${project.label}',
                        style: pw.TextStyle(fontSize: 10, color: accentColor)),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Lines table
          pw.Text('Détail des Prestations',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#C5CAE9'),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(1.5),
              1: const pw.FlexColumnWidth(3.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children: [
                  _header('Date'),
                  _header('Description'),
                  _header('Mode'),
                  _header('Montant HT', align: pw.TextAlign.right),
                ],
              ),
              ...report.workEntries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F5F5');
                final taskLabel = e.tasks.isNotEmpty
                    ? e.tasks.join(', ')
                    : _billingLabel(e.billingMode);
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell(dateFormat.format(e.date.toDateTime()), darkText),
                    _cell(taskLabel, darkText),
                    _cell(_billingLabel(e.billingMode), darkText),
                    _cell(e.laborAmountHT.toEurosString(), darkText, align: pw.TextAlign.right),
                  ],
                );
              }),
              // Expenses (billable only)
              ...report.expenses.where((e) => e.isBillable).toList().asMap().entries.map((entry) {
                final i = entry.key + report.workEntries.length;
                final e = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F5F5F5');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell(dateFormat.format(e.date.toDateTime()), darkText),
                    _cell('${e.description}${e.vendor != null ? " (${e.vendor})" : ""}', darkText),
                    _cell('Matériel', darkText),
                    _cell(e.amountHT.toEurosString(), darkText, align: pw.TextAlign.right),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),

          // Totals
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 260,
                child: pw.Column(
                  children: [
                    _totalRow('Main d\'œuvre HT', report.totalLaborAmount.toEurosString(), darkText),
                    if (report.totalTravelAmount.amountCents > 0)
                      _totalRow('Frais de déplacement HT', report.totalTravelAmount.toEurosString(), darkText),
                    _totalRow('Matériaux refacturables HT', report.totalBillableExpenses.toEurosString(), darkText),
                    pw.Divider(color: accentColor, thickness: 0.5),
                    _totalRow('TOTAL HT', report.totalProduction.toEurosString(), accentColor,
                        bold: true, fontSize: 13),
                    pw.SizedBox(height: 8),
                    _totalRow('Paiements reçus', '- ${report.totalPayments.toEurosString()}',
                        PdfColor.fromHex('#388E3C')),
                    pw.Divider(color: PdfColor.fromHex('#9E9E9E'), thickness: 0.5),
                    _totalRow(
                      'RESTE À PAYER',
                      report.theoreticalBalance.toEurosString(),
                      report.theoreticalBalance.amountCents > 0
                          ? PdfColor.fromHex('#D32F2F')
                          : PdfColor.fromHex('#388E3C'),
                      bold: true,
                      fontSize: 14,
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Legal mention
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Facture payable à réception. En cas de retard de paiement, des pénalités de retard seront appliquées conformément à la législation en vigueur.',
              style: pw.TextStyle(fontSize: 8, color: subtleText),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _buildFooter(
    pw.Context ctx, {
    required PdfColor subtleText,
    required String invoiceNumber,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColor.fromHex('#C5CAE9')),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Facture N° $invoiceNumber — WorkLog Pro',
                style: pw.TextStyle(fontSize: 9, color: subtleText)),
            pw.Text('Page ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 9, color: subtleText)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _header(String text, {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white)),
      );

  static pw.Widget _cell(String text, PdfColor color,
          {pw.TextAlign align = pw.TextAlign.left}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: pw.Text(text,
            textAlign: align,
            style: pw.TextStyle(fontSize: 10, color: color)),
      );

  static pw.Widget _totalRow(String label, String value, PdfColor valueColor,
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
        return 'Horaire';
      case BillingMode.half_day:
        return 'Demi-journée';
      case BillingMode.day:
        return 'Journée';
      case BillingMode.fixed_job:
        return 'Forfait';
    }
  }
}
