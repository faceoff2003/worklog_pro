/// Application constants
class AppConstants {
  AppConstants._();

  /// Current schema version
  static const int schemaVersion = 1;

  /// Default values
  static const int defaultDayHours = 8;
  static const int defaultHalfDayHours = 4;
  static const int defaultPauseMinutes = 0;
  static const int defaultRoundingMinutes = 15;
  static const double defaultMinBillingHours = 2.0;
  static const int defaultMinBillingAmountCents = 2500; // 25€
  static const String defaultCurrency = 'EUR';
  static const String defaultCountry = 'Belgique';
  static const int defaultTravelRatePerKmCents = 50; // 0.50€

  /// Firebase constraints
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const List<String> allowedImageTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
  static const List<String> allowedDocumentTypes = ['application/pdf'];

  /// Quick tasks library (default)
  static const List<String> defaultQuickTasks = [
    'Tirage câble',
    'Saignées',
    'Coffret / Tableau',
    'Raccordement',
    'Tests / Mesures',
    'Schéma unifilaire',
    'Schéma de position',
    'Posepises',
    'Pose interrupteurs',
    'Pose luminaires',
    'Pose goulottes / chemins de câbles',
    'Domotique',
    'Parlophone / Vidéophone',
    'Alarme',
    'Mise en conformité',
    'Dépannage',
    'Contrôle Vinçotte',
  ];

  /// Quick vendors library (default)
  static const List<String> defaultQuickVendors = [
    'Brico',
    'Cebeo',
    'Rexel',
    'Elec 44',
    'Van Marcke',
    'Autre',
  ];

  /// Rounding options (in minutes)
  static const List<int> roundingOptions = [0, 5, 10, 15, 30];

  /// Validation limits
  static const int maxClientNameLength = 200;
  static const int maxProjectLabelLength = 200;
  static const int maxTaskItemLength = 200;
  static const int maxTasksPerEntry = 50;
  static const int maxNotesLength = 5000;
  static const int maxDescriptionLength = 500;

  /// Time constraints
  static const int minTimeOfDay = 0; // 00:00
  static const int maxTimeOfDay = 1439; // 23:59
  static const int maxPauseMinutes = 600; // 10 hours

  /// Display formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String currencySymbol = '€';
}
