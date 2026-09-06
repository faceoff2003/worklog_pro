// Tests d'intégration : les vrais formulaires (widgets réels, providers
// réels, repositories réels) contre l'émulateur Firestore + Auth, avec les
// rules réelles (firestore.rules) déployées SUR L'ÉMULATEUR uniquement.
//
// Ne remplace pas un test sur appareil réel, mais couvre le chemin
// UI -> repository -> rules que test/features/.../*_test.dart (repository
// fake) et firestore-tests/rules.test.mjs (pas de vrai widget) ne voient
// ni l'un ni l'autre.
//
// Prérequis, dans deux terminaux séparés :
//   1. firebase emulators:start --only firestore,auth
//   2. flutter test integration_test/app_test.dart -d <device>
//
// Vérifié sur un émulateur Android (AVD "medium_phone", API 36, x86_64,
// créé via `flutter emulators --create`) : 4/5 tests verts. Le 5e
// ("modification de dépense") échouait à cause du clavier logiciel réel
// recouvrant le bouton Modifier après la saisie du montant — corrigé
// dans tapButton() (unfocus avant de taper) mais pas re-vérifié après ce
// fix précis (session interrompue). À revérifier avant de considérer ce
// fichier comme du vert stable en CI.
//
// Deux prérequis Android découverts en le faisant tourner :
//   - AVD sans profil d'appareil (`-d` non précisé à la création) donne
//     un écran minuscule (320x640) : bouton Enregistrer hors zone
//     cliquable. Utiliser un profil réaliste (ex. "medium_phone").
//   - Cleartext HTTP vers l'émulateur (10.0.2.2/localhost) bloqué par
//     défaut dès l'API 28 : voir android/app/src/debug/res/xml/
//     network_security_config.xml (debug uniquement, jamais en release).
//
// Chaque test se connecte avec un nouvel utilisateur anonyme (uid frais à
// chaque fois) : isolation naturelle, pas besoin de vider l'émulateur entre
// les tests.

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/clients/domain/entities/client.dart';
import 'package:worklog_pro/features/clients/presentation/pages/client_form_page.dart';
import 'package:worklog_pro/features/clients/presentation/providers/clients_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/presentation/pages/expense_form_page.dart';
import 'package:worklog_pro/features/expenses/presentation/providers/expenses_provider.dart';
import 'package:worklog_pro/features/projects/presentation/pages/project_form_page.dart';
import 'package:worklog_pro/features/projects/presentation/providers/projects_provider.dart';
import 'package:worklog_pro/features/work_entries/presentation/pages/work_entry_form_page.dart';
import 'package:worklog_pro/features/work_entries/presentation/providers/work_entries_provider.dart';
import 'package:worklog_pro/firebase_options.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    // 10.0.2.2 = alias standard vers le localhost de la machine hôte,
    // depuis l'intérieur d'un émulateur Android (son propre "localhost"
    // pointe sur lui-même, pas sur la machine qui l'héberge).
    final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  /// Un nouvel utilisateur anonyme (émulateur Auth) par test, et un
  /// ProviderContainer dont authStateProvider est déjà résolu AVANT qu'on
  /// pompe le moindre widget — sinon les providers repository (qui font
  /// `ref.watch(authStateProvider).value` et lèvent si null) peuvent
  /// planter sur la toute première frame, avant que le stream d'auth
  /// n'ait eu le temps d'émettre.
  Future<ProviderContainer> signedInContainer() async {
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
    final container = ProviderContainer();
    await container.read(authStateProvider.future);
    return container;
  }

  /// Monte `page` via une route poussée (jamais home: page directement) :
  /// _save() de chaque formulaire fait Navigator.pop() en cas de succès,
  /// et pop() sur l'unique route d'un Navigator peut mal se comporter.
  Future<void> openPage(WidgetTester tester, ProviderContainer container, Widget page) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => page),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdown(WidgetTester tester, Type dropdownType, String optionText) async {
    await tester.tap(find.byType(dropdownType));
    await tester.pumpAndSettle();
    await tester.tap(find.text(optionText).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapButton(WidgetTester tester, String text) async {
    // Ferme le clavier logiciel réel avant de scroller/taper : sur
    // appareil (contrairement aux tests widgets hôte), le clavier occupe
    // une vraie portion d'écran et peut passer par-dessus le bouton
    // Enregistrer/Modifier après une saisie de texte juste avant.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    final button = find.text(text);
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('création client avec tarifs', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    await openPage(tester, container, const ClientFormPage());

    await tester.enterText(find.widgetWithText(TextFormField, 'Nom *'), 'Jean Dupont');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tarif horaire'), '35');
    await tester.enterText(find.widgetWithText(TextFormField, 'Demi-journée'), '150');
    await tester.enterText(find.widgetWithText(TextFormField, 'Journée'), '280');
    await tester.enterText(find.widgetWithText(TextFormField, 'Forfait'), '500');

    await tapButton(tester, 'Créer le client');

    // Repository réel, émulateur réel, rules réelles : si isPositiveInt ou
    // hasTimestamps avait échoué côté rules, cette lecture serait vide.
    final clients = await container.read(clientRepositoryProvider).getClients();
    expect(clients, hasLength(1));
    final client = clients.single;
    expect(client.name, 'Jean Dupont');
    expect(client.defaultRates.hour, Money.fromCents(3500));
    expect(client.defaultRates.halfDay, Money.fromCents(15000));
    expect(client.defaultRates.day, Money.fromCents(28000));
    expect(client.defaultRates.fixedJob, Money.fromCents(50000));
  });

  testWidgets('création chantier', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    final client = await container.read(clientRepositoryProvider).createClient(
          Client(
            id: '',
            name: 'Client Chantier',
            type: ClientType.patron,
            defaultRates: const DefaultRates(),
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await openPage(tester, container, ProjectFormPage(clientId: client.id));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nom du chantier *'),
      'Rénovation Salle de Bain',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Ville'), 'Liège');

    await tapButton(tester, 'Créer le chantier');

    final projects = await container.read(projectRepositoryProvider).getProjects();
    expect(projects, hasLength(1));
    final project = projects.single;
    expect(project.label, 'Rénovation Salle de Bain');
    expect(project.clientId, client.id);
    expect(project.address.city, 'Liège');
    // Statut/type par défaut de la page, doivent passer les rules (M4).
    expect(project.status, ProjectStatus.actif);
  });

  testWidgets('dépense sans catégorie de matériel ni mode de déplacement', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    final client = await container.read(clientRepositoryProvider).createClient(
          Client(
            id: '',
            name: 'Client Dépense',
            type: ClientType.patron,
            defaultRates: const DefaultRates(),
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await openPage(tester, container, ExpenseFormPage(initialClientId: client.id));

    // Catégorie par défaut du formulaire = materials (affiche Type de
    // Matériel) ; on bascule sur "Autre" pour que ni materialCategory ni
    // travelMode ne soient renseignés (M4 : les deux doivent rester
    // null-tolérants côté rules, exactement le cas trouvé en prod par le
    // script scripts/list-distinct-enum-values.mjs).
    await selectDropdown(tester, DropdownButtonFormField<ExpenseCategory>, ExpenseCategory.other.displayName);

    await tester.enterText(find.widgetWithText(TextFormField, 'Description *'), 'Frais divers chantier');
    await tester.enterText(find.widgetWithText(TextFormField, 'Montant HT *'), '42.50');

    await tapButton(tester, 'Enregistrer');

    final expenses = await container.read(expenseRepositoryProvider).getExpenses();
    expect(expenses, hasLength(1));
    final expense = expenses.single;
    expect(expense.category, ExpenseCategory.other);
    expect(expense.materialCategory, isNull);
    expect(expense.travelMode, isNull);
    expect(expense.amountHT, Money.fromCents(4250));
    expect(expense.clientId, client.id);
  });

  testWidgets('modification de dépense', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    final client = await container.read(clientRepositoryProvider).createClient(
          Client(
            id: '',
            name: 'Client Modif Dépense',
            type: ClientType.patron,
            defaultRates: const DefaultRates(),
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await container.read(expenseRepositoryProvider).createExpense(
          Expense(
            id: '',
            date: DateOnly.today(),
            clientId: client.id,
            category: ExpenseCategory.food,
            amountHT: Money.fromCents(1000),
            description: 'Repas chantier',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    final seeded = (await container.read(expenseRepositoryProvider).getExpenses()).single;
    final originalCreatedAt = seeded.createdAt;

    await openPage(tester, container, ExpenseFormPage(expense: seeded));

    final amountField = find.widgetWithText(TextFormField, 'Montant HT *');
    await tester.enterText(amountField, '17.30');

    // Bouton "Modifier" en édition (pas "Enregistrer") — voir aussi le
    // titre d'AppBar "Modifier Dépense", texte distinct.
    await tapButton(tester, 'Modifier');

    final updated = (await container.read(expenseRepositoryProvider).getExpenses()).single;
    expect(updated.id, seeded.id);
    expect(updated.amountHT, Money.fromCents(1730));
    expect(updated.description, 'Repas chantier');
    expect(updated.createdAt, originalCreatedAt);
  });

  testWidgets('création prestation', (tester) async {
    final container = await signedInContainer();
    addTearDown(container.dispose);

    final client = await container.read(clientRepositoryProvider).createClient(
          Client(
            id: '',
            name: 'Client Prestation',
            type: ClientType.patron,
            defaultRates: DefaultRates(
              hour: Money.fromCents(2500),
              day: Money.fromCents(30000),
            ),
            tags: const [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    await openPage(tester, container, WorkEntryFormPage(initialClientId: client.id));

    // Mode par défaut = hourly : on bascule explicitement sur "Journée"
    // pour garantir que _recalculate(updatePrice: true) se déclenche
    // (même valeur que la valeur par défaut ne redéclenche pas forcément
    // onChanged).
    await selectDropdown(tester, DropdownButtonFormField<BillingMode>, BillingMode.day.displayName);

    await tapButton(tester, 'Enregistrer la prestation');

    final entries = await container.read(workEntryRepositoryProvider).getWorkEntries();
    expect(entries, hasLength(1));
    final entry = entries.single;
    expect(entry.clientId, client.id);
    expect(entry.billingMode, BillingMode.day);
    // Mode day : laborAmountHT et rateApplied valent tous les deux le
    // tarif jour (indépendant de la durée), calculé par
    // WorkEntryBuilderService puis accepté par isPositiveInt(laborAmountHT).
    expect(entry.laborAmountHT, Money.fromCents(30000));
    expect(entry.rateApplied, Money.fromCents(30000));
    expect(entry.durationMinutes, greaterThan(0));
  });
}
