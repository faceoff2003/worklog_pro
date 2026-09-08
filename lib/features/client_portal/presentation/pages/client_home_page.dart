import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_mirror_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/user_role_provider.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';

/// C-PORTAL.8 — la vraie liste de prestations depuis le miroir. Trié par
/// ClientMirrorRepositoryImpl (date décroissante, stable) : aucun tri ici.
class ClientHomePage extends ConsumerStatefulWidget {
  const ClientHomePage({super.key});

  @override
  ConsumerState<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends ConsumerState<ClientHomePage> {
  // Garde anti-boucle — vérifié empiriquement le 2026-09-09, pas supposé :
  // sans elle, chaque permission-denied consécutif sur le flux (le SDK
  // retente, échoue à nouveau) redéclenche une réinvalidation de
  // userPortalProvider, sans borne (1 -> 2 -> 3 -> 4... un appel getPortal()
  // par échec, mesuré sur un test qui enchaîne plusieurs permission-denied).
  // Une seule réinvalidation tant que l'erreur persiste ; réarmée dès que le
  // flux revient à un état non-erreur (recovery, ou nouvelle déconnexion).
  bool _hasReinvalidatedForCurrentError = false;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(myWorkEntriesStreamProvider);

    ref.listen<AsyncValue<List<WorkEntry>>>(myWorkEntriesStreamProvider, (previous, next) {
      final error = next.error;
      if (error is FirebaseException && error.code == 'permission-denied') {
        if (_hasReinvalidatedForCurrentError) return;
        _hasReinvalidatedForCurrentError = true;
        final uid = ref.read(currentUserProvider)!.uid;
        ref.invalidate(userPortalProvider(uid));
      } else {
        _hasReinvalidatedForCurrentError = false;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text('Mon espace'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) {
          final code = error is FirebaseException ? error.code : error.toString();
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Impossible de charger vos prestations. Réessayez. ($code)',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(myWorkEntriesStreamProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          );
        },
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Aucune prestation pour le moment.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Card(
                child: ListTile(
                  title: Text(entry.date.formatEuropean()),
                  subtitle: Text(entry.billingMode.displayName),
                  trailing: Text(
                    entry.laborAmountHT.toEurosString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
