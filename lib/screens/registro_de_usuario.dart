import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class RegistroDeUsuario extends StatelessWidget {
  const RegistroDeUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _RegistroMobile(),
      web: _RegistroWeb(),
    );
  }
}

class _RegistroWeb extends StatelessWidget {
  const _RegistroWeb();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          // Panel izquierdo
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ESPACIO FONDO ESTADIO:
                // Reemplaza con Image.asset('assets/estadio.jpg', fit: BoxFit.cover)
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF001a0e), Color(0xFF0a0a1a)],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.stadium, size: 180, color: Color(0x12FFFFFF)),
                  ),
                ),
                Container(color: Colors.black.withOpacity(0.5)),
                Padding(
                  padding: const EdgeInsets.all(56),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        color: AppTheme.accentGreen,
                        child: const Text('ÚNETE AL MUNDIAL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 2)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'CREA TU\nCUENTA\nY VIVE 2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.05,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Panel derecho: formulario
          Container(
            width: 520,
            color: AppTheme.surfaceCard,
            child: const SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 56, vertical: 64),
              child: _RegistroForm(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistroMobile extends StatelessWidget {
  const _RegistroMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // ESPACIO LOGO MÓVIL
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const Icon(Icons.sports_soccer, color: AppTheme.accentGreen, size: 32),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: const _RegistroForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegistroForm extends StatefulWidget {
  const _RegistroForm();

  @override
  State<_RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<_RegistroForm> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 4, height: 32, color: AppTheme.accentGreen),
            const SizedBox(width: 12),
            const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Completa tus datos para registrarte', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 32),

        _label('NOMBRE COMPLETO'),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Tu nombre completo', prefixIcon: Icon(Icons.person_outline)),
        ),
        const SizedBox(height: 20),

        _label('CORREO ELECTRÓNICO'),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'tu@correo.com', prefixIcon: Icon(Icons.email_outlined)),
        ),
        const SizedBox(height: 20),

        _label('CONTRASEÑA'),
        const SizedBox(height: 8),
        TextField(
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 20),

        _label('CONFIRMAR CONTRASEÑA'),
        const SizedBox(height: 8),
        TextField(
          obscureText: _obscureConfirm,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
            ),
          ),
        ),
        const SizedBox(height: 32),

        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentGreen,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('REGISTRARSE', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        ),
        const SizedBox(height: 20),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('¿Ya tienes cuenta?', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Inicia sesión', style: TextStyle(color: AppTheme.accentRed, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _label(String text) =>
      Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
}
