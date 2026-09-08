import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_disabled_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/client_home_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/pages/role_check_blocked_page.dart';
import 'package:worklog_pro/features/client_portal/presentation/providers/user_role_provider.dart';
import 'package:worklog_pro/features/home/presentation/pages/home_page.dart';

/// Seul point de décision de rôle de toute l'app — AuthWrapper délègue ici
/// dès qu'un utilisateur est authentifié, avant de choisir quel écran
/// construire. Aucune deuxième logique de rôle ailleurs (notamment pas dans
/// HomePage) : un client ne doit jamais atteindre HomePage du tout, sauf le
/// résiduel hors-ligne documenté sur decideRoleRoute()/CONTEXT.md.
class PostAuthRoleRouter extends ConsumerWidget {
  final String uid;
  const PostAuthRoleRouter({super.key, required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(userPortalProvider(uid));
    switch (decideRoleRoute(state)) {
      case RoleRoute.checking:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case RoleRoute.artisan:
        return const HomePage();
      case RoleRoute.clientEnabled:
        return const ClientHomePage();
      case RoleRoute.clientDisabled:
        return const ClientDisabledPage();
      case RoleRoute.blocked:
        return RoleCheckBlockedPage(uid: uid, error: state.error!);
    }
  }
}
