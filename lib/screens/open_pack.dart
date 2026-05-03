import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OpenPackScreen extends StatelessWidget {
  const OpenPackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('¡Sobre Abierto!')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Has obtenido 5 nuevas láminas', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildCard(context, 'L. Messi', 'Argentina', true, false),
                _buildCard(context, 'A. Davies', 'Canadá', true, false),
                _buildCard(context, 'H. Lozano', 'México', false, true),
                _buildCard(context, 'C. Pulisic', 'USA', true, false),
                _buildCard(context, 'Trofeo Oficial', 'Especial', true, false, isSpecial: true),
              ],
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.style),
              label: const Text('ABRIR OTRO SOBRE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/album'),
              icon: const Icon(Icons.auto_stories),
              label: const Text('IR AL ÁLBUM'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, String name, String country, bool isNew, bool isRepeated, {bool isSpecial = false}) {
    return Container(
      width: 180,
      height: 240,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
        border: isSpecial ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.person, size: 64, color: Colors.grey)),
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                        child: const Text('NUEVA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isRepeated)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(12)),
                        child: const Text('REPETIDA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (isSpecial)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.stars, color: Colors.amber),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(country, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
