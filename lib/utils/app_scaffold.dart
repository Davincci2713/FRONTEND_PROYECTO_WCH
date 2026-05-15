import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/screens/inicio.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';

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
class _MobileHeader extends StatelessWidget {
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
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Drawer de notificaciones ──────────────────────────────────────────────────
class _NotificationsDrawer extends StatefulWidget {
  const _NotificationsDrawer();
  @override
  State<_NotificationsDrawer> createState() => _NotificationsDrawerState();
}

class _NotificationsDrawerState extends State<_NotificationsDrawer> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    // Notificaciones del sistema (estáticas por ahora, extendible con API)
    setState(() {
      _items = [
        {'icon': Icons.sports_soccer, 'color': 0xFF00341C,
         'title': 'Copa Mundial 2026', 'body': 'Los partidos de la fase de grupos están disponibles para apostar.', 'time': 'Hace 2 h'},
        {'icon': Icons.style, 'color': 0xFFF57C00,
         'title': 'Álbum Digital', 'body': 'Tienes sobres disponibles. ¡Ábrelos para completar tu colección!', 'time': 'Hoy'},
        {'icon': Icons.confirmation_number, 'color': 0xFF1565C0,
         'title': 'Entradas disponibles', 'body': 'Hay entradas disponibles para los próximos partidos.', 'time': 'Hoy'},
      ];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(children: [
                Text('Notificaciones', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _items.isEmpty
                      ? const Center(child: Text('Sin notificaciones', style: TextStyle(color: Colors.grey)))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                          itemBuilder: (_, i) {
                            final n = _items[i];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Color(n['color'] as int).withOpacity(0.1),
                                child: Icon(n['icon'] as IconData, color: Color(n['color'] as int), size: 20),
                              ),
                              title: Text(n['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n['body'], style: const TextStyle(fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(n['time'], style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ]),
                              isThreeLine: true,
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
