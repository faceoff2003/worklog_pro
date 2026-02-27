import 'package:freezed_annotation/freezed_annotation.dart';

/// Objet-Valeur (Value Object) représentant une Date pure (sans notion d'heure).
/// 
/// Dans l'application, les heures (timezone) posent souvent des problèmes
/// de décalage. Cet objet stocke de manière fiable et immuable la date
/// au format standard ISO "YYYY-MM-DD" pour une persistance parfaite dans Firestore.
@immutable
class DateOnly implements Comparable<DateOnly> {
  /// Chaîne de date formattée ISO 8601 : "YYYY-MM-DD"
  final String value;

  const DateOnly._(this.value);

  /// Crée un objet DateOnly à partir d'un objet [DateTime] natif.
  factory DateOnly.fromDateTime(DateTime dateTime) {
    final year = dateTime.year.toString().padLeft(4, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final day = dateTime.day.toString().padLeft(2, '0');
    return DateOnly._('$year-$month-$day');
  }

  /// Crée un objet DateOnly à partir d'une chaîne exacte "YYYY-MM-DD".
  factory DateOnly.fromString(String value) {
    // Validate format
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(value)) {
      throw ArgumentError('Invalid date format. Expected YYYY-MM-DD, got: $value');
    }
    
    // Validate it's a real date
    try {
      DateTime.parse(value);
    } catch (e) {
      throw ArgumentError('Invalid date: $value');
    }
    
    return DateOnly._(value);
  }

  /// Date du jour courant.
  factory DateOnly.today() => DateOnly.fromDateTime(DateTime.now());

  /// Reconvertit l'entité en objet [DateTime] natif (à minuit pile).
  DateTime toDateTime() {
    return DateTime.parse(value);
  }

  /// Year
  int get year => toDateTime().year;

  /// Month (1-12)
  int get month => toDateTime().month;

  /// Day (1-31)
  int get day => toDateTime().day;

  /// Weekday (1 = Monday, 7 = Sunday)
  int get weekday => toDateTime().weekday;

  /// Add days
  DateOnly addDays(int days) {
    final dt = toDateTime().add(Duration(days: days));
    return DateOnly.fromDateTime(dt);
  }

  /// Subtract days
  DateOnly subtractDays(int days) {
    return addDays(-days);
  }

  /// Add months
  DateOnly addMonths(int months) {
    final dt = toDateTime();
    final newMonth = dt.month + months;
    final newYear = dt.year + (newMonth - 1) ~/ 12;
    final finalMonth = ((newMonth - 1) % 12) + 1;
    
    // Handle day overflow (e.g., Jan 31 + 1 month = Feb 28/29)
    final maxDay = DateTime(newYear, finalMonth + 1, 0).day;
    final finalDay = dt.day > maxDay ? maxDay : dt.day;
    
    return DateOnly.fromDateTime(DateTime(newYear, finalMonth, finalDay));
  }

  /// Check if date is in range [from, to] (inclusive)
  bool isBetween(DateOnly from, DateOnly to) {
    return this >= from && this <= to;
  }

  /// Format as "dd/MM/yyyy"
  String formatEuropean() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Format as "15 février 2026"
  String formatLongFrench() {
    const months = [
      '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '$day ${months[month]} $year';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DateOnly && value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  bool operator <(DateOnly other) => value.compareTo(other.value) < 0;
  bool operator <=(DateOnly other) => value.compareTo(other.value) <= 0;
  bool operator >(DateOnly other) => value.compareTo(other.value) > 0;
  bool operator >=(DateOnly other) => value.compareTo(other.value) >= 0;

  @override
  int compareTo(DateOnly other) => value.compareTo(other.value);

  @override
  String toString() => value;

  /// Serialize to string for Firestore
  String toJson() => value;

  /// Deserialize from string
  factory DateOnly.fromJson(String value) => DateOnly.fromString(value);
}
