import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

/// Firestore implementation of [SettingsRepository], sur un document à ID
/// fixe : users/{uid}/settings/main (pas un ID variable comme les autres
/// collections — un artisan a un seul jeu de réglages).
///
/// Fine enveloppe autour de [FirestoreCloudSettingsGateway] : la logique
/// d'accès au document vit dans le gateway (réutilisée par
/// SyncingSettingsRepository, F-SETTINGS.5), ici on se contente de traduire
/// vers la surface publique SettingsRepository (absent -> Settings() par
/// défaut, comme LocalSettingsRepository).
///
/// Aucune réconciliation, aucun cache local ici : voir
/// SyncingSettingsRepository (F-SETTINGS.5+) pour la logique
/// local-d'abord / cloud-vide-jamais-écrasé.
class FirestoreSettingsRepository implements SettingsRepository {
  final CloudSettingsGateway _gateway;

  FirestoreSettingsRepository({required String uid, FirebaseFirestore? firestore})
      : _gateway = FirestoreCloudSettingsGateway(uid: uid, firestore: firestore);

  @override
  Future<Settings> loadSettings() async => (await _gateway.fetch()).settings;

  @override
  Future<void> saveSettings(Settings settings) => _gateway.push(settings);

  @override
  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(pdfHeader: header));
  }
}
