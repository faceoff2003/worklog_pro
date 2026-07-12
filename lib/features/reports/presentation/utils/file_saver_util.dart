import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'file_saver_stub.dart' if (dart.library.html) 'file_saver_web.dart';

class FileSaverUtil {
  /// Sauvegarde ou partage un fichier (PDF, Excel...) en fonction de la plateforme.
  static Future<void> saveAndShareFile({
    required List<int> bytes,
    required String fileName,
    required String mimeType,
  }) async {
    if (kIsWeb) {
      // Sur le Web, on déclenche le téléchargement du fichier
      saveFileWeb(bytes, fileName, mimeType);
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
