import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

// Pour le téléchargement Web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class FileSaverUtil {
  /// Sauvegarde ou partage un fichier (PDF, Excel...) en fonction de la plateforme.
  static Future<void> saveAndShareFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      // Sur le Web, on déclenche le téléchargement du fichier
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Sur mobile/desktop, on sauvegarde dans le dossier temporaire puis on le partage
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Partage du fichier
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        text: 'Voici votre fichier : $fileName',
      );
    }
  }
}
