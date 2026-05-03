import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: LoginMobile(),
      web: LoginWeb(),
    );
  }
}

class LoginWeb extends StatelessWidget {
  const LoginWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Row(
        children: [
          // Left side: Image or branding
          Expanded(
            child: Container(
              color: theme.colorScheme.primary,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_soccer, size: 100, color: Colors.white),
                    const SizedBox(height: 24),
                    Text(
                      'World Cup Hub',
                      style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu compañero digital para la Copa del Mundo',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side: Login form
          Container(
            width: 450,
            padding: const EdgeInsets.all(48.0),
            child: const LoginForm(),
          ),
        ],
      ),
    );
  }
}

class LoginMobile extends StatelessWidget {
  const LoginMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(Icons.sports_soccer, size: 64, color: Color(0xFF00341C)),
              ),
              const SizedBox(height: 24),
              const LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Iniciar Sesión',
          style: theme.textTheme.headlineLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa a tu cuenta de World Cup Hub',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        const Text(
          'Correo Electrónico',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Contraseña',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '******',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Iniciar Sesión'),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿No tienes cuenta?'),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Regístrate aquí'),
            ),
          ],
        ),
      ],
    );
  }
}
