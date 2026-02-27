import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/pdf/domain/templates/pdf_fonts.dart';
import 'package:worklog_pro/features/pdf/domain/templates/pdf_invoice_template.dart';
import 'package:worklog_pro/features/pdf/domain/templates/pdf_quote_template.dart';
import 'package:worklog_pro/features/pdf/domain/templates/pdf_simple_template.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';

/// Fournisseur Riverpod pour injecter le [PdfService].
final pdfServiceProvider = Provider<PdfService>((ref) => PdfService());

/// Types de documents PDF générables par l'application.
enum PdfTemplate { simple, invoice, quote }

/// Service en charge de la génération visuelle des documents PDF.
///
/// Il charge les polices compatibles avec l'Euro et les accents (Roboto),
/// puis orchestre la création des pages et composants via la bibliothèque `pdf`.
class PdfService {
  /// Charge la police Roboto (format UTF-8) depuis les assets locaux.
  /// 
  /// Indispensable pour l'affichage correct des caractères spéciaux comme 
  /// l'Euro (€) ou les lettres accentuées françaises (é, à, etc.).
  Future<pw.ThemeData> _loadTheme() async {
    await PdfFonts.load();
    return pw.ThemeData.withFont(
      base: PdfFonts.regular,
      bold: PdfFonts.bold,
      italic: PdfFonts.italic,
      boldItalic: PdfFonts.bold,
    );
  }

  /// Génère un rapport d'activité simple (résumé interne ou pour le client sans valeur fiscale).
  ///
  /// Retourne un tableau d'octets ([Uint8List]) représentant le fichier PDF complet.
  Future<Uint8List> generateSimplePdf({
    required ReportData report,
    Client? client,
    Project? project,
  }) async {
    final theme = await _loadTheme();
    final doc = PdfSimpleTemplate.build(
      report: report,
      client: client,
      project: project,
      theme: theme,
    );
    return doc.save();
  }

  /// Génère une facture professionnelle aux normes ([Invoice]).
  /// 
  /// Le numéro de la facture contiendra le préfixe "F" généré automatiquement.
  Future<Uint8List> generateInvoicePdf({
    required ReportData report,
    Client? client,
    Project? project,
    String? companyName,
    String? companySiret,
    String? companyPhone,
    String? companyEmail,
  }) async {
    final theme = await _loadTheme();
    final invoiceNumber = _generateDocNumber('F');
    final doc = PdfInvoiceTemplate.build(
      report: report,
      client: client,
      project: project,
      invoiceNumber: invoiceNumber,
      companyName: companyName,
      companySiret: companySiret,
      companyPhone: companyPhone,
      companyEmail: companyEmail,
      theme: theme,
    );
    return doc.save();
  }

  /// Generates a quote (devis) PDF
  Future<Uint8List> generateQuotePdf({
    required ReportData report,
    Client? client,
    Project? project,
    String? companyName,
    String? companySiret,
    String? companyPhone,
    String? companyEmail,
  }) async {
    final theme = await _loadTheme();
    final quoteNumber = _generateDocNumber('D');
    final doc = PdfQuoteTemplate.build(
      report: report,
      client: client,
      project: project,
      quoteNumber: quoteNumber,
      companyName: companyName,
      companySiret: companySiret,
      companyPhone: companyPhone,
      companyEmail: companyEmail,
      theme: theme,
    );
    return doc.save();
  }

  /// Generates a document number like F-2025-001
  String _generateDocNumber(String prefix) {
    final now = DateTime.now();
    final ts = DateFormat('yyyyMMdd-HHmm').format(now);
    return '$prefix-$ts';
  }

  /// Returns the suggested filename for a PDF
  String getFileName({required PdfTemplate template, String? clientName}) {
    final DateFormat fmt = DateFormat('yyyy-MM-dd');
    final date = fmt.format(DateTime.now());
    final client = clientName?.replaceAll(' ', '_') ?? 'client';
    switch (template) {
      case PdfTemplate.simple:
        return 'recap_${client}_$date.pdf';
      case PdfTemplate.invoice:
        return 'facture_${client}_$date.pdf';
      case PdfTemplate.quote:
        return 'devis_${client}_$date.pdf';
    }
  }
}
