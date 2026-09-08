// C-PORTAL.7 — decideRoleRoute() est une fonction pure (aucun Firebase, aucun
// widget) : c'est le seul endroit où la décision "quel écran pour quel état"
// est prise, testable sans émulateur ni AVD.
//
// Règle du 2026-09-08 (décision de William, après mesure empirique — voir
// user_role_provider.dart) : SEUL permission-denied bloque. Tout le reste
// route vers artisan, y compris un code d'erreur imprévu — jamais l'inverse.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worklog_pro/features/client_portal/domain/entities/client_portal.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/user_role_provider.dart';

ClientPortal _portal({required bool enabled}) => ClientPortal(
      portalUid: 'client-uid-1',
      artisanUid: 'artisan-uid-1',
      clientId: 'client-doc-1',
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('data — succès de getPortal()', () {
    test('null (aucun document) -> artisan', () {
      expect(decideRoleRoute(const AsyncValue.data(null)), RoleRoute.artisan);
    });

    test('trouvé, enabled == true -> clientEnabled', () {
      expect(decideRoleRoute(AsyncValue.data(_portal(enabled: true))), RoleRoute.clientEnabled);
    });

    test('trouvé, enabled == false -> clientDisabled', () {
      expect(decideRoleRoute(AsyncValue.data(_portal(enabled: false))), RoleRoute.clientDisabled);
    });
  });

  test('loading -> checking (écran d\'attente, ni artisan ni client)', () {
    expect(decideRoleRoute(const AsyncValue.loading()), RoleRoute.checking);
  });

  group('error — seul permission-denied bloque, tout le reste route vers artisan', () {
    test('FirebaseException(code: permission-denied) -> blocked', () {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
    });

    test('FirebaseException(code: unavailable) -> artisan (mesuré empiriquement, cas réel du terrain)', () {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
    });

    test('FirebaseException(code: deadline-exceeded) -> artisan', () {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'deadline-exceeded');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
    });

    test('FirebaseException(code: cancelled) -> artisan', () {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'cancelled');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
    });

    test('TimeoutException (le filet 15s) -> artisan, jamais bloquant', () {
      final error = TimeoutException('25s dépassées');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
    });

    test('code d\'erreur totalement imprévu (ni FirebaseException, ni TimeoutException) -> artisan, jamais blocked', () {
      final error = Exception('quelque chose de jamais vu');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
    });

    test(
      'FirebaseException dont le code est autre chose que permission-denied (ex. faute de frappe future) -> artisan',
      () {
        final error = FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.artisan);
      },
    );
  });
}
