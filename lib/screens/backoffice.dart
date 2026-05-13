import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class BackofficePanel extends StatelessWidget {
  const BackofficePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              color: AppTheme.accentRed,
              child: const Text('OPERADOR', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
            ),
            const SizedBox(width: 12),
            const Text('Panel de Control', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
          ],
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('GESTIÓN OPERATIVA', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 4),
            const Text('Dashboard', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 28),

            // Stats operativas
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              final stats = [
                _OpStat('ENTRADAS RESERVADAS', '1,250', AppTheme.accentBlue, Icons.confirmation_number_outlined),
                _OpStat('ALERTAS DE FRAUDE', '14', AppTheme.accentRed, Icons.warning_amber_outlined),
                _OpStat('SOPORTE PENDIENTE', '8', AppTheme.accentYellow, Icons.support_agent_outlined),
              ];
              if (isWide) {
                return Row(
                  children: stats.map((s) => Expanded(child: Padding(
                    padding: EdgeInsets.only(right: s == stats.last ? 0 : 16),
                    child: _OpStatCard(stat: s),
                  ))).toList(),
                );
              }
              return Column(
                children: stats.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _OpStatCard(stat: s),
                )).toList(),
              );
            }),
            const SizedBox(height: 32),

            // Incidentes
            Row(
              children: [
                const Text('INCIDENTES RECIENTES', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  color: AppTheme.accentRed.withOpacity(0.15),
                  child: const Text('3 ACTIVOS', style: TextStyle(color: AppTheme.accentRed, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...List.generate(3, (i) => _IncidentCard(index: i)),
            const SizedBox(height: 32),

            // Acciones
            const Text('ACCIONES OPERATIVAS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 16),
            _ActionButtons(),
          ],
        ),
      ),
    );
  }
}

class _OpStat {
  final String label, value;
  final Color color;
  final IconData icon;
  const _OpStat(this.label, this.value, this.color, this.icon);
}

class _OpStatCard extends StatelessWidget {
  final _OpStat stat;
  const _OpStatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stat.color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(stat.icon, color: stat.color, size: 22),
          const SizedBox(height: 12),
          Text(stat.value, style: TextStyle(color: stat.color, fontSize: 30, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(stat.label, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _IncidentCard extends StatelessWidget {
  final int index;
  const _IncidentCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final priorities = ['ALTA', 'MEDIA', 'BAJA'];
    final colors = [AppTheme.accentRed, AppTheme.accentYellow, AppTheme.accentGreen];

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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors[index % colors.length].withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(Icons.warning_amber_outlined, color: colors[index % colors.length], size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Caso #${8920 + index} — Error de Pago', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: colors[index % colors.length].withOpacity(0.15),
                      child: Text(priorities[index % priorities.length], style: TextStyle(color: colors[index % colors.length], fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text('maria.rodriguez@email.com', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: AppTheme.divider),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1),
            ),
            child: const Text('INVESTIGAR'),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.campaign, size: 18),
          label: const Text('ENVIAR NOTIFICACIÓN MASIVA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.history, size: 18, color: Colors.white),
          label: const Text('VER REGISTROS DE TRAZABILIDAD', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12, color: Colors.white)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppTheme.divider),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
      ],
    );
  }
}
