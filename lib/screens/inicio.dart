import 'package:flutter/material.dart';
import '../services/auth/auth.dart';
import '../services/album_service.dart';
import '../services/match_service.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final MatchService _matchService = MatchService();
  int _upcomingMatchesCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final matches = await _matchService.getAllMatches();
      if (mounted) {
        setState(() {
          _upcomingMatchesCount = matches.length;
        });
      }
    } catch (e) {
      // Ignorar error de carga de dashboard por ahora
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser ?? {};
    final firstName = user['firstName'] ?? 'Fanático';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bienvenido de nuevo, $firstName', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth = constraints.maxWidth < 300 ? constraints.maxWidth : 300;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: cardWidth, child: DashboardCard(title: 'Próximos Partidos', subtitle: '$_upcomingMatchesCount programados', icon: Icons.calendar_month)),
                  SizedBox(width: cardWidth, child: const DashboardCard(title: 'Mi Álbum', subtitle: 'Ver colección', icon: Icons.book)),
                  SizedBox(width: cardWidth, child: const DashboardCard(title: 'Mis Comunidades', subtitle: 'Ver ranking', icon: Icons.group)),
                ],
              );
            }
          ),
          const SizedBox(height: 32),
          Text('Noticias del Mundial', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('Noticias y Alertas de FIFA')),
          ),
        ],
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardCard({required this.title, required this.subtitle, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: const Color(0xFF00341C)),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Indicador de monedas reutilizable ────────────────────────────────────────
class CoinsIndicator extends StatefulWidget {
  final Color textColor;
  const CoinsIndicator({super.key, this.textColor = Colors.black87});
  @override
  State<CoinsIndicator> createState() => _CoinsIndicatorState();
}

class _CoinsIndicatorState extends State<CoinsIndicator> {
  int? _coins;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    try {
      final data = await AlbumService().getUserAlbum(uid);
      if (mounted) setState(() => _coins = (data['coins'] as num?)?.toInt());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🪙', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            _coins == null ? '—' : '$_coins',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.amber.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top bar (web) ─────────────────────────────────────────────────────────────
class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser ?? {};
    final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Usuario' : fullName;

    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 12),
          const CoinsIndicator(),
          const SizedBox(width: 12),
          IconButton(icon: const Icon(Icons.notifications_outlined), onPressed: () {}),
          const SizedBox(width: 8),
          const CircleAvatar(
            backgroundColor: Color(0xFF00341C),
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
