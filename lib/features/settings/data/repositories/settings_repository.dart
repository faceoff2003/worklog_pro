import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

/// Repository for persisting Settings using SharedPreferences
class SettingsRepository {
  static const _key = 'app_settings';

  Future<Settings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_key);
    if (jsonStr == null) return const Settings();
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return Settings.fromJson(map);
    } catch (_) {
      return const Settings();
    }
  }

  Future<void> saveSettings(Settings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(settings.toJson());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(pdfHeader: header));
  }
}
