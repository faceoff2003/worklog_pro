import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/services/work_calculator_service.dart';

/// Construit un [WorkEntry] à partir des valeurs brutes saisies dans le
/// formulaire (anciennement assemblées directement dans
/// `WorkEntryFormPage._save()`).
///
/// Ne décide ni de la persistance (create vs update), ni de la navigation :
/// c'est toujours à l'appelant de fournir [id]/[createdAt] selon qu'il
/// s'agit d'une nouvelle prestation ou d'une modification.
class WorkEntryBuilderService {
  const WorkEntryBuilderService(this._calculator);

  final WorkCalculatorService _calculator;

  /// Peut lever [ArgumentError] (voir
  /// [WorkCalculatorService.calculateDuration]).
  WorkEntry build({
    required String id,
    required DateOnly date,
    required int startTime,
    required int endTime,
    required int pauseMinutes,
    required String clientId,
    String? projectId,
    required BillingMode billingMode,
    required Money laborAmountHT,
    required DefaultRates clientDefaultRates,
    required double travelDistanceKm,
    required double travelRatePerKm,
    required String notes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) {
    final duration = _calculator.calculateDuration(
      startTime,
      endTime,
      pauseMinutes: pauseMinutes,
    );

    // Aller-retour : (distance * 2) * taux.
    final travelAmountHT = Money.fromEuros((travelDistanceKm * 2) * travelRatePerKm);

    return WorkEntry(
      id: id,
      date: date,
      startTime: startTime,
      endTime: endTime,
      pauseMinutes: pauseMinutes,
      durationMinutes: duration,
      clientId: clientId,
      projectId: projectId,
      billingMode: billingMode,
      rateApplied: _unitRate(clientDefaultRates, billingMode),
      laborAmountHT: laborAmountHT,
      travelDistanceKm: travelDistanceKm,
      travelRatePerKm: travelRatePerKm,
      travelAmountHT: travelAmountHT,
      notes: notes,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Money _unitRate(DefaultRates rates, BillingMode mode) {
    switch (mode) {
      case BillingMode.hourly:
        return rates.hour ?? Money.zero;
      case BillingMode.half_day:
        return rates.halfDay ?? Money.zero;
      case BillingMode.day:
        return rates.day ?? Money.zero;
      case BillingMode.fixed_job:
        return rates.fixedJob ?? Money.zero;
    }
  }
}
