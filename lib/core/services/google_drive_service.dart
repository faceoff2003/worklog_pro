import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

/// Fournisseur Riverpod pour injecter le [GoogleDriveService].
final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  return GoogleDriveService();
});

/// Interface client HTTP qui injecte automatiquement les headers d'authentification Google
/// lors des requêtes vers l'API Google Drive.
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _client.send(request..headers.addAll(_headers));
  }
}

/// Service d'intégration pour uploader et classer des PDF sur le Google Drive de l'utilisateur.
/// 
/// Utilise Google Sign-In pour obtenir une clef d'accès OAuth (token)
/// puis le package Google APIs (`googleapis`) pour transférer le flux d'octets.
class GoogleDriveService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb || Platform.isIOS ? '996761949359-ia498upjpaniek3ufhivh6djkhdn8q90.apps.googleusercontent.com' : null,
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/drive.file',
    ],
  );

  /// Uploade un fichier physique depuis l'appareil vers Google Drive.
  /// 
  /// S'assure que le dossier racine "WorkLog Pro" existe, et le crée sinon.
  /// Place ensuite le [file] nommé [fileName] directement dans ce dossier.
  /// Retourne l'identifiant (Drive ID) du fichier créé.
  Future<String?> uploadPdf(File file, String fileName) async {
    try {
      var account = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      account ??= await _googleSignIn.signIn();
      
      if (account == null) throw Exception('Connexion à Google requise.');

      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      // Search or create WorkLog Pro folder
      String? folderId;
      const q = "mimeType='application/vnd.google-apps.folder' and name='WorkLog Pro' and trashed=false";
      final folderList = await driveApi.files.list(q: q, spaces: 'drive');
      
      if (folderList.files != null && folderList.files!.isNotEmpty) {
        folderId = folderList.files!.first.id;
      } else {
        final folder = drive.File()
          ..name = 'WorkLog Pro'
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(folder);
        folderId = createdFolder.id;
      }

      // Upload file
      final driveFile = drive.File()
        ..name = fileName
        ..parents = [if (folderId != null) folderId];

      final fileContent = file.readAsBytesSync();
      final length = fileContent.length;
      final media = drive.Media(file.openRead(), length);

      final result = await driveApi.files.create(driveFile, uploadMedia: media);
      return result.id;
    } catch (e) {
      throw Exception('Erreur Google Drive: $e');
    }
  }
}
