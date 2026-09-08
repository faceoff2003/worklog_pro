import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_mirror_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_mirror_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// Seul endroit qui source le uid pour ClientMirrorRepository — depuis la
/// session authentifiée, jamais depuis un widget. Voir le commentaire sur
/// ClientMirrorRepository pour pourquoi ça compte.
final clientMirrorRepositoryProvider = Provider<ClientMirrorRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('User must be authenticated to access ClientMirrorRepository');
  }
  return ClientMirrorRepositoryImpl(uid: user.uid);
});

final myWorkEntriesStreamProvider = StreamProvider<List<WorkEntry>>((ref) {
  return ref.watch(clientMirrorRepositoryProvider).watchMyWorkEntries();
});
