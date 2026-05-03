import 'package:flutter/material.dart';

class PollasScreen extends StatelessWidget {
  const PollasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis Pollas', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 24),
          _buildActivePolls(context),
          const SizedBox(height: 32),
          Text('Ranking Global', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildRankingTable(context),
        ],
      ),
    );
  }

  Widget _buildActivePolls(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Pollas Activas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Crear Polla'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return Container(
                width: 200,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grupo ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Text('12 Participantes'),
                    const Text('Posición: 4°'),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRankingTable(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Pos')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Puntos')),
        ],
        rows: List.generate(5, (index) => DataRow(
          cells: [
            DataCell(Text('${index + 1}')),
            DataCell(Text('Usuario ${index + 1}')),
            DataCell(Text('${100 - index * 10}')),
          ],
        )),
      ),
    );
  }
}
