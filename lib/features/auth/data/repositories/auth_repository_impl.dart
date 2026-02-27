import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:worklog_pro/core/errors/auth_exception.dart';
import 'dart:io' show Platform;
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/domain/repositories/auth_repository.dart';

/// Firebase implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(
          clientId: kIsWeb || Platform.isIOS ? '996761949359-ia498upjpaniek3ufhivh6djkhdn8q90.apps.googleusercontent.com' : null,
          scopes: [
            'email',
            'profile',
            'https://www.googleapis.com/auth/drive.file',
          ],
        );

  @override
  Stream<AppUser?> get authStateChanges {
    return _auth.authStateChanges().map((firebaseUser) {
      if (firebaseUser == null) return null;
      return _mapFirebaseUser(firebaseUser);
    });
  }

  @override
  AppUser? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return _mapFirebaseUser(firebaseUser);
  }

  @override
  Future<AppUser> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(
          code: 'user-not-found',
          message: 'User not found after sign in',
        );
      }

      return _mapFirebaseUser(userCredential.user!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<AppUser> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (userCredential.user == null) {
        throw const AuthException(
          code: 'user-not-found',
          message: 'User not created',
        );
      }

      // Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        await userCredential.user!.updateDisplayName(displayName);
        await userCredential.user!.reload();
      }

      return _mapFirebaseUser(
        _auth.currentUser ?? userCredential.user!,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    } catch (e) {
      throw AuthException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    }
  }

  @override
  Future<AppUser> signInWithGoogle() async {
    try {
      debugPrint('[GoogleSignIn] Starting Google Sign-In flow...');
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      debugPrint('[GoogleSignIn] User selected: ${googleUser?.email}');
      
      if (googleUser == null) {
        debugPrint('[GoogleSignIn] User cancelled sign-in');
        throw const AuthException(
          code: 'sign_in_canceled',
          message: 'Connexion annulée par l\'utilisateur',
        );
      }

      debugPrint('[GoogleSignIn] Getting authentication details...');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      debugPrint('[GoogleSignIn] AccessToken: ${googleAuth.accessToken != null ? "✓" : "✗"}');
      debugPrint('[GoogleSignIn] IdToken: ${googleAuth.idToken != null ? "✓" : "✗"}');

      // Check if we have the required tokens (accessToken is valid in 6.x)
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        debugPrint('[GoogleSignIn] ERROR: No tokens received');
        throw const AuthException(
          code: 'missing-tokens',
          message: 'Aucun token reçu de Google',
        );
      }

      debugPrint('[GoogleSignIn] Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('[GoogleSignIn] Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('[GoogleSignIn] Firebase user: ${userCredential.user?.email}');
      
      if (userCredential.user == null) {
        debugPrint('[GoogleSignIn] ERROR: No Firebase user returned');
        throw const AuthException(
          code: 'null-user',
          message: 'La connexion a échoué',
        );
      }

      debugPrint('[GoogleSignIn] ✓ Success! Mapping user...');
      final appUser = _mapFirebaseUser(userCredential.user!);
      
      debugPrint('[GoogleSignIn] Creating/updating user in Firestore...');
      await _createUserInFirestore(appUser);
      
      return appUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('[GoogleSignIn] FirebaseAuthException: ${e.code} - ${e.message}');
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[GoogleSignIn] Generic error: $e');
      throw AuthException(
        code: 'google-sign-in-error',
        message: 'Erreur lors de la connexion Google: ${e.toString()}',
      );
    }
  }

  /// Create or update user document in Firestore.
  /// This is called after successful Google Sign-In to ensure the user exists in Firestore.
  Future<void> _createUserInFirestore(AppUser user) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final userDoc = firestore.collection('users').doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        debugPrint('[Firestore] Creating new user document for ${user.email}');
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        debugPrint('[Firestore] Updating existing user document');
        await userDoc.update({
          'displayName': user.displayName,
          'photoUrl': user.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('[Firestore] Error creating/updating user: $e');
    }
  }

  /// Map Firebase User to AppUser entity.
  AppUser _mapFirebaseUser(User firebaseUser) {
    return AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
    );
  }
}
