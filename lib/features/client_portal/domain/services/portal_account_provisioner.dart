/// Créer un compte Firebase Auth pour un client SANS déconnecter l'artisan
/// est fondamentalement un problème d'infrastructure Firebase (app
/// secondaire jetable) — cette interface l'isole du séquencement métier
/// (ClientPortalProvisioningService), qui n'a besoin de connaître que ces
/// trois opérations pour être entièrement testable sans Firebase réel.
abstract class PortalAccountProvisioner {
  /// Lève [PortalEmailAlreadyInUseException] si l'email est déjà utilisé, ou
  /// [PortalInvalidEmailException] si son format est invalide — deux
  /// chemins explicites, jamais confondus avec une autre erreur de
  /// création. Le premier est le cas le plus fréquent (faute de frappe) et
  /// l'artisan doit savoir que c'est corrigeable de son côté, pas une
  /// panne.
  Future<String> createAccount({required String email, required String password});

  /// Supprime le compte tout juste créé par [createAccount] sur CETTE même
  /// instance (encore connectée dessus) — jamais utilisable après [dispose].
  Future<void> deleteJustCreatedAccount();

  /// Libère les ressources (app Firebase secondaire) — appelé exactement
  /// une fois, toujours, quelle que soit l'issue de la séquence.
  Future<void> dispose();
}

class PortalEmailAlreadyInUseException implements Exception {
  const PortalEmailAlreadyInUseException();
}

class PortalInvalidEmailException implements Exception {
  const PortalInvalidEmailException();
}
