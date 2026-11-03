import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/reports/domain/services/excel_export_service.dart';

ReportData _report(int carry) => ReportData(
      totalLaborAmount: Money.fromCents(1000),
      totalTravelAmount: Money.zero,
      totalBillableExpenses: Money.zero,
      totalNonBillableExpenses: Money.zero,
      totalPayments: Money.fromCents(400),
      workEntries: const [],
      expenses: const [],
      payments: const [],
      dateRange: DateTimeRange(start: DateTime(2026, 3, 1), end: DateTime(2026, 3, 31)),
      carriedOverAmount: Money.fromCents(carry),
    );

Future<Map<String, double>> _summary(ReportData report) async {
  final bytes = await ExcelExportService().generateExcel(report);
  final sheet = Excel.decodeBytes(bytes)['Résumé'];
  // Relu depuis le fichier, un double entier (6.0) revient en IntCellValue.
  double? number(CellValue? v) => v is DoubleCellValue ? v.value : v is IntCellValue ? v.value.toDouble() : null;
  return {
    for (final row in sheet.rows)
      if (row.length > 1 && row[0]?.value is TextCellValue && number(row[1]?.value) != null)
        (row[0]!.value as TextCellValue).value.text!: number(row[1]?.value)!,
  };
}

void main() {
  test('report non nul : ligne « Report à nouveau », reste à percevoir qui l\'inclut', () async {
    final rows = await _summary(_report(-250));
    expect(rows['Report à nouveau'], -2.5);
    expect(rows['Reste à Percevoir'], 3.5);
  });

  test('report nul : pas de ligne', () async {
    final rows = await _summary(_report(0));
    expect(rows.containsKey('Report à nouveau'), isFalse);
    expect(rows['Reste à Percevoir'], 6.0);
  });
}
