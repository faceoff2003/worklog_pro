/// Authentication-related exceptions.
class AuthException implements Exception {
  final String code;
  final String message;

  const AuthException({
    required this.code,
    required this.message,
  });

  @override
  String toString() => 'AuthException($code): $message';

  /// Get user-friendly error message in French.
  String get userMessage {
    switch (code) {
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'user-disabled':
        return 'Ce compte a été désactivé.';
      case 'user-not-found':
        return 'Identifiants incorrects.';
      case 'wrong-password':
        return 'Identifiants incorrects.';
      case 'email-already-in-use':
        return 'Cette adresse email est déjà utilisée.';
      case 'operation-not-allowed':
        return 'Opération non autorisée.';
      case 'weak-password':
        return 'Le mot de passe est trop faible (minimum 6 caractères).';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifiez votre connexion.';
      case 'invalid-credential':
        return 'Identifiants invalides.';
      default:
        return 'Erreur d\'authentification. Veuillez réessayer.';
    }
  }
}
