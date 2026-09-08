/// Envoie l'email qui permet au client de définir son propre mot de passe
/// et d'accéder à son portail pour la première fois — jamais de mot de
/// passe transmis par l'artisan. N'a besoin d'aucune session particulière
/// (pas d'app secondaire) : envoyer une réinitialisation ne nécessite pas
/// d'être connecté en tant que ce compte.
abstract class PortalInviteEmailSender {
  Future<void> sendInvite({required String email});
}
