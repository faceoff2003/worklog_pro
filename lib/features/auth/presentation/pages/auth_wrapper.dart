import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/presentation/pages/login_page.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/home/presentation/pages/home_page.dart';

/// Authentication wrapper that decides which screen to show.
/// 
/// If user is authenticated, shows the home screen.
/// If not, shows the login screen.
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, show home screen
          return const HomePage();
        } else {
          // User is not authenticated, show login
          return const LoginPage();
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 60,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur d\'authentification',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry
                  ref.invalidate(authStateProvider);
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
