import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

/// Contrat interne (pas la surface publique SettingsRepository) utilisé par
/// SyncingSettingsRepository pour distinguer un cloud vide d'un cloud
/// injoignable — la même distinction que LocalSettingsStatus côté local,
/// côté cloud cette fois. Un état explicite, jamais un Settings? nullable
/// où null pourrait vouloir dire "absent" ou "erreur".
enum CloudSettingsStatus { absent, loaded }

class CloudSettingsSnapshot {
  final Settings settings;
  final CloudSettingsStatus status;

  const CloudSettingsSnapshot({required this.settings, required this.status});
}

/// fetch()/push() doivent propager toute erreur (réseau, permissions,
/// timeout) telle quelle — SyncingSettingsRepository est seul responsable
/// de décider quoi faire d'un échec. Ce contrat ne doit JAMAIS avaler une
/// erreur en la transformant en CloudSettingsStatus.absent : seul un
/// DocumentSnapshot avec exists == false confirme un cloud vide.
abstract class CloudSettingsGateway {
  Future<CloudSettingsSnapshot> fetch();
  Future<void> push(Settings settings);
}

/// Implémentation réelle, sur users/{uid}/settings/main (ID fixe : un
/// artisan a un seul jeu de réglages, pas un ID variable comme les autres
/// collections).
class FirestoreCloudSettingsGateway implements CloudSettingsGateway {
  final FirebaseFirestore _firestore;
  final String _uid;

  FirestoreCloudSettingsGateway({required String uid, FirebaseFirestore? firestore})
      : _uid = uid,
        _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _docRef() =>
      _firestore.collection('users').doc(_uid).collection('settings').doc('main');

  @override
  Future<CloudSettingsSnapshot> fetch() async {
    final snapshot = await _docRef().get();
    if (!snapshot.exists) {
      return const CloudSettingsSnapshot(settings: Settings(), status: CloudSettingsStatus.absent);
    }
    return CloudSettingsSnapshot(
      settings: Settings.fromJson(snapshot.data()!),
      status: CloudSettingsStatus.loaded,
    );
  }

  @override
  Future<void> push(Settings settings) async {
    await _docRef().set(settings.toJson());
  }
}
