import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/reports/domain/services/excel_export_service.dart';

/// Provider pour accèder au service d'export Excel.
final excelExportServiceProvider = Provider<ExcelExportService>((ref) {
  return ExcelExportService();
});
