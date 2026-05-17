import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/screens/inicio.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';

// Contador global de notificaciones no leídas; se resetea al abrir el drawer.
final _notifCount = ValueNotifier<int>(0);

class AppScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: Scaffold(
        endDrawer: const _NotificationsDrawer(),
        body: SafeArea(
          child: Column(
            children: [
              _MobileHeader(),
              Expanded(child: child),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 10,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Álbum'),
            BottomNavigationBarItem(icon: Icon(Icons.sports_soccer), label: 'Pollas'),
            BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Comunidades'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number), label: 'Tickets'),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
          ],
          onTap: (index) => _onTap(context, index),
        ),
      ),
      web: Scaffold(
        endDrawer: const _NotificationsDrawer(),
        body: Row(
          children: [
            Container(
              width: 280,
              color: Theme.of(context).colorScheme.primary,
              child: AppSidebar(currentIndex: currentIndex),
            ),
            Expanded(
              child: Column(
                children: [
                  const AppTopBar(),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/album', '/pollas', '/comunidades', '/tickets', '/profile'];
    if (index < routes.length) context.go(routes[index]);
  }
}

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  const AppSidebar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Icon(Icons.sports_soccer, size: 64, color: Colors.white),
        const SizedBox(height: 48),
        _SidebarItem(icon: Icons.home, label: 'Inicio', active: currentIndex == 0, onTap: () => context.go('/home')),
        _SidebarItem(icon: Icons.book, label: 'Mi Álbum', active: currentIndex == 1, onTap: () => context.go('/album')),
        _SidebarItem(icon: Icons.sports_soccer, label: 'Mis Pollas', active: currentIndex == 2, onTap: () => context.go('/pollas')),
        _SidebarItem(icon: Icons.groups, label: 'Comunidades', active: currentIndex == 3, onTap: () => context.go('/comunidades')),
        _SidebarItem(icon: Icons.confirmation_number, label: 'Tickets', active: currentIndex == 4, onTap: () => context.go('/tickets')),
        const Spacer(),
        _SidebarItem(icon: Icons.person, label: 'Mi Perfil', active: currentIndex == 5, onTap: () => context.go('/profile')),
        _SidebarItem(icon: Icons.logout, label: 'Cerrar Sesión', onTap: () => context.go('/login')),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: active ? Colors.white : Colors.white70),
      title: Text(label, style: TextStyle(color: active ? Colors.white : Colors.white70, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      onTap: onTap,
    );
  }
}

// ── Header mobile: nombre + campana ──────────────────────────────────────────
class _MobileHeader extends StatefulWidget {
  @override
  State<_MobileHeader> createState() => _MobileHeaderState();
}

class _MobileHeaderState extends State<_MobileHeader> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!AuthService().isAuthenticated) return;
    try {
      final items = await AuthService().getNotifications();
      _notifCount.value = items.length;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) {
        final user = AuthService().currentUser ?? {};
        final firstName = user['firstName'] as String? ?? '';
        if (firstName.isEmpty) return const SizedBox.shrink();

        final profilePicture = user['profilePicture'] as String?;
        ImageProvider? imageProvider;
        if (profilePicture != null && profilePicture.isNotEmpty) {
          if (profilePicture.startsWith('data:image')) {
            final base64Str = profilePicture.split(',').last;
            imageProvider = MemoryImage(base64Decode(base64Str));
          } else if (profilePicture.startsWith('http')) {
            imageProvider = NetworkImage(profilePicture);
          }
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFF00341C),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, color: Colors.white, size: 15)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(firstName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Builder(
                builder: (ctx) => ValueListenableBuilder<int>(
                  valueListenable: _notifCount,
                  builder: (_, count, __) => Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          _notifCount.value = 0;
                          Scaffold.of(ctx).openEndDrawer();
                        },
                      ),
                      if (count > 0)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              count > 99 ? '99+' : '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Utilidades de notificaciones ──────────────────────────────────────────────
({IconData icon, Color color, String? route}) _notifMeta(String? type) {
  return switch (type) {
    'trade' || 'trade_accepted' || 'trade_rejected' =>
      (icon: Icons.swap_horiz, color: const Color(0xFF00341C), route: '/trades'),
    'ticket' =>
      (icon: Icons.confirmation_number_outlined, color: const Color(0xFF1565C0), route: '/tickets'),
    'packs' || 'album_milestone' =>
      (icon: Icons.style_outlined, color: const Color(0xFFE65100), route: '/album'),
    'community_like' || 'community_comment' || 'community_reply' =>
      (icon: Icons.groups_outlined, color: const Color(0xFF6A1B9A), route: '/comunidades'),
    'bet' || 'bet_result' =>
      (icon: Icons.sports_soccer_outlined, color: const Color(0xFF00796B), route: '/pollas'),
    _ => (icon: Icons.notifications_outlined, color: Colors.grey.shade600, route: null),
  };
}

String _timeAgo(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'ahora';
    if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'hace ${diff.inHours} h';
    if (diff.inDays < 7) return 'hace ${diff.inDays} d';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '';
  }
}

// ── Drawer de notificaciones ──────────────────────────────────────────────────
class _NotificationsDrawer extends StatefulWidget {
  const _NotificationsDrawer();
  @override
  State<_NotificationsDrawer> createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<_NotificationsDrawer> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await AuthService().getNotifications();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  void _onTap(dynamic n) {
    final meta = _notifMeta(n['notifType'] as String?);
    Navigator.pop(context);
    if (meta.route != null) context.push(meta.route!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: 340,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(children: [
                Text('Notificaciones',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.notifications_off_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('Sin notificaciones',
                                style: TextStyle(color: Colors.grey.shade500)),
                          ]),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, indent: 56, color: Colors.grey.shade200),
                            itemBuilder: (_, i) {
                              final n = _items[i];
                              final meta = _notifMeta(n['notifType'] as String?);
                              final timeStr = _timeAgo(n['createdAt'] as String?);
                              return ListTile(
                                onTap: () => _onTap(n),
                                leading: CircleAvatar(
                                  backgroundColor: meta.color.withOpacity(0.1),
                                  child: Icon(meta.icon, color: meta.color, size: 20),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: Colors.black87),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n['message'] ?? '',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey.shade700),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (timeStr.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(timeStr,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade400)),
                                    ],
                                  ],
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
