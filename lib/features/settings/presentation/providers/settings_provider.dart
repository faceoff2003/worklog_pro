import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/data/repositories/syncing_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

// Comme workEntryRepositoryProvider / clientRepositoryProvider /
// expenseRepositoryProvider / projectRepositoryProvider : ce provider ne
// renvoie un repository qu'avec un uid non nul, donc users/null/... n'est
// jamais construit. Sûr en pratique : AuthWrapper ne monte HomePage (et donc
// n'importe quelle page consommant settingsProvider) que quand
// authState.value != null ; un utilisateur non connecté ne voit que
// LoginPage, qui ne touche jamais aux réglages.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user == null) {
    throw Exception('User must be authenticated to access SettingsRepository');
  }
  return SyncingSettingsRepository(
    local: LocalSettingsRepository(),
    cloud: FirestoreCloudSettingsGateway(uid: user.uid),
  );
});

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
