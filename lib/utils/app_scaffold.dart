import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';

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
    context.watch<ThemeProvider>();
    return ResponsiveLayout(
      mobile: _MobileScaffold(currentIndex: currentIndex, child: child),
      web: _WebScaffold(currentIndex: currentIndex, child: child),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────
class _MobileScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  const _MobileScaffold({required this.currentIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: const _NotificationsDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _MobileHeader(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border, width: 2)),
        ),
        child: _AppBottomNav(currentIndex: currentIndex),
      ),
    );
  }
}

class _AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const _AppBottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (i) {
        const routes = ['/home', '/album', '/pollas', '/comunidades', '/tickets', '/profile'];
        if (i < routes.length) context.go(routes[i]);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'INICIO',
        ),
        NavigationDestination(
          icon: Icon(Icons.book_outlined),
          selectedIcon: Icon(Icons.book_rounded),
          label: 'ÁLBUM',
        ),
        NavigationDestination(
          icon: Icon(Icons.sports_soccer_outlined),
          selectedIcon: Icon(Icons.sports_soccer),
          label: 'POLLAS',
        ),
        NavigationDestination(
          icon: Icon(Icons.groups_outlined),
          selectedIcon: Icon(Icons.groups_rounded),
          label: 'GRUPOS',
        ),
        NavigationDestination(
          icon: Icon(Icons.confirmation_number_outlined),
          selectedIcon: Icon(Icons.confirmation_number),
          label: 'TICKETS',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'PERFIL',
        ),
      ],
    );
  }
}

// ── Web ───────────────────────────────────────────────────────────────────────
class _WebScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  const _WebScaffold({required this.currentIndex, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      endDrawer: const _NotificationsDrawer(),
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.border, width: 2)),
            ),
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
    );
  }
}

// ── Sidebar ───────────────────────────────────────────────────────────────────
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  const AppSidebar({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: 32),
          // Logo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.onPrimary, width: 2),
                  ),
                  child: Icon(Icons.sports_soccer, color: AppColors.onPrimary, size: 24),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'WCH.26',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.text,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 48),
          _SidebarSection(label: 'PRINCIPAL'),
          _SidebarItem(icon: Icons.home_rounded,      label: 'INICIO',       active: currentIndex == 0, onTap: () => context.go('/home')),
          _SidebarItem(icon: Icons.book_rounded,       label: 'MI ÁLBUM',     active: currentIndex == 1, onTap: () => context.go('/album')),
          _SidebarItem(icon: Icons.sports_soccer,      label: 'MIS POLLAS',   active: currentIndex == 2, onTap: () => context.go('/pollas')),
          SizedBox(height: 16),
          _SidebarSection(label: 'SOCIAL'),
          _SidebarItem(icon: Icons.groups_rounded,     label: 'COMUNIDADES',  active: currentIndex == 3, onTap: () => context.go('/comunidades')),
          _SidebarItem(icon: Icons.confirmation_number,label: 'TICKETS',      active: currentIndex == 4, onTap: () => context.go('/tickets')),
          const Spacer(),
          Divider(),
          _SidebarItem(icon: Icons.person_rounded,  label: 'MI PERFIL',   active: currentIndex == 5, onTap: () => context.go('/profile')),
          _SidebarItem(icon: Icons.logout_rounded,  label: 'CERRAR SESIÓN', onTap: () => context.go('/login')),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SidebarSection extends StatelessWidget {
  final String label;
  const _SidebarSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
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
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: active ? Colors.black : Colors.transparent, width: 2),
            top: BorderSide(color: active ? Colors.black : Colors.transparent, width: 2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: active ? Colors.black : AppColors.textMuted, size: 20),
            SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: active ? Colors.black : AppColors.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            if (active)
              Icon(Icons.arrow_forward, color: AppColors.onPrimary, size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Header ─────────────────────────────────────────────────────────────
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
            imageProvider = MemoryImage(base64Decode(profilePicture.split(',').last));
          } else if (profilePicture.startsWith('http')) {
            imageProvider = NetworkImage(profilePicture);
          }
        }

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: Row(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.text, width: 2),
                ),
                child: imageProvider != null
                    ? Image(image: imageProvider, width: 32, height: 32, fit: BoxFit.cover)
                    : Container(
                        width: 32,
                        height: 32,
                        color: AppColors.primary,
                        child: Icon(Icons.person, color: AppColors.onPrimary, size: 20),
                      ),
              ),
              SizedBox(width: 12),
              Text(
                firstName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              // Notif badge
              Builder(
                builder: (ctx) => ValueListenableBuilder<int>(
                  valueListenable: _notifCount,
                  builder: (_, count, __) => GestureDetector(
                    onTap: () {
                      _notifCount.value = 0;
                      Scaffold.of(ctx).openEndDrawer();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: count > 0 ? AppColors.primary : Colors.transparent,
                            border: Border.all(color: count > 0 ? AppColors.primary : AppColors.border, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              count > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                              size: 20,
                              color: count > 0 ? Colors.black : AppColors.text,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.background, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: GoogleFonts.dmSans(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
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

// ── Top bar (web) ─────────────────────────────────────────────────────────────
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) {
        final user = AuthService().currentUser ?? {};
        final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        final displayName = fullName.isEmpty ? 'USUARIO' : fullName.toUpperCase();
        final profilePicture = user['profilePicture'] as String?;
        ImageProvider? imageProvider;
        if (profilePicture != null && profilePicture.isNotEmpty) {
          if (profilePicture.startsWith('data:image')) {
            imageProvider = MemoryImage(base64Decode(profilePicture.split(',').last));
          } else if (profilePicture.startsWith('http')) {
            imageProvider = NetworkImage(profilePicture);
          }
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                displayName,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.text,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(width: 24),
              Builder(
                builder: (ctx) => ValueListenableBuilder<int>(
                  valueListenable: _notifCount,
                  builder: (_, count, __) => GestureDetector(
                    onTap: () {
                      _notifCount.value = 0;
                      Scaffold.of(ctx).openEndDrawer();
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: count > 0 ? AppColors.primary : Colors.transparent,
                            border: Border.all(color: count > 0 ? AppColors.primary : AppColors.border, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              count > 0 ? Icons.notifications_active : Icons.notifications_outlined,
                              size: 24,
                              color: count > 0 ? Colors.black : AppColors.text,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            top: -6,
                            right: -6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.background, width: 1.5),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: GoogleFonts.dmSans(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, height: 1),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.text, width: 2),
                ),
                child: imageProvider != null
                    ? Image(image: imageProvider, width: 44, height: 44, fit: BoxFit.cover)
                    : Container(
                        width: 44,
                        height: 44,
                        color: AppColors.primary,
                        child: Icon(Icons.person, color: AppColors.onPrimary, size: 24),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Notif meta ────────────────────────────────────────────────────────────────
({IconData icon, Color color, String? route}) _notifMeta(String? type) {
  return switch (type) {
    'trade' || 'trade_accepted' || 'trade_rejected' =>
      (icon: Icons.swap_horiz_rounded, color: AppColors.primary, route: '/trades'),
    'ticket' =>
      (icon: Icons.confirmation_number_rounded, color: const Color(0xFF00FFFF), route: '/tickets'),
    'packs' || 'album_milestone' =>
      (icon: Icons.style_rounded, color: const Color(0xFFFF00FF), route: '/album'),
    'community_like' || 'community_comment' || 'community_reply' =>
      (icon: Icons.groups_rounded, color: const Color(0xFFFF3333), route: '/comunidades'),
    'bet' || 'bet_result' =>
      (icon: Icons.sports_soccer_rounded, color: AppColors.text, route: '/pollas'),
    _ => (icon: Icons.notifications_rounded, color: AppColors.textMuted, route: null),
  };
}

String _timeAgo(String? iso) {
  if (iso == null) return '';
  try {
    final dt = DateTime.parse(iso).toLocal();
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'AHORA';
    if (diff.inMinutes < 60) return 'HACE ${diff.inMinutes} MIN';
    if (diff.inHours < 24) return 'HACE ${diff.inHours} H';
    if (diff.inDays < 7) return 'HACE ${diff.inDays} D';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) { return ''; }
}

// ── Notifications drawer ──────────────────────────────────────────────────────
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
    setState(() { _items = data; _loading = false; });
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
      width: 380,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.border, width: 2),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.onPrimary, width: 2),
                    ),
                    child: Icon(Icons.notifications_rounded, color: AppColors.onPrimary, size: 24),
                  ),
                  SizedBox(width: 16),
                  Text('NOTIFICACIONES', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -1)),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 28),
                    color: AppColors.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(),
            Expanded(
              child: _loading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _items.isEmpty
                      ? Center(
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: AppColors.border, width: 2),
                              ),
                              child: Icon(Icons.notifications_off_outlined, size: 32, color: AppColors.textMuted),
                            ),
                            SizedBox(height: 24),
                            Text('SIN NOTIFICACIONES', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                          ]),
                        )
                      : RefreshIndicator(
                          color: AppColors.onPrimary,
                          backgroundColor: AppColors.primary,
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => Divider(indent: 88, color: AppColors.borderLight),
                            itemBuilder: (_, i) {
                              final n = _items[i];
                              final meta = _notifMeta(n['notifType'] as String?);
                              return ListTile(
                                onTap: () => _onTap(n),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: meta.color.withValues(alpha: 0.15),
                                    border: Border.all(color: meta.color, width: 2),
                                  ),
                                  child: Icon(meta.icon, color: meta.color, size: 24),
                                ),
                                title: Text(
                                  n['title'] ?? '',
                                  style: GoogleFonts.dmSans(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(height: 4),
                                    Text(
                                      n['message'] ?? '',
                                      style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      _timeAgo(n['createdAt'] as String?),
                                      style: GoogleFonts.dmSans(color: AppColors.accentText, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                                    ),
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
