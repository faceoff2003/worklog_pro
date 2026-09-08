import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Accès en LECTURE SEULE au miroir clientPortals/{monUid}/... — côté
/// CLIENT, jamais côté artisan (voir ClientPortalRepository pour l'écriture
/// du miroir).
///
/// Aucune méthode ne prend de portalUid en paramètre, délibérément :
/// l'implémentation dérive toujours son propre uid au constructeur, sourcé
/// par le provider depuis la session authentifiée — jamais depuis un
/// widget, jamais depuis un argument. Un appelant ne peut donc
/// structurellement pas demander le miroir de quelqu'un d'autre ; les
/// rules (isOwner(portalUid) && isPortalEnabled(portalUid)) restent le
/// filet de dernier recours, pas la seule garantie.
abstract class ClientMirrorRepository {
  Stream<List<WorkEntry>> watchMyWorkEntries();
}
