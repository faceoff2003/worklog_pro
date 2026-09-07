import 'dart:async';

import 'package:worklog_pro/features/settings/data/repositories/cloud_settings_gateway.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';
import 'package:worklog_pro/features/settings/domain/repositories/settings_repository.dart';

/// Combine LocalSettingsRepository (source de vérité immédiate, jamais
/// bloquante) et un CloudSettingsGateway (secondaire, best-effort en
/// écriture, réconcilié en tâche de fond en lecture).
///
/// RÈGLE ABSOLUE : seul un CloudSettingsSnapshot avec status == absent
/// confirme un cloud vide. Une exception ou un timeout sur fetch() ne le
/// confirme JAMAIS et ne doit jamais déclencher d'écriture (locale ou
/// cloud) — voir _reconcile(), tout est sous un seul try/catch qui ne fait
/// rien de plus en cas d'échec.
///
/// Arbre de réconciliation (local d'abord, cloud absent -> push ; sinon
/// l'updatedAt le plus récent gagne ; corrupted ne pousse jamais, seul le
/// cloud peut le sauver) :
///   absent   + cloud vide     -> push local
///   loaded   + cloud vide     -> push local
///   absent/loaded + cloud plein -> updatedAt le plus récent gagne
///     (absent => Settings().updatedAt == null == "le plus vieux possible",
///     donc le cloud gagne toujours face à un absent, cohérent avec "on ne
///     pousse jamais par-dessus un cloud déjà peuplé sans comparer")
///   corrupted + cloud plein   -> cloud vers local, recoveredSettings, JAMAIS de push
///   corrupted + cloud vide    -> rien du tout
class SyncingSettingsRepository implements SettingsRepository {
  final LocalSettingsRepository _local;
  final CloudSettingsGateway _cloud;
  final Duration _reconciliationTimeout;

  Future<void>? _reconciliationFuture;
  Settings? _recoveredSettings;
  bool _recoveryFailed = false;

  SyncingSettingsRepository({
    required LocalSettingsRepository local,
    required CloudSettingsGateway cloud,
    Duration reconciliationTimeout = const Duration(seconds: 4),
  })  : _local = local,
        _cloud = cloud,
        _reconciliationTimeout = reconciliationTimeout;

  /// true si la branche corrupted n'a pas pu confirmer l'état du cloud dans
  /// le délai imparti (hors ligne, ou trop lent) : les réglages retournés
  /// par loadSettings() sont alors les valeurs par défaut, potentiellement
  /// fausses par rapport à ce que l'utilisateur avait réellement configuré.
  /// Usage prévu : un provider séparé côté UI (F-SETTINGS.6+), jamais en
  /// changeant le type de retour de loadSettings().
  bool get recoveryFailed => _recoveryFailed;

  @override
  Future<Settings> loadSettings() async {
    final localSnapshot = await _local.loadWithStatus();
    _reconciliationFuture ??= _reconcile(localSnapshot);

    if (localSnapshot.status != LocalSettingsStatus.corrupted) {
      // absent/loaded : jamais bloquant, la réconciliation continue derrière.
      return localSnapshot.settings;
    }

    // corrupted : on ne sait pas si "Settings() par défaut" est correct ou
    // masque une vraie corruption — on attend une réponse du cloud, borné.
    try {
      await _reconciliationFuture!.timeout(_reconciliationTimeout);
    } on TimeoutException {
      _recoveryFailed = true;
    }
    return _recoveredSettings ?? const Settings();
  }

  @override
  Future<void> saveSettings(Settings settings) async {
    // Stamp inconditionnel : toute sauvegarde publique représente une
    // modification qui a lieu MAINTENANT, quel que soit l'updatedAt que
    // l'appelant a pu transmettre (souvent une valeur inchangée depuis le
    // dernier chargement, via copyWith(champ: nouvelleValeur)). Avant ce
    // fix, seul _withTimestampIfMissing() posait un stamp, et uniquement
    // si null — donc jamais sur un objet qui avait déjà un updatedAt réel
    // (reçu du cloud via la réconciliation), figeant l'arbitrage
    // "le plus récent gagne" dès la première synchronisation.
    //
    // Un seul objet stampé, réutilisé pour le local ET le cloud : les deux
    // doivent toujours porter le même updatedAt, jamais deux
    // DateTime.now() indépendants qui pourraient diverger de quelques
    // millisecondes et fausser une comparaison ultérieure.
    final stamped = settings.copyWith(updatedAt: DateTime.now());
    await _local.saveSettings(stamped);
    try {
      await _cloud.push(stamped);
    } catch (_) {
      // best-effort : une écriture locale réussie ne doit jamais échouer à
      // cause d'un problème réseau côté cloud.
    }
  }

  @override
  Future<void> updatePdfHeader(PdfHeader header) async {
    final current = await loadSettings();
    await saveSettings(current.copyWith(pdfHeader: header));
  }

  Future<void> _reconcile(LocalSettingsSnapshot localSnapshot) async {
    try {
      final cloudSnapshot = await _cloud.fetch();

      if (localSnapshot.status == LocalSettingsStatus.corrupted) {
        if (cloudSnapshot.status == CloudSettingsStatus.loaded) {
          await _local.saveSettings(cloudSnapshot.settings);
          _recoveredSettings = cloudSnapshot.settings;
        }
        // cloud vide : rien du tout, jamais de push depuis corrupted.
        return;
      }

      if (cloudSnapshot.status == CloudSettingsStatus.absent) {
        await _cloud.push(_withTimestampIfMissing(localSnapshot.settings));
        return;
      }

      final cmp = _compareRecency(localSnapshot.settings, cloudSnapshot.settings);
      if (cmp > 0) {
        await _cloud.push(_withTimestampIfMissing(localSnapshot.settings));
      } else if (cmp < 0) {
        await _local.saveSettings(cloudSnapshot.settings);
      }
      // cmp == 0 : égalité (ou les deux null), on ne touche à rien.
    } catch (_) {
      // fetch()/push()/saveSettings() en échec (réseau, permissions...) :
      // on ne touche à rien de plus, ni local ni cloud (règle absolue).
      if (localSnapshot.status == LocalSettingsStatus.corrupted && _recoveredSettings == null) {
        _recoveryFailed = true;
      }
    }
  }

  Settings _withTimestampIfMissing(Settings settings) =>
      settings.updatedAt == null ? settings.copyWith(updatedAt: DateTime.now()) : settings;

  DateTime _effectiveTimestamp(DateTime? t) => t ?? DateTime.fromMillisecondsSinceEpoch(0);

  int _compareRecency(Settings a, Settings b) =>
      _effectiveTimestamp(a.updatedAt).compareTo(_effectiveTimestamp(b.updatedAt));
}
