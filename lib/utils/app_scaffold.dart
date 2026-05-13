import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';

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
      mobile: _MobileScaffold(child: child, currentIndex: currentIndex),
      web: _WebScaffold(child: child, currentIndex: currentIndex),
    );
  }
}

class _MobileScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  const _MobileScaffold({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.divider)),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: AppTheme.surfaceCard,
          selectedItemColor: AppTheme.accentRed,
          unselectedItemColor: const Color(0xFF555555),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.book_outlined), activeIcon: Icon(Icons.book), label: 'Álbum'),
            BottomNavigationBarItem(icon: Icon(Icons.group_outlined), activeIcon: Icon(Icons.group), label: 'Pollas'),
            BottomNavigationBarItem(icon: Icon(Icons.confirmation_number_outlined), activeIcon: Icon(Icons.confirmation_number), label: 'Tickets'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Perfil'),
          ],
          onTap: (index) => _onTap(context, index),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/album', '/pollas', '/tickets', '/profile'];
    if (index < routes.length) context.go(routes[index]);
  }
}

class _WebScaffold extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  const _WebScaffold({required this.child, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          AppSidebar(currentIndex: currentIndex),
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
    );
  }
}

class AppSidebar extends StatelessWidget {
  final int currentIndex;
  const AppSidebar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppTheme.surfaceCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Logo area ─────────────────────────────────
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.divider)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ESPACIO PARA LOGO WCH (imagen)
                // Reemplaza este Container con: Image.asset('assets/logo_wch.png', height: 48)
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_soccer, color: AppTheme.accentRed, size: 28),
                  ),
                ),
                // NOTA: ↑ Reemplaza con Image.asset('assets/logo_wch.png')
                const SizedBox(height: 12),
                const Text(
                  'WORLD CUP\nHUB',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Navegación principal ───────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _SidebarItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Inicio', active: currentIndex == 0, onTap: () => context.go('/home')),
                  _SidebarItem(icon: Icons.book_outlined, activeIcon: Icons.book, label: 'Mi Álbum', active: currentIndex == 1, onTap: () => context.go('/album')),
                  _SidebarItem(icon: Icons.group_outlined, activeIcon: Icons.group, label: 'Mis Pollas', active: currentIndex == 2, onTap: () => context.go('/pollas')),
                  _SidebarItem(icon: Icons.confirmation_number_outlined, activeIcon: Icons.confirmation_number, label: 'Tickets', active: currentIndex == 3, onTap: () => context.go('/tickets')),
                ],
              ),
            ),
          ),

          // ── Footer sidebar ─────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.divider)),
            ),
            child: Column(
              children: [
                _SidebarItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Mi Perfil', active: currentIndex == 4, onTap: () => context.go('/profile')),
                _SidebarItem(icon: Icons.logout, activeIcon: Icons.logout, label: 'Cerrar Sesión', onTap: () => context.go('/login')),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border(bottom: BorderSide(color: AppTheme.divider)),
      ),
      child: Row(
        children: [
          // Tag de evento en vivo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accentRed.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.accentRed.withOpacity(0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, color: AppTheme.accentRed, size: 8),
                SizedBox(width: 6),
                Text('MUNDIAL 2026', style: TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppTheme.onSurfaceMuted),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppTheme.divider),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.person, color: Colors.white, size: 16),
                ),
                SizedBox(width: 10),
                Text('Usuario', style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
                SizedBox(width: 8),
                Icon(Icons.keyboard_arrow_down, color: AppTheme.onSurfaceMuted, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.active = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppTheme.accentRed.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: active ? Border.all(color: AppTheme.accentRed.withOpacity(0.3)) : null,
        ),
        child: Row(
          children: [
            Icon(
              active ? activeIcon : icon,
              color: active ? AppTheme.accentRed : AppTheme.onSurfaceMuted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppTheme.onSurfaceMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            if (active) ...[
              const Spacer(),
              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppTheme.accentRed, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}
