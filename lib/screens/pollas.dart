import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:go_router/go_router.dart';

class PollasScreen extends StatelessWidget {
  const PollasScreen({super.key});

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
                  Text('PREDICCIONES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Mis Pollas', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () { context.push('/crear_polla'); },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('CREAR POLLA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Pollas activas (ESTA ES LA PARTE CLICKEABLE AHORA)
          const Text('POLLAS ACTIVAS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) => _PollCard(index: index),
            ),
          ),
          const SizedBox(height: 32),

          // Próximos cierres
          const Text('PRÓXIMOS CIERRES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...List.generate(2, (i) => _MatchPredictionCard(index: i)),
          const SizedBox(height: 32),

          // Ranking global (Ahora es informativo)
          const Text('LÍDERES GLOBALES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          _RankingTable(),
        ],
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  final int index;
  const _PollCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final names = ['Polla Oficina', 'Amigos FC', 'Familia'];
    final colors = [AppTheme.accentBlue, AppTheme.accentGreen, AppTheme.accentRed];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: () => context.push('/detalle_polla'), 
      borderRadius: BorderRadius.circular(8),
      child: Ink(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(names[index % names.length], 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: AppTheme.onSurfaceMuted),
              ],
            ),
            const Spacer(),
            Text('12 Participantes', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.emoji_events, color: color, size: 14),
                const SizedBox(width: 4),
                Text('Posición: 4°', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPredictionCard extends StatelessWidget {
  final int index;
  const _MatchPredictionCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {'home': 'COL', 'away': 'BRA', 'time': '2h 30min'},
      {'home': 'MEX', 'away': 'ARG', 'time': '5h 10min'},
    ];
    final m = matches[index % matches.length];

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CIERRA EN ${m['time']}', style: TextStyle(color: AppTheme.accentYellow, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                const SizedBox(height: 6),
                Text('${m['home']} vs ${m['away']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Aquí podrías abrir un modal para poner el marcador
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('PREDECIR', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _RankingTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final data = [
      {'pos': 1, 'user': 'juanito_co', 'pts': 100, 'medal': '🥇'},
      {'pos': 2, 'user': 'mariafan26', 'pts': 90, 'medal': '🥈'},
      {'pos': 3, 'user': 'mundialero', 'pts': 80, 'medal': '🥉'},
      {'pos': 4, 'user': 'futbolero7', 'pts': 70, 'medal': ''},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('POS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                const Expanded(child: Text('USUARIO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800))),
                Text('PUNTOS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          ...data.map((row) {
            final isTop3 = (row['pos'] as int) <= 3;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      row['medal'] != '' ? row['medal'] as String : '#${row['pos']}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(row['user'] as String, style: const TextStyle(color: Colors.white)),
                  ),
                  Text('${row['pts']} pts', style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w900)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}