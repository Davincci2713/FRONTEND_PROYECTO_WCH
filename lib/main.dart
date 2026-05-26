import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:frontend_proyecto/utils/app_scaffold.dart';
import 'package:frontend_proyecto/screens/login.dart';
import 'package:frontend_proyecto/screens/registro_de_usuario.dart';
import 'package:frontend_proyecto/screens/onboarding.dart';
import 'package:frontend_proyecto/screens/inicio.dart';
import 'package:frontend_proyecto/screens/profile.dart';
import 'package:frontend_proyecto/screens/album.dart';
import 'package:frontend_proyecto/screens/pollas.dart';
import 'package:frontend_proyecto/screens/admin_screen.dart';
import 'package:frontend_proyecto/screens/tickets.dart';
import 'package:frontend_proyecto/screens/open_pack.dart';
import 'package:frontend_proyecto/screens/album_progress.dart';
import 'package:frontend_proyecto/screens/comunidades.dart';
import 'package:frontend_proyecto/screens/group_detail.dart';
import 'package:frontend_proyecto/screens/trades.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/services/fcm_service.dart';
import 'package:frontend_proyecto/firebase_options.dart';

import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_proyecto/providers/album_provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,);
  await AuthService().initialize();

  // Inicializar el tema antes del primer frame para evitar parpadeo
  final prefs = await SharedPreferences.getInstance();
  AppColors.isLightMode = prefs.getBool('is_light_mode') ?? false;
  FCMService().setRouter(_router, _rootNavigatorKey);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AlbumProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MyApp(),
    ),
  );
  // FCM init after runApp — requestPermission() needs the Flutter UI to be active
  // so the iOS permission dialog can appear on top of the rendered app.
  FCMService().initialize();
}

final GlobalKey<NavigatorState> _rootNavigatorKey  = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final _auth = AuthService();

final GoRouter _router = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/home',
  refreshListenable: _auth,
  redirect: (context, state) {
    final loggedIn = _auth.isAuthenticated;
    final hasSeenOnboarding = _auth.hasSeenOnboarding;
    final isPublic = state.matchedLocation == '/login' ||
                     state.matchedLocation == '/register';
    

    if (!loggedIn && !isPublic) return '/login';

    if (loggedIn) {
      final int? userRoleId = _auth.idRole;
      final bool isAdmin = userRoleId == 1;

      if (isAdmin) {
        if (isPublic || state.matchedLocation == '/home' || state.matchedLocation == '/onboarding') {
          return '/admin';
        }
        return null;
      }

      //seguridad pa q no intenten entrar al backoffice los usuarios regulares
      if (state.matchedLocation == '/admin') {
        return '/home';
      }

      if (!hasSeenOnboarding && state.matchedLocation != '/onboarding') {
        return '/onboarding';
      } else if (hasSeenOnboarding && (isPublic || state.matchedLocation == '/onboarding')) {
        return '/home';
      }
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegistroDeUsuario(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/group-detail',
      builder: (context, state) {
        final group = state.extra as Map<String, dynamic>?;
        if (group == null) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => context.go('/comunidades'));
          return Scaffold(
              backgroundColor: AppColors.background,
              body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
        }
        return GroupDetailScreen(group: group);
      },
    ),
    GoRoute(
      path: '/open-pack',
      builder: (context, state) => const OpenPackScreen(),
    ),
    GoRoute(
      path: '/album-progress',
      builder: (context, state) => AlbumProgressScreen(
        initialTeam: state.extra as String?,
      ),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        int index = 0;
        if (state.fullPath == '/home') {
          index = 0;
        } else if (state.fullPath == '/album')       index = 1;
        else if (state.fullPath == '/pollas')      index = 2;
        else if (state.fullPath == '/comunidades') index = 3;
        else if (state.fullPath == '/tickets')     index = 4;
        else if (state.fullPath == '/profile')     index = 5;

        return AppScaffold(
          currentIndex: index,
          child: child,
        );
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
          path: '/comunidades',
          pageBuilder: (context, state) => const NoTransitionPage(child: ComunidadesScreen()),
        ),
        GoRoute(
          path: '/tickets',
          pageBuilder: (context, state) => const NoTransitionPage(child: TicketsScreen()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
        ),
        GoRoute(
          path: '/trades',
          pageBuilder: (context, state) => const MaterialPage(child: TradesScreen()),
        ),
      ],
      
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => const MaterialPage(
      child: AdminScreen(),
      fullscreenDialog: true, 
      ),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Sincronizar el getter estático de colores antes de construir la app
        AppColors.isLightMode = themeProvider.isLightMode;
        
        return MaterialApp.router(
          title: 'World Cup Hub',
          theme: AppTheme.currentTheme,
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
