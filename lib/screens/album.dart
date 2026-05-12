import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('Álbum Digital', style: theme.textTheme.headlineMedium),
              ElevatedButton.icon(
                onPressed: () => context.go('/open-pack'),
                icon: const Icon(Icons.style),
                label: const Text('ABRIR SOBRE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Statistics
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(child: _buildStatCard(context, 'Completado', '45%', Colors.green)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, 'Láminas', '250/600', Colors.blue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard(context, 'Repetidas', '12', Colors.orange)),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatCard(context, 'Completado', '45%', Colors.green),
                    const SizedBox(height: 16),
                    _buildStatCard(context, 'Láminas', '250/600', Colors.blue),
                    const SizedBox(height: 16),
                    _buildStatCard(context, 'Repetidas', '12', Colors.orange),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),
          Text('Mis Colecciones', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: 8,
            itemBuilder: (context, index) {
              return Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        color: Colors.grey[300],
                        child: const Center(child: Icon(Icons.flag, size: 48)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Selección ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}
