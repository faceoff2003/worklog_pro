import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/domain/repositories/auth_repository.dart';

/// Provider for AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl();
});

/// Provider for auth state changes stream.
/// 
/// Emits current user when signed in, null when signed out.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

/// Provider for current user (synchronous).
final currentUserProvider = Provider<AppUser?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

/// Auth controller for sign in, sign up, sign out operations.
class AuthController extends StateNotifier<AsyncValue<void>> {
  final AuthRepository _authRepository;

  AuthController(this._authRepository) : super(const AsyncValue.data(null));

  /// Sign in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    });
  }

  /// Sign up with email and password.
  Future<void> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: displayName,
      );
    });
  }

  /// Sign out current user.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signOut();
    });
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.sendPasswordResetEmail(email);
    });
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authRepository.signInWithGoogle();
    });
  }
}

/// Provider for AuthController.
final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository);
});
