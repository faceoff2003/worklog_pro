import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';

/// Authentication repository interface.
/// 
/// This defines the contract for authentication operations.
/// Implementation will use Firebase Auth.
abstract class AuthRepository {
  /// Stream of authentication state changes.
  /// Emits the current user when signed in, null when signed out.
  Stream<AppUser?> get authStateChanges;

  /// Get the current authenticated user (synchronous).
  AppUser? get currentUser;

  /// Sign in with email and password.
  /// 
  /// Throws [AuthException] on failure.
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Create a new user account with email and password.
  /// 
  /// Throws [AuthException] on failure.
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  });

  /// Sign out the current user.
  Future<void> signOut();

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email);

  /// Sign in with Google.
  /// 
  /// Opens Google Sign-In flow and authenticates the user.
  /// Throws [AuthException] on failure or if user cancels.
  Future<AppUser> signInWithGoogle();
}
