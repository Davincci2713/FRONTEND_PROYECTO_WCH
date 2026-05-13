import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class CrearPollaScreen extends StatefulWidget {
  const CrearPollaScreen({super.key});

  @override
  State<CrearPollaScreen> createState() => _CrearPollaScreenState();
}

class _CrearPollaScreenState extends State<CrearPollaScreen> {
  bool _isPrivate = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text('NUEVA POLLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CONFIGURACIÓN BÁSICA', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 20),
            _buildField('NOMBRE DE LA POLLA', 'Ej: Los Amigos del Fútbol'),
            const SizedBox(height: 16),
            _buildField('CONTRASEÑA (OPCIONAL)', '••••••', isPassword: true),
            const SizedBox(height: 24),
            
            // Privacidad
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: AppTheme.accentYellow),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Polla Privada', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('Solo con invitación o código', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isPrivate, 
                    onChanged: (v) => setState(() => _isPrivate = v),
                    activeColor: AppTheme.accentYellow,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            const Text('REGLAMENTO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 2)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
              child: const Text(
                '• 3 puntos por marcador exacto\n• 1 punto por acertar ganador/empate\n• Se cierra 15 min antes del partido',
                style: TextStyle(color: Colors.white, height: 1.6),
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('CREAR POLLA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint, {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 10, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}