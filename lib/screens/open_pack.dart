import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class OpenPackScreen extends StatelessWidget {
  const OpenPackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('SOBRE ABIERTO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/album'),
        ),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppTheme.divider)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header resultado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.accentYellow.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.accentYellow.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.style, color: AppTheme.accentYellow, size: 28),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('¡SOBRE ABIERTO!', style: TextStyle(color: AppTheme.accentYellow, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14)),
                      Text('Has obtenido 5 nuevas láminas', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Grid de cartas
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _StickerCard(name: 'L. Messi', country: 'Argentina', isNew: true),
                _StickerCard(name: 'A. Davies', country: 'Canadá', isNew: true),
                _StickerCard(name: 'H. Lozano', country: 'México', isRepeated: true),
                _StickerCard(name: 'C. Pulisic', country: 'USA', isNew: true),
                _StickerCard(name: 'Trofeo Oficial', country: 'Especial', isNew: true, isSpecial: true),
              ],
            ),
            const SizedBox(height: 40),

            // Botones de acción
            LayoutBuilder(builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              final btn1 = ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.style, size: 18),
                label: const Text('ABRIR OTRO SOBRE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentYellow,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              );
              final btn2 = OutlinedButton.icon(
                onPressed: () => context.go('/album'),
                icon: const Icon(Icons.auto_stories, size: 18, color: Colors.white),
                label: const Text('IR AL ÁLBUM', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12, color: Colors.white)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  side: const BorderSide(color: AppTheme.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              );
              if (isWide) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [btn1, const SizedBox(width: 16), btn2],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [btn1, const SizedBox(height: 12), btn2],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StickerCard extends StatelessWidget {
  final String name;
  final String country;
  final bool isNew;
  final bool isRepeated;
  final bool isSpecial;

  const _StickerCard({
    required this.name,
    required this.country,
    this.isNew = false,
    this.isRepeated = false,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSpecial ? AppTheme.accentYellow : (isRepeated ? AppTheme.onSurfaceMuted.withOpacity(0.3) : AppTheme.accentBlue.withOpacity(0.4)),
          width: isSpecial ? 2 : 1,
        ),
        boxShadow: isSpecial ? [BoxShadow(color: AppTheme.accentYellow.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)] : null,
      ),
      child: Column(
        children: [
          // Imagen de la lámina (espacio para avatar/foto jugador)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isSpecial
                      ? [Color(0xFF2a2000), Color(0xFF1E1E1E)]
                      : [Color(0xFF0a1a2a), Color(0xFF1E1E1E)],
                ),
              ),
              child: Stack(
                children: [
                  // ESPACIO IMAGEN JUGADOR/AVATAR
                  // Reemplaza con Image.asset('assets/players/${name}.png', fit: BoxFit.cover)
                  Center(
                    child: Icon(
                      isSpecial ? Icons.emoji_events : Icons.person,
                      size: 56,
                      color: isSpecial ? AppTheme.accentYellow.withOpacity(0.6) : AppTheme.onSurfaceMuted.withOpacity(0.3),
                    ),
                  ),
                  // Badge estado
                  if (isNew)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppTheme.accentBlue,
                        child: const Text('NUEVA', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  if (isRepeated)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        color: AppTheme.surfaceElevated,
                        child: Text('REPETIDA', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      ),
                    ),
                  if (isSpecial)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.stars, color: AppTheme.accentYellow, size: 20),
                    ),
                ],
              ),
            ),
          ),
          // Info jugador
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
                const SizedBox(height: 2),
                Text(country, style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
