import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class RecuperarContrasena extends StatelessWidget {
  const RecuperarContrasena({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _RecuperarMobile(),
      web: _RecuperarWeb(),
    );
  }
}

class _RecuperarWeb extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: Row(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF001a0e), Color(0xFF0a0a1a)],
                      ),
                    ),
                  ),
                  Container(color: Colors.black.withOpacity(0.4)),
                  Padding(
                    padding: const EdgeInsets.all(56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          color: AppTheme.accentBlue,
                          child: const Text('SEGURIDAD DE CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 16),
                        const Text('RECUPERA\nTU ACCESO', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 480,
              color: AppTheme.surfaceCard,
              padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 64),
              child: const _RecuperarForm(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecuperarMobile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Recuperar Contraseña', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: _RecuperarForm(),
        ),
      ),
    );
  }
}

class _RecuperarForm extends StatelessWidget {
  const _RecuperarForm();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 4, height: 32, color: AppTheme.accentBlue),
            const SizedBox(width: 12),
            const Text('RECUPERAR\nCONTRASEÑA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1, height: 1.2)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Ingresa tu correo y te enviaremos un enlace de recuperación.', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 32),

        const Text('CORREO ELECTRÓNICO', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('ENVIAR ENLACE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        ),
        const SizedBox(height: 20),

        TextButton(
          onPressed: () => context.go('/login'),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.arrow_back, size: 16, color: AppTheme.onSurfaceMuted),
              SizedBox(width: 8),
              Text('Volver al inicio de sesión', style: TextStyle(color: AppTheme.onSurfaceMuted)),
            ],
          ),
        ),
      ],
    );
  }
}
