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

// ── Header mobile: nombre + monedas ──────────────────────────────────────────
class _MobileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser ?? {};
    final firstName = user['firstName'] as String? ?? '';
    if (firstName.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0xFF00341C),
            child: Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Text(
            firstName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Spacer(),
          const CoinsIndicator(),
        ],
      ),
    );
  }
}
