import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';

/// enabled == false sur clientPortals/{monUid} — état métier normal (révoqué
/// délibérément par l'artisan, pas un échec), donc ton informatif, pas rouge.
/// Rien à réessayer ici : seul l'artisan peut réactiver l'accès.
class ClientDisabledPage extends ConsumerWidget {
  const ClientDisabledPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600, size: 60),
              const SizedBox(height: 16),
              Text('Accès désactivé', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text(
                'Votre accès a été désactivé par votre artisan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                child: const Text('Se déconnecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
