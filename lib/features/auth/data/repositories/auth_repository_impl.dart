import 'dart:developer' as dev;

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
      if (kDebugMode) dev.log('Starting Google Sign-In flow...', name: 'Auth');

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (kDebugMode) dev.log('User selected: ${googleUser?.email}', name: 'Auth');

      if (googleUser == null) {
        if (kDebugMode) dev.log('User cancelled sign-in', name: 'Auth');
        throw const AuthException(
          code: 'sign_in_canceled',
          message: 'Connexion annulée par l\'utilisateur',
        );
      }

      if (kDebugMode) dev.log('Getting authentication details...', name: 'Auth');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      if (kDebugMode) {
        dev.log('AccessToken: ${googleAuth.accessToken != null ? "✓" : "✗"}', name: 'Auth');
        dev.log('IdToken: ${googleAuth.idToken != null ? "✓" : "✗"}', name: 'Auth');
      }

      // Check if we have the required tokens (accessToken is valid in 6.x)
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        if (kDebugMode) dev.log('ERROR: No tokens received', name: 'Auth');
        throw const AuthException(
          code: 'missing-tokens',
          message: 'Aucun token reçu de Google',
        );
      }

      if (kDebugMode) dev.log('Creating Firebase credential...', name: 'Auth');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      if (kDebugMode) dev.log('Signing in to Firebase...', name: 'Auth');
      final userCredential = await _auth.signInWithCredential(credential);

      if (kDebugMode) dev.log('Firebase user: ${userCredential.user?.email}', name: 'Auth');

      if (userCredential.user == null) {
        if (kDebugMode) dev.log('ERROR: No Firebase user returned', name: 'Auth');
        throw const AuthException(
          code: 'null-user',
          message: 'La connexion a échoué',
        );
      }

      if (kDebugMode) dev.log('✓ Success! Mapping user...', name: 'Auth');
      final appUser = _mapFirebaseUser(userCredential.user!);

      if (kDebugMode) dev.log('Creating/updating user in Firestore...', name: 'Auth');
      await _createUserInFirestore(appUser);

      return appUser;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) dev.log('FirebaseAuthException: ${e.code} - ${e.message}', name: 'Auth');
      throw AuthException(
        code: e.code,
        message: e.message ?? 'Unknown error',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      if (kDebugMode) dev.log('Generic error: $e', name: 'Auth');
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
        if (kDebugMode) dev.log('Creating new user document for ${user.email}', name: 'Auth');
        await userDoc.set({
          'email': user.email,
          'displayName': user.displayName,
          'photoUrl': user.photoUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        if (kDebugMode) dev.log('Updating existing user document', name: 'Auth');
        await userDoc.update({
          'displayName': user.displayName,
          'photoUrl': user.photoUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) dev.log('Error creating/updating user: $e', name: 'Auth');
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
