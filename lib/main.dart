import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:frontend_proyecto/utils/app_scaffold.dart';
import 'package:frontend_proyecto/screens/login.dart';
import 'package:frontend_proyecto/screens/registro_de_usuario.dart';
import 'package:frontend_proyecto/screens/inicio.dart';
import 'package:frontend_proyecto/screens/profile.dart';
import 'package:frontend_proyecto/screens/album.dart';
import 'package:frontend_proyecto/screens/pollas.dart';
import 'package:frontend_proyecto/screens/tickets.dart';
import 'package:frontend_proyecto/screens/open_pack.dart';
import 'package:frontend_proyecto/screens/RecuperarContrasena.dart';
import 'package:frontend_proyecto/screens/backoffice.dart';

void main() {
  runApp(const MyApp());
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/login',
      routes: [
        // ── Rutas sin scaffold (flujo auth y especiales) ──────────────────
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          builder: (context, state) => const RegistroDeUsuario(),
        ),
        GoRoute(
          path: '/recover',
          builder: (context, state) => const RecuperarContrasena(),
        ),
        GoRoute(
          path: '/open-pack',
          builder: (context, state) => const OpenPackScreen(),
        ),
        GoRoute(
          path: '/backoffice',
          builder: (context, state) => const BackofficePanel(),
        ),

        // ── Shell con navegación principal ────────────────────────────────
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            int index = 0;
            if (state.fullPath == '/home') {
              index = 0;
            } else if (state.fullPath == '/album') {
              index = 1;
            } else if (state.fullPath == '/pollas') {
              index = 2;
            } else if (state.fullPath == '/tickets') {
              index = 3;
            } else if (state.fullPath == '/profile') {
              index = 4;
            }
            return AppScaffold(currentIndex: index, child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              pageBuilder: (context, state) => const NoTransitionPage(child: Inicio()),
            ),
            GoRoute(
              path: '/album',
              pageBuilder: (context, state) => const NoTransitionPage(child: AlbumScreen()),
            ),
            GoRoute(
              path: '/pollas',
              pageBuilder: (context, state) => const NoTransitionPage(child: PollasScreen()),
            ),
            GoRoute(
              path: '/tickets',
              pageBuilder: (context, state) => const NoTransitionPage(child: TicketsScreen()),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'World Cup Hub',
      theme: AppTheme.darkTheme,   // ← Nuevo tema oscuro
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
