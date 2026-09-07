import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

/// Firestore implementation of [SettingsRepository], sur un document à ID
/// fixe : users/{uid}/settings/main (pas un ID variable comme les autres
/// collections — un artisan a un seul jeu de réglages).
///
/// Aucune réconciliation, aucun cache local ici : voir
/// SyncingSettingsRepository (F-SETTINGS.5+) pour la logique
/// local-d'abord / cloud-vide-jamais-écrasé.
class FirestoreSettingsRepository implements SettingsRepository {
  final FirebaseFirestore _firestore;
  final String _uid;

  FirestoreSettingsRepository({required String uid, FirebaseFirestore? firestore})
      : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _docRef() =>
      _firestore.collection('users').doc(_uid).collection('settings').doc('main');

  @override
  Future<Settings> loadSettings() async {
    final snapshot = await _docRef().get();
    if (!snapshot.exists) return const Settings();
    return Settings.fromJson(snapshot.data()!);
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    await _docRef().set(settings.toJson());
  }

  @override
  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(pdfHeader: header));
  }
}
