import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';

/// Service métier dédié aux calculs liés au temps de travail et à la facturation.
///
/// Contrairement aux modèles de données, ce service pur (sans état) contient
/// l'intelligence d'application : comment le temps est arrondi, comment
/// la durée est transformée en argent, etc.
class WorkCalculatorService {
  /// Calcule la durée effective de travail en minutes.
  ///
  /// [startTime] et [endTime] sont exprimés en minutes écoulées depuis minuit.
  /// Le [pauseMinutes] est soustrait du total.
  /// Si la fin est avant le début (changement de jour non géré pour l'instant),
  /// retourne 0 par sécurité.
  int calculateDuration(int startTime, int endTime, {int pauseMinutes = 0}) {
    if (endTime < startTime) {
      // Handle overnight? For now assume same day or error.
      // If end < start, maybe it's next day? 
      // Let's assume standard single day entry for now.
      return 0; 
    }
    return (endTime - startTime) - pauseMinutes;
  }

  /// Arrondit la durée de travail à un intervalle précis.
  /// 
  /// Par exemple, pour facturer au quart d'heure près ([step] = 15).
  /// Si [roundUp] est vrai, toute minute entamée dans le palier comptera
  /// pour un palier entier (avantage à l'artisan). Sinon, arrondit au plus proche.
  int roundDuration(int durationMinutes, int step, {bool roundUp = false}) {
    if (step <= 1) return durationMinutes;
    
    if (roundUp) {
      return ((durationMinutes + step - 1) ~/ step) * step;
    } else {
      return ((durationMinutes + step / 2) ~/ step) * step;
    }
  }

  /// Calcule le coût final de la main d'œuvre en fonction du temps et du mode de facturation.
  ///
  /// Le calcul prend en compte :
  /// 1. Le temps passé [durationMinutes]
  /// 2. Le mode de facturation ([BillingMode.hourly], [BillingMode.day], etc.)
  /// 3. Les tarifs convenus avec le client ([DefaultRates])
  /// 4. L'arrondi du temps choisi pour la facturation ([roundingStep])
  Money calculateLaborCost({
    required int durationMinutes,
    required BillingMode mode,
    required DefaultRates rates,
    required int roundingStep,
  }) {
    // 1. Round duration first for calculation?
    // Usually we bill based on rounded duration.
    final roundedDuration = roundDuration(durationMinutes, roundingStep, roundUp: true); // Default to round up for billing
    
    switch (mode) {
      case BillingMode.hourly:
        final hourlyRate = rates.hour ?? Money.zero;
        if (hourlyRate == Money.zero) return Money.zero;
        
        final hours = roundedDuration / 60.0;
        return hourlyRate * hours;
        
      case BillingMode.half_day:
        return rates.halfDay ?? Money.zero;
        
      case BillingMode.day:
        return rates.day ?? Money.zero;
        
      case BillingMode.fixed_job:
        // For fixed job, usually the rate is entered manually per job, 
        // but if we use default rate:
        return rates.fixedJob ?? Money.zero;
    }
  }

  /// Formate des minutes cumulées en chaîne de caractères (ex: 480 -> "08:00").
  ///
  /// Pratique pour faire le pont entre la base de données (int) et l'interface utilisateur.
  String formatTime(int minutesFromMidnight) {
    if (minutesFromMidnight < 0) return '00:00';
    final h = minutesFromMidnight ~/ 60;
    final m = minutesFromMidnight % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Transforme une chaîne de temps "HH:mm" en minutes écoulées depuis minuit.
  ///
  /// Utile lors de la saisie manuelle de l'heure par l'utilisateur.
  int parseTime(String timeString) {
    // Expected format HH:mm
    final parts = timeString.split(':');
    if (parts.length != 2) return 0;
    
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    
    return (h * 60) + m;
  }
}
