import 'dart:math';

/// Génère un mot de passe aléatoire fort qui ne sert qu'à satisfaire
/// createUserWithEmailAndPassword — jamais affiché, jamais loggé, jamais
/// stocké (ni en clair ni hashé), le client définit le sien via l'email de
/// réinitialisation envoyé juste après. Random.secure() obligatoire :
/// jamais Random() (non cryptographiquement sûr, prévisible).
class SecurePasswordGenerator {
  static const _chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*-_=+';
  static const _length = 32;

  // Pas de seam injectable ici, délibérément : Random.secure() est
  // obligatoire, sans exception ni pour les tests ni pour un futur usage —
  // aucune façon de le remplacer par accident par un Random() non sûr.
  String generate() {
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(_length, (_) => _chars.codeUnitAt(random.nextInt(_chars.length))),
    );
  }
}
