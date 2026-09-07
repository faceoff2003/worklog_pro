import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

/// Distingue les trois états possibles du cache local, là où loadSettings()
/// (interface publique) les confond tous en un seul Settings() par défaut.
///
/// Cette distinction existe pour SyncingSettingsRepository (F-SETTINGS.4+) :
/// absent → sûr à écraser avec le cloud ou à pousser vers un cloud vide ;
/// corrupted → jamais sûr à pousser, seule une lecture cloud peut récupérer.
enum LocalSettingsStatus { absent, loaded, corrupted }

class LocalSettingsSnapshot {
  final Settings settings;
  final LocalSettingsStatus status;

  const LocalSettingsSnapshot({required this.settings, required this.status});
}

/// Repository for persisting Settings using SharedPreferences
class LocalSettingsRepository implements SettingsRepository {
  static const _key = 'app_settings';

  Future<LocalSettingsSnapshot> loadWithStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) {
      return const LocalSettingsSnapshot(
        settings: Settings(),
        status: LocalSettingsStatus.absent,
      );
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return LocalSettingsSnapshot(
        settings: Settings.fromJson(map),
        status: LocalSettingsStatus.loaded,
      );
    } catch (_) {
      return const LocalSettingsSnapshot(
        settings: Settings(),
        status: LocalSettingsStatus.corrupted,
      );
    }
  }

  @override
  Future<Settings> loadSettings() async => (await loadWithStatus()).settings;

  @override
  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(settings.toJson());
    await prefs.setString(_key, jsonStr);
  }

  @override
  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(pdfHeader: header));
  }
}
