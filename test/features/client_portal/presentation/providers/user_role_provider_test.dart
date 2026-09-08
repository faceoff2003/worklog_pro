// C-PORTAL.7 — decideRoleRoute() est une fonction pure (aucun Firebase, aucun
// widget) : c'est le seul endroit où la décision "quel écran pour quel état"
// est prise, testable sans émulateur ni AVD.
//
// Règle révisée le 2026-09-08, après le bug réel de désérialisation
// (createdAt Timestamp vs String) qui a montré que "tout sauf
// permission-denied -> artisan" routait aussi les erreurs de CODE vers
// artisan — pas seulement les pannes réseau visées. Désormais : SEULES les
// erreurs réseau identifiées (unavailable, deadline-exceeded, cancelled,
// TimeoutException) routent vers artisan. Tout le reste bloque, y compris
// permission-denied, unauthenticated, et les erreurs de désérialisation.

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

  group('error — seules les erreurs réseau routent vers artisan, tout le reste bloque', () {
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

    test('FirebaseException(code: permission-denied) -> blocked', () {
      final error = FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
    });

    test(
      'FirebaseException(code: unauthenticated) -> blocked, PAS artisan — un token invalide est un problème '
      'd\'identité, pas un problème réseau, ne doit jamais être masqué',
      () {
        final error = FirebaseException(plugin: 'cloud_firestore', code: 'unauthenticated');
        expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
      },
    );

    test(
      'erreur de désérialisation (TypeError, le bug réel du 2026-09-08) -> blocked, PAS artisan — '
      'c\'est exactement le bug qui a motivé cette révision de la règle',
      () {
        final error = TypeError();
        expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
      },
    );

    test('code d\'erreur totalement imprévu (ni FirebaseException, ni TimeoutException) -> blocked, jamais artisan', () {
      final error = Exception('quelque chose de jamais vu');
      expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
    });

    test(
      'FirebaseException dont le code n\'est pas dans la liste réseau (ex. not-found) -> blocked',
      () {
        final error = FirebaseException(plugin: 'cloud_firestore', code: 'not-found');
        expect(decideRoleRoute(AsyncValue.error(error, StackTrace.empty)), RoleRoute.blocked);
      },
    );
  });
}
