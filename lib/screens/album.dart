import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 40, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MI COLECCIÓN', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Álbum Digital', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/open-pack'),
                icon: const Icon(Icons.style, size: 18),
                label: const Text('ABRIR SOBRE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Stats
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;
            final stats = [
              _StatData('COMPLETADO', '45%', AppTheme.accentGreen),
              _StatData('LÁMINAS', '250/600', AppTheme.accentBlue),
              _StatData('REPETIDAS', '12', AppTheme.accentYellow),
            ];
            if (isWide) {
              return Row(
                children: stats.map((s) => Expanded(child: Padding(
                  padding: EdgeInsets.only(right: s == stats.last ? 0 : 16),
                  child: _StatCard(data: s),
                ))).toList(),
              );
            }
            return Column(
              children: stats.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StatCard(data: s),
              )).toList(),
            );
          }),
          const SizedBox(height: 32),

          // Progreso
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('PROGRESO TOTAL', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                    const Spacer(),
                    const Text('250 / 600', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: 250 / 600,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.accentGreen),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Mis colecciones
          const Text('MIS COLECCIONES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 8,
            itemBuilder: (context, index) => _CollectionCard(index: index),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  const _StatData(this.label, this.value, this.color);
}

class _StatCard extends StatelessWidget {
  final _StatData data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: data.color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(data.label, style: TextStyle(color: data.color, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text(data.value, style: TextStyle(color: data.color, fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final int index;
  const _CollectionCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final completions = [0.3, 0.8, 0.5, 1.0, 0.2, 0.65, 0.45, 0.9];
    final pct = completions[index % completions.length];
    final color = pct == 1.0 ? AppTheme.accentYellow : (pct > 0.6 ? AppTheme.accentGreen : AppTheme.accentBlue);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: pct == 1.0 ? AppTheme.accentYellow.withOpacity(0.5) : AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ESPACIO IMAGEN BANDERA/SELECCIÓN
          // Reemplaza con Image.asset('assets/flags/flag_${index}.png', fit: BoxFit.cover)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(child: Icon(Icons.flag, size: 36, color: color.withOpacity(0.5))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selección ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text('${(pct * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
