import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

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
                onPressed: () {},
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

          // Pollas activas (scroll horizontal)
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

          // Próximos cierres de pronóstico
          const Text('PRÓXIMOS CIERRES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          ...List.generate(2, (i) => _MatchPredictionCard(index: i)),
          const SizedBox(height: 32),

          // Ranking global
          const Text('RANKING GLOBAL', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
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
    final colors = [AppTheme.accentBlue, AppTheme.accentGreen, AppTheme.accentRed];
    final color = colors[index % colors.length];
    return Container(
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
              Text('Grupo ${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
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
          // Match info
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
          // Botón predicción
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 11),
            ),
            child: const Text('PREDECIR'),
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
      {'pos': 5, 'user': 'copa2026', 'pts': 60, 'medal': ''},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: [
          // Header tabla
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                SizedBox(width: 36, child: Text('POS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
                const Expanded(child: Text('USUARIO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5))),
                Text('PUNTOS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.divider),
          ...data.map((row) {
            final isTop3 = (row['pos'] as int) <= 3;
            final colors = [AppTheme.accentYellow, Color(0xFFAAAAAA), Color(0xFFCD7F32)];
            final rankColor = isTop3 ? colors[(row['pos'] as int) - 1] : AppTheme.onSurfaceMuted;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isTop3 ? rankColor.withOpacity(0.05) : Colors.transparent,
                border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      row['medal'] as String != '' ? row['medal'] as String : '#${row['pos']}',
                      style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(row['user'] as String, style: TextStyle(color: isTop3 ? Colors.white : AppTheme.onSurface, fontWeight: isTop3 ? FontWeight.w700 : FontWeight.w400)),
                  ),
                  Text('${row['pts']} pts', style: TextStyle(color: rankColor, fontWeight: FontWeight.w900, fontSize: 15)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
