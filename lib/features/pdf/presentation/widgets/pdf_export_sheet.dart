import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:worklog_pro/core/services/google_drive_service.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/pdf/domain/services/pdf_service.dart';
import 'package:worklog_pro/features/projects/domain/entities/project.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/settings/presentation/providers/settings_provider.dart';

/// Bottom sheet to pick PDF template and trigger generation
class PdfExportSheet extends ConsumerStatefulWidget {
  final ReportData report;
  final Client? client;
  final Project? project;

  const PdfExportSheet({
    super.key,
    required this.report,
    this.client,
    this.project,
  });

  @override
  ConsumerState<PdfExportSheet> createState() => _PdfExportSheetState();
}

class _PdfExportSheetState extends ConsumerState<PdfExportSheet> {
  bool _isGenerating = false;

  // Generate PDF and open the print/preview dialog (existing behavior)
  Future<void> _generate(PdfTemplate template) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _buildPdfBytes(template);
      final service = ref.read(pdfServiceProvider);
      final fileName = service.getFileName(
        template: template,
        clientName: widget.client?.name,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await Printing.layoutPdf(
        onLayout: (_) async => pdfBytes,
        name: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Generate PDF and share via WhatsApp / any app
  Future<void> _share(PdfTemplate template) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _buildPdfBytes(template);
      final service = ref.read(pdfServiceProvider);
      final fileName = service.getFileName(
        template: template,
        clientName: widget.client?.name,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      if (!mounted) return;
      Navigator.of(context).pop();
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/pdf')],
        subject: fileName,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur partage: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Generate PDF and upload to Google Drive
  Future<void> _saveToDrive(PdfTemplate template) async {
    setState(() => _isGenerating = true);
    try {
      final pdfBytes = await _buildPdfBytes(template);
      final pdfService = ref.read(pdfServiceProvider);
      final fileName = pdfService.getFileName(
        template: template,
        clientName: widget.client?.name,
      );
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      final driveService = ref.read(googleDriveServiceProvider);
      await driveService.uploadPdf(file, fileName);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF sauvegardé sur Drive ($fileName)'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur Drive: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // Common PDF bytes builder
  Future<Uint8List> _buildPdfBytes(PdfTemplate template) async {
    final service = ref.read(pdfServiceProvider);
    final settings = ref.read(settingsProvider).valueOrNull;
    final header = settings?.pdfHeader;
    return switch (template) {
      PdfTemplate.simple => await service.generateSimplePdf(
          report: widget.report,
          client: widget.client,
          project: widget.project,
        ),
      PdfTemplate.invoice => await service.generateInvoicePdf(
          report: widget.report,
          client: widget.client,
          project: widget.project,
          companyName: header?.name.isNotEmpty == true ? header!.name : null,
          companySiret: header?.tvaNumber,
          companyPhone: header?.phone.isNotEmpty == true ? header!.phone : null,
          companyEmail: header?.email,
        ),
      PdfTemplate.quote => await service.generateQuotePdf(
          report: widget.report,
          client: widget.client,
          project: widget.project,
          companyName: header?.name.isNotEmpty == true ? header!.name : null,
          companySiret: header?.tvaNumber,
          companyPhone: header?.phone.isNotEmpty == true ? header!.phone : null,
          companyEmail: header?.email,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Exporter en PDF',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (widget.client != null) ...[
            const SizedBox(height: 4),
            Text(
              widget.client!.name + (widget.project != null ? ' — ${widget.project!.label}' : ''),
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
          const SizedBox(height: 24),

          if (_isGenerating)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Génération en cours...'),
                ],
              ),
            )
          else ...[
            _TemplateOption(
              icon: Icons.table_chart,
              iconColor: Colors.indigo,
              title: 'Récapitulatif Simple',
              subtitle: 'Tableau des prestations + totaux',
              onTap: () => _generate(PdfTemplate.simple),
              onShare: () => _share(PdfTemplate.simple),
              onDrive: () => _saveToDrive(PdfTemplate.simple),
            ),
            const SizedBox(height: 12),
            _TemplateOption(
              icon: Icons.receipt_long,
              iconColor: Colors.deepOrange,
              title: 'Facture',
              subtitle: 'Format professionnel avec N° de facture',
              onTap: () => _generate(PdfTemplate.invoice),
              onShare: () => _share(PdfTemplate.invoice),
              onDrive: () => _saveToDrive(PdfTemplate.invoice),
            ),
            const SizedBox(height: 12),
            _TemplateOption(
              icon: Icons.edit_document,
              iconColor: Colors.green,
              title: 'Devis',
              subtitle: 'Devis avec zone de signature (valable 30 jours)',
              onTap: () => _generate(PdfTemplate.quote),
              onShare: () => _share(PdfTemplate.quote),
              onDrive: () => _saveToDrive(PdfTemplate.quote),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onDrive;

  const _TemplateOption({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onShare,
    required this.onDrive,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              // Save to Drive button
              IconButton(
                onPressed: onDrive,
                icon: const Icon(Icons.cloud_upload),
                tooltip: 'Sauvegarder sur Google Drive',
                color: Colors.blue.shade600,
              ),
              // Share button (WhatsApp, email, etc.)
              IconButton(
                onPressed: onShare,
                icon: const Icon(Icons.share),
                tooltip: 'Partager (WhatsApp, email...)',
                color: Colors.green.shade600,
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
