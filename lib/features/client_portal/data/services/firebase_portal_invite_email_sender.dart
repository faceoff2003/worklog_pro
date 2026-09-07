import 'package:firebase_auth/firebase_auth.dart';
import 'package:worklog_pro/features/client_portal/domain/services/portal_invite_email_sender.dart';

/// Utilise l'app Firebase PAR DÉFAUT (celle de l'artisan connecté) — envoyer
/// une réinitialisation de mot de passe ne nécessite aucune session
/// particulière, jamais d'app secondaire pour ça.
class FirebasePortalInviteEmailSender implements PortalInviteEmailSender {
  final FirebaseAuth _auth;

  FirebasePortalInviteEmailSender({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<void> sendInvite({required String email}) => _auth.sendPasswordResetEmail(email: email);
}
