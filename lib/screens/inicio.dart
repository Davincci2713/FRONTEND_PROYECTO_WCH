import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class Inicio extends StatelessWidget {
  const Inicio({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BIENVENIDO DE NUEVO',
                      style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Fanático', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.accentRed.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: AppTheme.accentRed, size: 8),
                    SizedBox(width: 6),
                    Text('EN VIVO', style: TextStyle(color: AppTheme.accentRed, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Hero banner - espacio para imagen/estadio
          // ESPACIO BANNER: reemplaza el Container con tu imagen o widget
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF001a0e), Color(0xFF0a1020), Color(0xFF1a000a)],
              ),
            ),
            child: Stack(
              children: [
                // NOTA: Reemplaza con Image.asset('assets/estadio.jpg', fit: BoxFit.cover)
                const Center(child: Icon(Icons.stadium, size: 80, color: Color(0x20FFFFFF))),
                // Overlay con contenido
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        color: AppTheme.accentRed,
                        child: const Text('¿QUIERES IR A UN PARTIDO?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.go('/tickets'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        child: const Text('RESERVA YA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Accesos rápidos
          const Text('ACCESOS RÁPIDOS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final cols = constraints.maxWidth > 600 ? 3 : 1;
            if (cols == 3) {
              return Row(
                children: [
                  Expanded(child: _QuickCard(title: 'Próximos Partidos', icon: Icons.calendar_month, color: AppTheme.accentBlue, onTap: () {})),
                  const SizedBox(width: 16),
                  Expanded(child: _QuickCard(title: 'Mi Álbum', icon: Icons.book, color: AppTheme.accentGreen, onTap: () => context.go('/album'))),
                  const SizedBox(width: 16),
                  Expanded(child: _QuickCard(title: 'Mis Pollas', icon: Icons.group, color: AppTheme.accentYellow, textColor: Colors.black, onTap: () => context.go('/pollas'))),
                ],
              );
            }
            return Column(
              children: [
                _QuickCard(title: 'Próximos Partidos', icon: Icons.calendar_month, color: AppTheme.accentBlue, onTap: () {}),
                const SizedBox(height: 12),
                _QuickCard(title: 'Mi Álbum', icon: Icons.book, color: AppTheme.accentGreen, onTap: () => context.go('/album')),
                const SizedBox(height: 12),
                _QuickCard(title: 'Mis Pollas', icon: Icons.group, color: AppTheme.accentYellow, textColor: Colors.black, onTap: () => context.go('/pollas')),
              ],
            );
          }),
          const SizedBox(height: 32),

          // Noticias del Mundial
          Row(
            children: [
              const Text('NOTICIAS DEL MUNDIAL', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
              const Spacer(),
              TextButton(onPressed: () {}, child: const Text('Ver todo', style: TextStyle(color: AppTheme.accentRed, fontSize: 12))),
            ],
          ),
          const SizedBox(height: 12),
          ...List.generate(3, (i) => _NewsItem(index: i)),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.icon,
    required this.color,
    this.textColor = Colors.white,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('Ver más', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.onSurfaceMuted, size: 14),
          ],
        ),
      ),
    );
  }
}

class _NewsItem extends StatelessWidget {
  final int index;
  const _NewsItem({required this.index});

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Confirmadas las sedes del Grupo A — México, CDMX',
      'Colombia clasifica con récord histórico para 2026',
      'Venta de entradas Fase 2: Todo lo que debes saber',
    ];
    final tags = ['SEDES', 'CLASIFICACIÓN', 'TICKETS'];
    final colors = [AppTheme.accentBlue, AppTheme.accentGreen, AppTheme.accentYellow];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          // ESPACIO IMAGEN NOTICIA: reemplaza con Image.network(...)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.article, color: AppTheme.onSurfaceMuted, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: colors[index % colors.length].withOpacity(0.2),
                  child: Text(tags[index % tags.length], style: TextStyle(color: colors[index % colors.length], fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
                const SizedBox(height: 6),
                Text(titles[index % titles.length], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: AppTheme.onSurfaceMuted, size: 14),
        ],
      ),
    );
  }
}
