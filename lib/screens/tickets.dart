import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

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
                  Text('ENTRADAS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Mis Tickets', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add, size: 18),
                label: const Text('COMPRAR ENTRADAS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Tickets
          ...List.generate(2, (i) => _TicketCard(index: i)),
          const SizedBox(height: 32),

          // Historial
          const Text('HISTORIAL DE COMPRAS', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          _TransactionHistory(),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final int index;
  const _TicketCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final matches = [
      {'match': 'Colombia vs Alemania', 'phase': 'FASE DE GRUPOS', 'venue': 'Estadio Azteca, CDMX', 'date': '15 Jun 2026 — 18:00', 'num': '45'},
      {'match': 'Argentina vs Francia', 'phase': 'CUARTOS DE FINAL', 'venue': 'MetLife Stadium, NJ', 'date': '04 Jul 2026 — 20:00', 'num': '62'},
    ];
    final m = matches[index % matches.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra lateral de color
            Container(
              width: 6,
              decoration: const BoxDecoration(
                color: AppTheme.accentRed,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(8), bottomLeft: Radius.circular(8)),
              ),
            ),
            // Contenido principal
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          color: AppTheme.accentRed.withOpacity(0.15),
                          child: Text('PARTIDO ${m['num']} — ${m['phase']}', style: const TextStyle(color: AppTheme.accentRed, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          color: AppTheme.accentGreen.withOpacity(0.15),
                          child: const Text('CONFIRMADA', style: TextStyle(color: AppTheme.accentGreen, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(m['match']!, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      children: [
                        _InfoChip(icon: Icons.location_on_outlined, text: m['venue']!),
                        _InfoChip(icon: Icons.calendar_today_outlined, text: m['date']!),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // QR
            Container(
              width: 80,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: AppTheme.divider, style: BorderStyle.solid)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_2, size: 52, color: AppTheme.onSurfaceMuted),
                  const SizedBox(height: 4),
                  Text('ESCANEAR', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.onSurfaceMuted),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
      ],
    );
  }
}

class _TransactionHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final txs = [
      {'desc': 'Colombia vs Alemania', 'date': '12 May 2026', 'amount': '\$85.00', 'status': 'Pagado'},
      {'desc': 'Argentina vs Francia', 'date': '10 May 2026', 'amount': '\$120.00', 'status': 'Pagado'},
      {'desc': 'Brasil vs España', 'date': '01 May 2026', 'amount': '\$95.00', 'status': 'Reembolsado'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        children: txs.map((tx) {
          final isRefund = tx['status'] == 'Reembolsado';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isRefund ? AppTheme.accentYellow.withOpacity(0.1) : AppTheme.accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isRefund ? Icons.undo : Icons.confirmation_number_outlined,
                    color: isRefund ? AppTheme.accentYellow : AppTheme.accentGreen,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tx['desc']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text(tx['date']!, style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(tx['amount']!, style: TextStyle(color: isRefund ? AppTheme.accentYellow : Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                    Text(tx['status']!, style: TextStyle(color: isRefund ? AppTheme.accentYellow : AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
