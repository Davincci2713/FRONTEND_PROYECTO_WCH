import 'package:flutter/material.dart';

class BackofficePanel extends StatelessWidget {
  const BackofficePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Control - Operador'),
        backgroundColor: const Color(0xFF00341C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestión Operativa', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            _buildAdminStats(), 
            const SizedBox(height: 32),
            Text('Incidentes Recientes', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _buildIncidentList(),
            const SizedBox(height: 32),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminStats() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Row(
            children: [
              Expanded(child: _statCard('Entradas Reservadas', '1,250', Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Alertas de Fraude', '14', Colors.red)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Soporte Pendiente', '8', Colors.orange)),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _statCard('Entradas Reservadas', '1,250', Colors.blue),
              const SizedBox(height: 16),
              _statCard('Alertas de Fraude', '14', Colors.red),
              const SizedBox(height: 16),
              _statCard('Soporte Pendiente', '8', Colors.orange),
            ],
          );
        }
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildIncidentList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return ListTile(
          tileColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
          title: Text('Caso #${8920 + index} - Error de Pago'),
          subtitle: const Text('Usuario: maria.rodriguez@email.com'),
          trailing: ElevatedButton(
            onPressed: () {}, 
            child: const Text('Investigar'),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.campaign),
          label: const Text('ENVIAR NOTIFICACIÓN MASIVA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBB0014),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {}, 
          icon: const Icon(Icons.history),
          label: const Text('VER REGISTROS DE TRAZABILIDAD'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ],
    );
  }
}