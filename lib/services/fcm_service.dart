import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/utils/app_scaffold.dart' show refreshNotificationCount;

@pragma('vm:entry-point')
Future<void> _backgroundMessageHandler(RemoteMessage message) async {
  // FCM muestra la notificación automáticamente en background/terminated
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;
  GoRouter? _router;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setRouter(GoRouter router, GlobalKey<NavigatorState> navigatorKey) {
    _router = router;
    _navigatorKey = navigatorKey;
  }

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_backgroundMessageHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (granted) {
      await _syncToken();
    }

    // iOS: mostrar notificaciones con la app en primer plano
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Re-registra el token si cambia (FCM lo rota ocasionalmente)
    _messaging.onTokenRefresh.listen((token) {
      if (AuthService().isAuthenticated) {
        AuthService().registerFcmToken(token);
      }
    });

    // App en foreground: mostrar banner in-app (Android no muestra notificación del sistema)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Foreground: ${message.notification?.title} — ${message.notification?.body}');
      }
      _showInAppBanner(message);
      refreshNotificationCount(); // Real-time notification badge update!
    });

    // App en background: usuario toca la notificación
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _navigateFromMessage(message);
    });

    // App terminada: usuario toca la notificación que la abrió
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Esperar que el árbol de widgets esté listo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFromMessage(initial);
      });
    }

    AuthService().addListener(_onAuthChanged);
  }

  void _navigateFromMessage(RemoteMessage message) {
    final notifType = message.data['notif_type'] ?? '';
    switch (notifType) {
      case 'trade':
        _router?.push('/trades');
      case 'bet':
        _router?.push('/pollas');
      case 'ticket':
        _router?.push('/tickets');
      case 'packs':
        _router?.push('/album');
    }
  }

  void _showInAppBanner(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final notifType = message.data['notif_type'] ?? '';
    final String? actionLabel;
    final String? actionRoute;
    switch (notifType) {
      case 'trade':
        actionLabel = 'Ver intercambio';
        actionRoute = '/trades';
      case 'bet':
        actionLabel = 'Ver apuesta';
        actionRoute = '/pollas';
      case 'ticket':
        actionLabel = 'Ver entrada';
        actionRoute = '/tickets';
      case 'packs':
        actionLabel = 'Abrir sobres';
        actionRoute = '/album';
      default:
        actionLabel = null;
        actionRoute = null;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notification.body != null)
              Text(notification.body!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: actionLabel != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: () => _router?.go(actionRoute!),
              )
            : null,
      ),
    );
  }

  void _onAuthChanged() {
    if (AuthService().isAuthenticated) {
      _syncToken();
    }
  }

  Future<void> _syncToken() async {
    if (!AuthService().isAuthenticated) return;
    try {
      // iOS requires the APNs token before FCM can issue a token.
      // On simulator or before APNs registers, getAPNSToken() returns null — skip silently.
      if (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS) {
        final apns = await _messaging.getAPNSToken();
        if (apns == null) return;
      }
      final token = await _messaging.getToken();
      if (token != null) {
        await AuthService().registerFcmToken(token);
      }
    } catch (e) {
      if (kDebugMode) print('[FCM] Token sync skipped: $e');
    }
  }
}
