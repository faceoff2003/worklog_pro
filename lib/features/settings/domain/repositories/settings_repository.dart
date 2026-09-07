import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

/// Contrat public pour la persistance des réglages.
///
/// Signature inchangée depuis avant F-SETTINGS : SettingsNotifier et
/// SettingsPage ne connaissent que cette interface, jamais l'implémentation
/// concrète (locale, cloud, ou synchronisée).
abstract class SettingsRepository {
  Future<Settings> loadSettings();
  Future<void> saveSettings(Settings settings);
  Future<void> updatePdfHeader(PdfHeader header);
}
