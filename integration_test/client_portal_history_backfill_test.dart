// C-PORTAL.9, étape 1 — preuves qu'un fake ne peut pas fournir :
// 1. Un vrai volume (600, au-delà de la limite de 500 par WriteBatch) se
//    découpe et s'écrit correctement contre le VRAI Firestore.
// 2. Rejouer le backfill après coup ne duplique rien (idempotence réelle,
//    pas déduite du seul choix de l'ID de document).
// 3. Sans le filtre isBillable AVANT le batch, une seule dépense non
//    refacturable fait échouer TOUT le lot contre les VRAIES rules — la
//    preuve que le filtre est nécessaire, pas cosmétique.
//
// Vérification par LECTURE toujours faite côté CLIENT (compte réel), jamais
// côté artisan : les rules n'autorisent l'artisan qu'à ÉCRIRE le miroir,
// jamais à le relire (allow read: if isOwner(portalUid) && ...) — découvert
// en écrivant ce test (première version tentait de vérifier depuis la
// session artisan, permission-denied immédiat).
//
// Prérequis : firebase emulators:start --only firestore,auth, puis
// flutter test integration_test/client_portal_history_backfill_test.dart -d <device>

import 'dart:io' show Platform;

import 'package:cloud_firestore/cloud_firestore.dart' hide Settings;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:worklog_pro/core/constants/constants.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_mirror_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/data/repositories/client_portal_repository_impl.dart';
import 'package:worklog_pro/features/client_portal/domain/services/client_portal_history_backfill_service.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/expenses/domain/repositories/expense_repository.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/work_entries/domain/repositories/work_entry_repository.dart';
import 'package:worklog_pro/firebase_options.dart';

class _InMemoryWorkEntryRepository implements WorkEntryRepository {
  final List<WorkEntry> entries;
  _InMemoryWorkEntryRepository(this.entries);

  @override
  Future<List<WorkEntry>> getWorkEntries({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) async =>
      entries;

  @override
  Stream<List<WorkEntry>> watchWorkEntries({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) =>
      throw UnimplementedError();
  @override
  Future<WorkEntry?> getWorkEntry(String id) => throw UnimplementedError();
  @override
  Future<WorkEntry> createWorkEntry(WorkEntry workEntry) => throw UnimplementedError();
  @override
  Future<WorkEntry> updateWorkEntry(WorkEntry workEntry) => throw UnimplementedError();
  @override
  Future<void> deleteWorkEntry(String id) => throw UnimplementedError();
}

class _InMemoryExpenseRepository implements ExpenseRepository {
  final List<Expense> expenses;
  _InMemoryExpenseRepository(this.expenses);

  @override
  Future<List<Expense>> getExpenses({DateOnly? from, DateOnly? to, String? clientId, String? projectId}) async =>
      expenses;

  @override
  Stream<List<Expense>> watchExpenses({String? clientId, String? projectId}) => throw UnimplementedError();
  @override
  Future<void> createExpense(Expense expense) => throw UnimplementedError();
  @override
  Future<void> updateExpense(Expense expense) => throw UnimplementedError();
  @override
  Future<void> deleteExpense(String id) => throw UnimplementedError();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final emulatorHost = Platform.isAndroid ? '10.0.2.2' : 'localhost';

  setUpAll(() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
    await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
  });

  WorkEntry entry(String id) => WorkEntry(
        id: id,
        date: DateOnly.fromString('2026-01-01'),
        startTime: 480,
        endTime: 720,
        durationMinutes: 240,
        clientId: 'client-1',
        billingMode: BillingMode.hourly,
        rateApplied: Money.fromCents(2000),
        laborAmountHT: Money.fromCents(8000),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  Expense expense(String id, {bool isBillable = true}) => Expense(
        id: id,
        date: DateOnly.fromString('2026-01-01'),
        clientId: 'client-1',
        category: ExpenseCategory.materials,
        amountHT: Money.fromCents(1000),
        description: 'Câble',
        isBillable: isBillable,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

  testWidgets(
    'volume réel (600, > 500) : découpage correct, puis rejeu idempotent sans duplication',
    (tester) async {
      final ts = DateTime.now().millisecondsSinceEpoch;

      // Le futur CLIENT se crée d'abord — son uid devient portalUid.
      final client = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'backfill-client-$ts@example.com',
        password: 'testpass123',
      );
      final portalUid = client.user!.uid;
      await FirebaseAuth.instance.signOut();

      // L'ARTISAN crée le portail et lance le backfill.
      final artisan = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'backfill-artisan-$ts@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisan.user!.uid;

      final portalRepo = ClientPortalRepositoryImpl();
      await portalRepo.createPortal(portalUid: portalUid, artisanUid: artisanUid, clientId: 'client-1');

      final entries = List.generate(600, (i) => entry('vol-entry-$i'));
      final service = ClientPortalHistoryBackfillService(
        _InMemoryWorkEntryRepository(entries),
        _InMemoryExpenseRepository(const []),
        portalRepo,
      );

      final outcome1 = await service.backfillHistory(portalUid: portalUid, clientId: 'client-1');
      expect(outcome1.mirroredWorkEntries, 600);
      expect(outcome1.workEntriesComplete, isTrue);

      // Rejeu immédiat (idempotence réelle, pas déduite), TOUJOURS comme
      // artisan — c'est lui qui a le droit d'écrire.
      final outcome2 = await service.backfillHistory(portalUid: portalUid, clientId: 'client-1');
      expect(outcome2.mirroredWorkEntries, 600);

      await FirebaseAuth.instance.signOut();

      // Vérification par LECTURE côté CLIENT — le seul rôle autorisé à lire
      // le miroir (isOwner(portalUid)).
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: client.user!.email!,
        password: 'testpass123',
      );
      final mirrored = await ClientMirrorRepositoryImpl(uid: portalUid).watchMyWorkEntries().first;
      expect(
        mirrored.length,
        600,
        reason: 'les 600 documents doivent réellement exister, et le rejeu n\'a strictement rien dupliqué',
      );
    },
  );

  testWidgets(
    'sans le filtre isBillable, une seule dépense non refacturable fait échouer TOUT le batch contre les vraies rules',
    (tester) async {
      final ts = DateTime.now().millisecondsSinceEpoch;

      final client = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'backfill-filter-client-$ts@example.com',
        password: 'testpass123',
      );
      final portalUid = client.user!.uid;
      await FirebaseAuth.instance.signOut();

      final artisan = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: 'backfill-filter-artisan-$ts@example.com',
        password: 'testpass123',
      );
      final artisanUid = artisan.user!.uid;

      final portalRepo = ClientPortalRepositoryImpl();
      await portalRepo.createPortal(portalUid: portalUid, artisanUid: artisanUid, clientId: 'client-1');

      // Appel DIRECT au repository, en contournant délibérément le filtre du
      // service — c'est exactement ce que le service ne doit JAMAIS faire.
      Object? error;
      try {
        await portalRepo.mirrorExpensesBatch(portalUid, [
          expense('would-succeed-1'),
          expense('would-fail-because-not-billable', isBillable: false),
          expense('would-succeed-2'),
        ]);
      } catch (e) {
        error = e;
      }
      expect(error, isNotNull, reason: 'le batch entier doit être rejeté par les rules');

      await FirebaseAuth.instance.signOut();

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: client.user!.email!,
        password: 'testpass123',
      );
      final mirroredExpenses = await FirebaseFirestore.instance
          .collection('clientPortals')
          .doc(portalUid)
          .collection('expenses')
          .get();
      expect(
        mirroredExpenses.docs.length,
        0,
        reason: 'AUCUNE des trois — même les deux refacturables — un WriteBatch est tout ou rien',
      );
    },
  );
}
