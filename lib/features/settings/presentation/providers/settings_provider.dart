import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((_) => LocalSettingsRepository());

/// Notifier that holds Settings state and persists changes
class SettingsNotifier extends AsyncNotifier<Settings> {
  late final SettingsRepository _repository;

  @override
  Future<Settings> build() async {
    _repository = ref.read(settingsRepositoryProvider);
    return _repository.loadSettings();
  }

  Future<void> updateSettings(Settings settings) async {
    await _repository.saveSettings(settings);
    state = AsyncData(settings);
  }

  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(pdfHeader: header);
    await updateSettings(updated);
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
