import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/user_role_provider.dart';

/// Seul permission-denied atterrit ici (voir decideRoleRoute) — un cas
/// volontairement rare, jamais le hors-ligne courant. Bouton de
/// déconnexion à côté de "Réessayer" : sans lui, un utilisateur bloqué ne
/// peut pas changer de compte pour en essayer un autre.
class RoleCheckBlockedPage extends ConsumerWidget {
  final String uid;
  final Object error;

  const RoleCheckBlockedPage({super.key, required this.uid, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = error is FirebaseException ? (error as FirebaseException).code : error.toString();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, color: Colors.red.shade700, size: 60),
              const SizedBox(height: 16),
              Text('Accès refusé', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Impossible de vérifier votre accès. ($code)',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                    child: const Text('Se déconnecter'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(userPortalProvider(uid)),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
