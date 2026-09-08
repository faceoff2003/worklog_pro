import 'dart:developer' as dev;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:worklog_pro/features/clients/domain/repositories/client_repository.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Décide QUOI mirrorer et OÙ, appelé par WorkEntryRepositoryImpl et
/// ExpenseRepositoryImpl après leur écriture réelle — jamais avant, jamais à
/// la place. Toute méthode ici est best-effort : une exception (client
/// introuvable, pas de portail, écriture cloud échouée) est avalée, jamais
/// propagée. Le miroir ne doit JAMAIS faire échouer l'enregistrement réel
/// d'une prestation ou d'une dépense pour l'artisan.
///
/// Un ajout raté (mirrorWorkEntry, ou mirrorExpense avec isBillable == true)
/// est silencieux : la pire conséquence est un miroir en retard d'une
/// écriture, sans rien exposer. Un RETRAIT raté (removeMirrored*, ou
/// mirrorExpense avec isBillable == false) laisse au contraire une donnée
/// SUPPRIMÉE ou NON REFACTURABLE toujours visible côté client — ce n'est
/// pas un détail, donc loggé (dev.log, gaté par kDebugMode, jamais
/// debugPrint — convention W-FIX1.4) même si toujours non bloquant.
class ClientPortalMirrorService {
  final ClientRepository _clientRepository;
  final ClientPortalRepository _clientPortalRepository;
  final void Function(String message) _logRemovalFailure;

  ClientPortalMirrorService({
    required ClientRepository clientRepository,
    required ClientPortalRepository clientPortalRepository,
    void Function(String message)? logRemovalFailure,
  })  : _clientRepository = clientRepository,
        _clientPortalRepository = clientPortalRepository,
        _logRemovalFailure = logRemovalFailure ?? _defaultLogRemovalFailure;

  static void _defaultLogRemovalFailure(String message) {
    if (kDebugMode) {
      dev.log(message, name: 'ClientPortalMirror');
    }
  }

  Future<void> mirrorWorkEntry(WorkEntry entry) => _guardedAdd(() async {
        final portalUid = await _portalUidFor(entry.clientId);
        if (portalUid == null) return;
        await _clientPortalRepository.mirrorWorkEntry(portalUid, entry);
      });

  Future<void> removeMirroredWorkEntry({required String clientId, required String entryId}) => _guardedRemove(
        description: 'workEntry $entryId (client $clientId)',
        action: () async {
          final portalUid = await _portalUidFor(clientId);
          if (portalUid == null) return;
          await _clientPortalRepository.deleteMirroredWorkEntry(portalUid, entryId);
        },
      );

  /// N'écrit jamais une dépense non refacturable — la retire du miroir si
  /// elle y était (le cas où isBillable bascule de true à false sur une
  /// dépense déjà mirrorée). Ce chemin est un RETRAIT : loggé s'il échoue,
  /// contrairement au chemin isBillable == true.
  Future<void> mirrorExpense(Expense expense) {
    if (!expense.isBillable) {
      return _guardedRemove(
        description: 'expense ${expense.id} (isBillable=false, client ${expense.clientId})',
        action: () async {
          final portalUid = await _portalUidFor(expense.clientId);
          if (portalUid == null) return;
          await _clientPortalRepository.deleteMirroredExpense(portalUid, expense.id);
        },
      );
    }
    return _guardedAdd(() async {
      final portalUid = await _portalUidFor(expense.clientId);
      if (portalUid == null) return;
      await _clientPortalRepository.mirrorExpense(portalUid, expense);
    });
  }

  Future<void> removeMirroredExpense({required String clientId, required String expenseId}) => _guardedRemove(
        description: 'expense $expenseId (client $clientId)',
        action: () async {
          final portalUid = await _portalUidFor(clientId);
          if (portalUid == null) return;
          await _clientPortalRepository.deleteMirroredExpense(portalUid, expenseId);
        },
      );

  Future<String?> _portalUidFor(String clientId) async {
    final client = await _clientRepository.getClient(clientId);
    return client?.portalUid;
  }

  Future<void> _guardedAdd(Future<void> Function() action) async {
    try {
      await action();
    } catch (_) {
      // best-effort silencieux : voir le commentaire de classe.
    }
  }

  Future<void> _guardedRemove({
    required String description,
    required Future<void> Function() action,
  }) async {
    try {
      await action();
    } catch (e) {
      _logRemovalFailure('Échec du retrait du miroir : $description reste visible côté client. Erreur : $e');
    }
  }
}
