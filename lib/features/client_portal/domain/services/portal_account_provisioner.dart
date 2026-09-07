/// Créer un compte Firebase Auth pour un client SANS déconnecter l'artisan
/// est fondamentalement un problème d'infrastructure Firebase (app
/// secondaire jetable) — cette interface l'isole du séquencement métier
/// (ClientPortalProvisioningService), qui n'a besoin de connaître que ces
/// trois opérations pour être entièrement testable sans Firebase réel.
abstract class PortalAccountProvisioner {
  /// Lève [PortalEmailAlreadyInUseException] si l'email est déjà utilisé —
  /// chemin explicite, jamais confondu avec une autre erreur de création.
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
