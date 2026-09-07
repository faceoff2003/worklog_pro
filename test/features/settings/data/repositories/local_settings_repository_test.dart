// Caractérisation du comportement de LocalSettingsRepository.
// F-SETTINGS.3 : extraction depuis SettingsRepository + introduction de
// LocalSettingsStatus / loadWithStatus(). Comportement public inchangé —
// loadSettings() résout toujours absent et corrupted vers Settings() par
// défaut, indistinguables pour l'appelant public. loadWithStatus() (usage
// interne, futur SyncingSettingsRepository) rend cette distinction possible.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:worklog_pro/features/settings/data/repositories/local_settings_repository.dart';
import 'package:worklog_pro/features/settings/domain/entities/settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final repository = LocalSettingsRepository();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('loadSettings — rien en stock', () {
    test('renvoie Settings() par défaut', () async {
      final settings = await repository.loadSettings();
      expect(settings, const Settings());
    });
  });

  group('loadWithStatus — distingue absent / loaded / corrupted', () {
    test('rien en stock → LocalSettingsStatus.absent', () async {
      final snapshot = await repository.loadWithStatus();

      expect(snapshot.status, LocalSettingsStatus.absent);
      expect(snapshot.settings, const Settings());
    });

    test('JSON valide → LocalSettingsStatus.loaded', () async {
      await repository.saveSettings(const Settings(dayHours: 6));

      final snapshot = await repository.loadWithStatus();

      expect(snapshot.status, LocalSettingsStatus.loaded);
      expect(snapshot.settings.dayHours, 6);
    });

    test(
      'JSON illisible → LocalSettingsStatus.corrupted, settings reste Settings() par défaut',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_settings': 'ceci n\'est pas du JSON valide {{{',
        });

        final snapshot = await repository.loadWithStatus();

        expect(snapshot.status, LocalSettingsStatus.corrupted);
        expect(snapshot.settings, const Settings());
        // loadSettings() public reste inchangé : Settings() par défaut, sans
        // exposer le statut — seul loadWithStatus() (interne) distingue
        // maintenant ce cas de "rien en stock" (voir groupe ci-dessus).
        expect(await repository.loadSettings(), const Settings());
      },
    );

    test(
      'JSON valide mais de mauvaise forme (map inattendue) → aussi corrupted, pas absent',
      () async {
        SharedPreferences.setMockInitialValues({
          // JSON syntaxiquement valide, mais ce n'est pas un objet
          // Settings (ex: un tableau) — un autre visage du même problème.
          'app_settings': '[1, 2, 3]',
        });

        final snapshot = await repository.loadWithStatus();

        expect(snapshot.status, LocalSettingsStatus.corrupted);
        expect(snapshot.settings, const Settings());
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
