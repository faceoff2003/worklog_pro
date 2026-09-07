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

/// true si la branche corrupted de SyncingSettingsRepository n'a pas pu
/// confirmer l'état du cloud dans le délai imparti (hors ligne, ou trop
/// lent) : les réglages affichés sont alors les valeurs par défaut,
/// potentiellement fausses par rapport à ce que l'artisan avait réellement
/// configuré.
///
/// Provider séparé plutôt qu'un champ sur Settings/settingsProvider : ça
/// évite de changer le type de retour de loadSettings() (qui cascaderait
/// dans SettingsNotifier et SettingsPage).
///
/// Réactivité : recoveryFailed est un simple bool mutable sur le
/// repository, pas un flux — un Provider qui le lirait une seule fois à sa
/// création ne se réévaluerait jamais. On force la réévaluation en
/// watchant settingsProvider : loadSettings() (sur la branche corrupted) ne
/// RETOURNE qu'une fois recoveryFailed définitivement fixé (succès dans le
/// délai, ou timeout), donc la transition AsyncLoading -> AsyncData de
/// settingsProvider — qui notifie toujours ses watchers, première
/// résolution d'un AsyncNotifier — arrive exactement au moment où la
/// valeur est stable. Aucun flux introduit : settingsProvider ne change
/// que sur des actions explicites (build() une fois, updateSettings()),
/// jamais un ticker de fond qui changerait l'état sous les doigts de
/// l'utilisateur en train de taper.
///
/// Limite connue : si la réconciliation en arrière-plan continue après le
/// timeout et finit par réussir plus tard, rien ne rafraîchit
/// settingsProvider a posteriori — le bandeau resterait affiché même si
/// les données ont fini par être récupérées. Gap préexistant du design
/// (aucune re-notification après coup n'a jamais été prévue), pas propre à
/// ce provider.
final settingsRecoveryFailedProvider = Provider<bool>((ref) {
  ref.watch(settingsProvider);
  final repository = ref.watch(settingsRepositoryProvider);
  return repository is SyncingSettingsRepository && repository.recoveryFailed;
});
