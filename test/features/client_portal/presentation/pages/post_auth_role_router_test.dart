// C-PORTAL.7 — PostAuthRoleRouter est le SEUL point de décision de rôle de
// toute l'app. Pour les scénarios client/bloqué, aucun provider artisan
// (authStateProvider, reportDataProvider, monthlyRevenueProvider) n'est
// overridé : si HomePage (ou un de ses descendants) était construit par
// erreur, le test échoue immédiatement avec une FirebaseException non
// mockée (aucune app Firebase initialisée dans flutter test) — preuve plus
// forte qu'un simple findsNothing, retenue avec William dès C-PORTAL.7.
//
// Pour le scénario artisan, c'est l'inverse : on override le minimum pour
// que HomePage monte, et on prouve explicitement qu'il ne bascule jamais
// côté client (find.byType(ClientHomePage), findsNothing).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:worklog_pro/core/value_objects/value_objects.dart';
import 'package:worklog_pro/features/auth/domain/entities/app_user.dart';
import 'package:worklog_pro/features/auth/presentation/providers/auth_provider.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/domain/repositories/client_portal_repository.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_disabled_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_home_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/post_auth_role_router.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/role_check_blocked_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/client_portal_provider.dart';
import 'package:worklog_pro/features/expenses/domain/entities/expense.dart';
import 'package:worklog_pro/features/home/presentation/pages/home_page.dart';
import 'package:worklog_pro/features/home/presentation/providers/chart_providers.dart';
import 'package:worklog_pro/features/reports/domain/entities/report_data.dart';
import 'package:worklog_pro/features/reports/presentation/providers/report_providers.dart';
import 'package:worklog_pro/features/work_entries/domain/entities/work_entry.dart';
import 'package:worklog_pro/features/payments/domain/entities/payment.dart';

const _uid = 'user-uid-1';

class _FakeClientPortalRepository implements ClientPortalRepository {
  ClientPortal? Function()? onGetPortal;
  Object? throwOnGetPortal;
  Completer<ClientPortal?>? hangOnGetPortal;

  @override
  Future<ClientPortal?> getPortal(String portalUid) {
    if (hangOnGetPortal != null) return hangOnGetPortal!.future;
    if (throwOnGetPortal != null) return Future.error(throwOnGetPortal!);
    return Future.value(onGetPortal?.call());
  }

  @override
  Future<void> createPortal({required String portalUid, required String artisanUid, required String clientId}) =>
      throw UnimplementedError();
  @override
  Future<void> setEnabled(String portalUid, bool enabled) => throw UnimplementedError();
  @override
  Future<List<ClientPortal>> listPortalsForArtisan(String artisanUid) => throw UnimplementedError();
  @override
  Future<void> mirrorWorkEntry(String portalUid, WorkEntry entry) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredWorkEntry(String portalUid, String entryId) => throw UnimplementedError();
  @override
  Future<void> mirrorExpense(String portalUid, Expense expense) => throw UnimplementedError();
  @override
  Future<void> deleteMirroredExpense(String portalUid, String expenseId) => throw UnimplementedError();
  @override
  Future<void> mirrorWorkEntriesBatch(String portalUid, List<WorkEntry> entries) => throw UnimplementedError();
  @override
  Future<void> mirrorExpensesBatch(String portalUid, List<Expense> expenses) => throw UnimplementedError();
  @override
  Future<void> saveBackfillStatus(String portalUid, BackfillOutcome outcome) => throw UnimplementedError();
  @override
  Future<BackfillOutcome?> getBackfillStatus(String portalUid) => throw UnimplementedError();
}

ClientPortal _portal({required bool enabled}) => ClientPortal(
      portalUid: _uid,
      artisanUid: 'artisan-uid-1',
      clientId: 'client-doc-1',
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

ReportData _emptyReportData() => ReportData(
      totalLaborAmount: Money.zero,
      totalTravelAmount: Money.zero,
      totalBillableExpenses: Money.zero,
      totalNonBillableExpenses: Money.zero,
      totalPayments: Money.zero,
      workEntries: const <WorkEntry>[],
      expenses: const <Expense>[],
      payments: const <Payment>[],
      dateRange: DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
    );

/// Overrides minimaux pour que HomePage monte sans exploser — utilisé
/// UNIQUEMENT pour le scénario artisan. Jamais pour les scénarios
/// client/bloqué : c'est justement leur absence qui prouve qu'un client
/// n'atteint jamais HomePage.
List<Override> _artisanHomePageOverrides() => [
      authStateProvider.overrideWith(
        (ref) => Stream.value(AppUser(uid: 'artisan-uid-1', email: 'artisan@example.com', createdAt: DateTime(2026, 1, 1))),
      ),
      reportDataProvider.overrideWithValue(AsyncValue.data(_emptyReportData())),
      monthlyRevenueProvider.overrideWithValue(const AsyncValue.data(<MonthRevenue>[])),
    ];

void main() {
  setUpAll(() async {
    // HomePage formate une date en fr_FR (DateFormat) — nécessaire dès que
    // le scénario artisan monte réellement HomePage.
    await initializeDateFormatting('fr_FR', null);
  });

  testWidgets(
    'artisan (document absent) -> HomePage, et JAMAIS ClientHomePage — la preuve qu\'un artisan ne bascule jamais côté client',
    (tester) async {
      final fake = _FakeClientPortalRepository()..onGetPortal = () => null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientPortalRepositoryProvider.overrideWithValue(fake),
            ..._artisanHomePageOverrides(),
          ],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(ClientHomePage), findsNothing);
      expect(find.byType(ClientDisabledPage), findsNothing);
      expect(find.byType(RoleCheckBlockedPage), findsNothing);
    },
  );

  testWidgets(
    'client, enabled == true -> ClientHomePage, jamais HomePage (repos artisan non mockés — un montage accidentel ferait planter le test)',
    (tester) async {
      final fake = _FakeClientPortalRepository()..onGetPortal = () => _portal(enabled: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientPortalRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClientHomePage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    },
  );

  testWidgets(
    'client, enabled == false -> ClientDisabledPage, jamais la liste de prestations ni HomePage',
    (tester) async {
      final fake = _FakeClientPortalRepository()..onGetPortal = () => _portal(enabled: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientPortalRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ClientDisabledPage), findsOneWidget);
      expect(find.text('Votre accès a été désactivé par votre artisan.'), findsOneWidget);
      expect(find.byType(ClientHomePage), findsNothing);
      expect(find.byType(HomePage), findsNothing);
    },
  );

  testWidgets(
    'permission-denied -> écran de blocage, avec le code et les boutons Réessayer + Se déconnecter',
    (tester) async {
      final fake = _FakeClientPortalRepository()
        ..throwOnGetPortal = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientPortalRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RoleCheckBlockedPage), findsOneWidget);
      expect(find.textContaining('permission-denied'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Réessayer'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Se déconnecter'), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(ClientHomePage), findsNothing);
    },
  );

  testWidgets(
    'erreur autre que permission-denied (unavailable) -> route quand même vers HomePage, jamais un blocage',
    (tester) async {
      final fake = _FakeClientPortalRepository()
        ..throwOnGetPortal = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientPortalRepositoryProvider.overrideWithValue(fake),
            ..._artisanHomePageOverrides(),
          ],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(RoleCheckBlockedPage), findsNothing);
      expect(find.byType(ClientHomePage), findsNothing);
    },
  );

  testWidgets(
    'timeout 15s (le filet) -> route vers HomePage, jamais un blocage infini',
    (tester) async {
      final fake = _FakeClientPortalRepository()..hangOnGetPortal = Completer<ClientPortal?>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clientPortalRepositoryProvider.overrideWithValue(fake),
            ..._artisanHomePageOverrides(),
          ],
          child: const MaterialApp(home: PostAuthRoleRouter(uid: _uid)),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Avance l'horloge virtuelle au-delà des 15s du timeout.
      await tester.pump(const Duration(seconds: 16));
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(RoleCheckBlockedPage), findsNothing);
    },
  );
}
