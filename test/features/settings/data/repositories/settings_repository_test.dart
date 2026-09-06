// Caractérisation du comportement ACTUEL de SettingsRepository (F-SETTINGS.2),
// avant toute extraction vers Local/Firestore/SyncingSettingsRepository.
// Aucun code de production touché dans cette étape — seulement ce fichier.
//
// Le point le plus important n'est pas ce qui marche, c'est ce qui NE
// distingue PAS deux situations différentes aujourd'hui : voir le groupe
// "JSON corrompu vs absence".

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/data/repositories/settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = SettingsRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loadSettings — rien en stock', () {
    test('renvoie Settings() par défaut', () async {
      final settings = await repository.loadSettings();
      expect(settings, const Settings());
    });
  });

  group('loadSettings — JSON corrompu vs absence (le vrai enjeu)', () {
    test(
      'JSON illisible renvoie Settings() par défaut — '
      'EXACTEMENT LA MÊME VALEUR que "rien en stock", indistinguable pour l\'appelant',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_settings': 'ceci n\'est pas du JSON valide {{{',
        });

        final settings = await repository.loadSettings();

        expect(settings, const Settings());
        // Caractérisation du gap identifié dans le plan F-SETTINGS : à ce
        // stade, il n'existe AUCUN moyen pour l'appelant de savoir si ces
        // réglages par défaut viennent d'un compte neuf (légitime, sûr à
        // pousser vers le cloud) ou d'une corruption locale (jamais sûr à
        // pousser — ça effacerait le cloud). F-SETTINGS.3 introduit
        // LocalSettingsStatus.{absent, loaded, corrupted} précisément pour
        // rendre cette distinction possible. Ce test doit être mis à jour
        // (pas supprimé) quand loadWithStatus() existera.
      },
    );

    test(
      'JSON valide mais de mauvaise forme (map inattendue) renvoie aussi Settings() par défaut',
      () async {
        SharedPreferences.setMockInitialValues({
          // JSON syntaxiquement valide, mais ce n'est pas un objet
          // Settings (ex: un tableau) — un autre visage du même problème.
          'app_settings': '[1, 2, 3]',
        });

        final settings = await repository.loadSettings();

        expect(settings, const Settings());
      },
    );
  });

  group('saveSettings / loadSettings — round-trip', () {
    test('sauvegarde puis relecture renvoie exactement les mêmes valeurs', () async {
      const original = Settings(
        dayHours: 7,
        halfDayHours: 3,
        defaultPauseMinutes: 15,
        roundingMinutes: 10,
        minBillingHours: 1.5,
        minBillingAmountCents: 3000,
        currency: 'EUR',
        country: 'BE',
        travelRatePerKmCents: 45,
        quickTasks: ['Tâche A', 'Tâche B'],
        quickVendors: ['Fournisseur A'],
        pdfHeader: PdfHeader(
          name: 'Jean Dupont',
          phone: '0470 12 34 56',
          email: 'jean@example.com',
          address: 'Rue de la Paix 1, Bruxelles',
          tvaNumber: 'BE0123456789',
          mentionHT: 'Prix HT',
        ),
        autoBackupEnabled: true,
        schemaVersion: 1,
      );

      await repository.saveSettings(original);
      final reloaded = await repository.loadSettings();

      expect(reloaded, original);
    });

    test('round-trip avec les valeurs par défaut (Settings())', () async {
      const original = Settings();

      await repository.saveSettings(original);
      final reloaded = await repository.loadSettings();

      expect(reloaded, original);
    });

    test('round-trip préserve lastBackupAt (DateTime nullable)', () async {
      final original = Settings(lastBackupAt: DateTime(2026, 3, 15, 10, 30));

      await repository.saveSettings(original);
      final reloaded = await repository.loadSettings();

      expect(reloaded.lastBackupAt, original.lastBackupAt);
    });

    test('une sauvegarde écrase entièrement la précédente (pas de fusion)', () async {
      await repository.saveSettings(const Settings(dayHours: 6, currency: 'EUR'));
      await repository.saveSettings(const Settings(dayHours: 9));

      final reloaded = await repository.loadSettings();

      expect(reloaded.dayHours, 9);
      // currency n'a pas été explicitement redonnée dans la 2e sauvegarde :
      // elle retombe sur la valeur par défaut ('EUR'), pas sur celle de la
      // 1re sauvegarde — saveSettings() persiste l'objet entier tel quel,
      // il n'y a pas de fusion champ-par-champ.
      expect(reloaded.currency, 'EUR');
    });
  });

  group('updatePdfHeader', () {
    test('modifie uniquement pdfHeader, préserve le reste des réglages existants', () async {
      const initial = Settings(dayHours: 9, currency: 'USD', autoBackupEnabled: true);
      await repository.saveSettings(initial);

      const newHeader = PdfHeader(name: 'Nouveau Nom', phone: '123', mentionHT: 'HT');
      await repository.updatePdfHeader(newHeader);

      final updated = await repository.loadSettings();
      expect(updated.pdfHeader, newHeader);
      expect(updated.dayHours, 9);
      expect(updated.currency, 'USD');
      expect(updated.autoBackupEnabled, true);
    });

    test('sans réglages préexistants, part des valeurs par défaut pour le reste', () async {
      const newHeader = PdfHeader(name: 'X', phone: '', mentionHT: 'Prix HT');
      await repository.updatePdfHeader(newHeader);

      final updated = await repository.loadSettings();
      expect(updated.pdfHeader, newHeader);
      expect(updated.dayHours, 8); // valeur par défaut de Settings()
    });
  });
}
