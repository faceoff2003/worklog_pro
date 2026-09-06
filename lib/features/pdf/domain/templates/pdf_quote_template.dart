import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/core/constants/enums.dart';

/// Template Devis (Quotation)
class PdfQuoteTemplate {
  static pw.Document build({
    required ReportData report,
    Client? client,
    Project? project,
    required String quoteNumber,
    String? companyName,
    String? companySiret,
    String? companyPhone,
    String? companyEmail,
    pw.ThemeData? theme,
  }) {
    final doc = pw.Document(theme: theme);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final quoteDate = dateFormat.format(DateTime.now());
    final validUntil = dateFormat.format(DateTime.now().add(const Duration(days: 30)));

    final headerColor = PdfColor.fromHex('#1B5E20');
    final accentColor = PdfColor.fromHex('#388E3C');
    final lightBg = PdfColor.fromHex('#E8F5E9');
    final darkText = PdfColor.fromHex('#212121');
    final subtleText = PdfColor.fromHex('#757575');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (ctx) => _buildFooter(ctx, subtleText: subtleText, quoteNumber: quoteNumber),
        build: (ctx) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'DEVIS',
                    style: pw.TextStyle(
                      fontSize: 28,
                      fontWeight: pw.FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                  pw.Text('N° $quoteNumber',
                      style: pw.TextStyle(fontSize: 14, color: darkText)),
                  pw.SizedBox(height: 4),
                  pw.Text('Date : $quoteDate',
                      style: pw.TextStyle(fontSize: 11, color: darkText)),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'Valable jusqu\'au $validUntil',
                      style: pw.TextStyle(fontSize: 10, color: accentColor, fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),

          // Client info
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
                  pw.Text('DEVIS ÉTABLI POUR',
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
                    pw.Text('Objet: ${project.label}',
                        style: pw.TextStyle(
                            fontSize: 10,
                            color: accentColor,
                            fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
          pw.SizedBox(height: 20),

          // Quote lines table
          pw.Text('Détail des Prestations Estimées',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: accentColor)),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(
              color: PdfColor.fromHex('#A5D6A7'),
              width: 0.5,
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerColor),
                children: [
                  _header('Description'),
                  _header('Mode', align: pw.TextAlign.center),
                  _header('Durée', align: pw.TextAlign.center),
                  _header('Prix HT', align: pw.TextAlign.right),
                ],
              ),
              ...report.workEntries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F1F8E9');
                String taskLabel;
                if (e.notes != null && e.notes!.trim().isNotEmpty) {
                  taskLabel = e.notes!.trim();
                } else if (project != null) {
                  taskLabel = project.label;
                } else if (e.tasks.isNotEmpty) {
                  taskLabel = e.tasks.join(', ');
                } else {
                  taskLabel = 'Prestation ${_billingLabel(e.billingMode)}';
                }
                final hours = e.durationMinutes ~/ 60;
                final mins = e.durationMinutes % 60;
                final duration = hours > 0
                    ? '${hours}h${mins.toString().padLeft(2, '0')}'
                    : '${mins}min';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell(taskLabel, darkText),
                    _cell(_billingLabel(e.billingMode), darkText, align: pw.TextAlign.center),
                    _cell(duration, darkText, align: pw.TextAlign.center),
                    _cell(e.laborAmountHT.toEurosString(), darkText, align: pw.TextAlign.right),
                  ],
                );
              }),
              ...report.expenses.where((e) => e.isBillable).toList().asMap().entries.map((entry) {
                final i = entry.key + report.workEntries.length;
                final e = entry.value;
                final bg = i.isEven ? PdfColors.white : PdfColor.fromHex('#F1F8E9');
                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: bg),
                  children: [
                    _cell(e.description, darkText),
                    _cell('Matériel', darkText, align: pw.TextAlign.center),
                    _cell('—', darkText, align: pw.TextAlign.center),
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
                width: 240,
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(color: accentColor, width: 0.5),
                ),
                child: pw.Column(
                  children: [
                    _totalRow('Main d\'œuvre HT', report.totalLaborAmount.toEurosString(), darkText),
                    if (report.totalTravelAmount.amountCents > 0)
                      _totalRow('Frais de déplacement HT', report.totalTravelAmount.toEurosString(), darkText),
                    _totalRow('Matériaux HT', report.totalBillableExpenses.toEurosString(), darkText),
                    pw.Divider(color: accentColor, thickness: 0.5),
                    _totalRow('TOTAL HT', report.totalProduction.toEurosString(), accentColor,
                        bold: true, fontSize: 13),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 30),

          // Signature area
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Signature du Client',
                      style: pw.TextStyle(fontSize: 10, color: subtleText)),
                  pw.SizedBox(height: 4),
                  pw.Text('Bon pour accord',
                      style: pw.TextStyle(
                          fontSize: 10, color: darkText, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 50),
                  pw.Container(width: 150, height: 0.5, color: PdfColor.fromHex('#BDBDBD')),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Date et Signature',
                      style: pw.TextStyle(fontSize: 10, color: subtleText)),
                  pw.SizedBox(height: 50),
                  pw.Container(width: 150, height: 0.5, color: PdfColor.fromHex('#BDBDBD')),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Legal mention
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColor.fromHex('#E0E0E0'), width: 0.5),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Ce devis est établi sans engagement et reste valable 30 jours à compter de sa date d\'émission. Tout commencement de travaux vaut acceptation tacite du devis. Devis non contractuel.',
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
    required String quoteNumber,
  }) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColor.fromHex('#A5D6A7')),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Devis N° $quoteNumber — WorkLog Pro',
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
                fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
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
