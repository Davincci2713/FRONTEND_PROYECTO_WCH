import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _LoginMobile(),
      web: _LoginWeb(),
    );
  }
}

// ── WEB ─────────────────────────────────────────────────────────────────────
class _LoginWeb extends StatelessWidget {
  const _LoginWeb();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          // Panel izquierdo: Hero con fondo de estadio
          Expanded(child: const _HeroPanel()),
          // Panel derecho: formulario
          Container(
            width: 480,
            color: AppTheme.surfaceCard,
            child: const SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 56, vertical: 64),
              child: _LoginForm(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MÓVIL ─────────────────────────────────────────────────────────────────
class _LoginMobile extends StatelessWidget {
  const _LoginMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          // Fondo estadio (espacio para imagen)
          Positioned.fill(child: const _StadiumBackground()),
          // Formulario sobre overlay
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // Logo móvil
                  // ESPACIO LOGO: reemplaza con Image.asset('assets/logo_wch.png', height: 72)
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Icon(Icons.sports_soccer, color: AppTheme.accentRed, size: 40),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const _LoginForm(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── COMPONENTES ──────────────────────────────────────────────────────────────

/// Fondo de estadio con gradiente oscuro encima
/// NOTA: Reemplaza el DecoratedBox con DecorationImage para imagen real:
/// decoration: BoxDecoration(image: DecorationImage(image: AssetImage('assets/estadio.jpg'), fit: BoxFit.cover))
class _StadiumBackground extends StatelessWidget {
  const _StadiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // ── ESPACIO PARA IMAGEN FONDO ESTADIO ──────────────────────────
        // Reemplaza este Container con:
        // Image.asset('assets/estadio.jpg', fit: BoxFit.cover)
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001a0e), Color(0xFF0a0a1a), Color(0xFF1a000a)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.stadium, size: 200, color: Color(0x15FFFFFF)),
          ),
        ),
        // Gradiente oscurecedor
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Panel hero solo para web
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _StadiumBackground(),
        // Contenido sobre el hero
        Padding(
          padding: const EdgeInsets.all(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Navbar superior estilo imagen
              Row(
                children: [
                  // ESPACIO LOGO WCH: reemplaza con Image.asset('assets/logo_wch.png', height: 40)
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.sports_soccer, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('WCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3)),
                  const Spacer(),
                  // Botones nav estilo imagen (Pollas, Álbum, Perfil)
                  _NavChip(label: 'Pollas', onTap: () {}),
                  const SizedBox(width: 8),
                  _NavChip(label: 'Álbum', onTap: () {}),
                  const SizedBox(width: 8),
                  _NavChip(label: 'Perfil', onTap: () {}),
                ],
              ),
              const Spacer(),
              // Texto hero
              const Text(
                '¿QUIERES IR A\nUN PARTIDO?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 24),
              // Botones de colores estilo imagen (Log in, Registrarse, Agenda, Billetera)
              Wrap(
                spacing: 0,
                children: [
                  _ColorTab(label: 'LOG IN', color: AppTheme.accentBlue),
                  _ColorTab(label: 'REGISTRARSE', color: AppTheme.accentGreen),
                  _ColorTab(label: 'AGENDA', color: AppTheme.accentRed),
                  _ColorTab(label: 'BILLETERA', color: AppTheme.accentYellow, textColor: Colors.black),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NavChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13, letterSpacing: 0.5)),
      ),
    );
  }
}

class _ColorTab extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _ColorTab({required this.label, required this.color, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: color,
      child: Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
    );
  }
}

// ── FORMULARIO ──────────────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header del form
        Row(
          children: [
            Container(width: 4, height: 32, color: AppTheme.accentRed),
            const SizedBox(width: 12),
            const Text(
              'INICIAR SESIÓN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Ingresa a tu cuenta de World Cup Hub',
            style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 32),

        const _FieldLabel('CORREO ELECTRÓNICO'),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),

        const _FieldLabel('CONTRASEÑA'),
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
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/recover'),
            child: const Text('¿Olvidaste tu contraseña?',
                style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Divisor
        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF333333))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('O', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: Color(0xFF333333))),
          ],
        ),
        const SizedBox(height: 20),

        OutlinedButton(
          onPressed: () => context.go('/register'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFF444444)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
  }
}
