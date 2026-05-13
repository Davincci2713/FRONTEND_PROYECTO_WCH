import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class ComprarEntradasScreen extends StatelessWidget {
  const ComprarEntradasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('COMPRAR ENTRADAS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('SELECCIONA UN PARTIDO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 20),
          _matchSelectionCard('Fase de Grupos', 'México vs Polonia', '18 Jun - CDMX', '\$85.00'),
          _matchSelectionCard('Fase de Grupos', 'Colombia vs Alemania', '22 Jun - Bogotá', '\$120.00'),
          const SizedBox(height: 32),
          const Text('ZONA DEL ESTADIO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
          const SizedBox(height: 16),
          DropdownButtonFormField(
            dropdownColor: AppTheme.surfaceCard,
            decoration: const InputDecoration(filled: true, fillColor: AppTheme.surfaceCard),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Tribuna Norte - \$85', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 2, child: Text('Tribuna Sur - \$85', style: TextStyle(color: Colors.white))),
              DropdownMenuItem(value: 3, child: Text('Occidental VIP - \$250', style: TextStyle(color: Colors.white))),
            ], 
            onChanged: (v) {},
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
            child: const Text('PROCEDER AL PAGO', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _matchSelectionCard(String phase, String match, String info, String price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        border: Border.all(color: AppTheme.divider),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(phase, style: const TextStyle(color: AppTheme.accentBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                Text(match, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text(info, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}