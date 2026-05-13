import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import '../services/auth/auth.dart';

class RegistroDeUsuario extends StatelessWidget {
  const RegistroDeUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: RegistroMobile(),
      web: RegistroWeb(),
    );
  }
}

class RegistroWeb extends StatelessWidget {
  const RegistroWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
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
                      'Únete a la Pasión',
                      style: theme.textTheme.displaySmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Crea tu cuenta y vive el Mundial 2026',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 500,
            padding: const EdgeInsets.all(48.0),
            child: const SingleChildScrollView(child: RegistroForm()),
          ),
        ],
      ),
    );
  }
}

class RegistroMobile extends StatelessWidget {
  const RegistroMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Icon(Icons.sports_soccer, size: 48, color: Color(0xFF00341C)),
              ),
              const SizedBox(height: 24),
              const RegistroForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class RegistroForm extends StatefulWidget {
  const RegistroForm({super.key});

  @override
  State<RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<RegistroForm> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleRegister() async {
    setState(() => _isLoading = true);
    final result = await AuthService().register(
      _firstNameController.text,
      _lastNameController.text,
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (context.mounted) {
        _showVerificationDialog(_emailController.text);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Error desconocido')),
        );
      }
    }
  }

  void _showVerificationDialog(String email) {
    final TextEditingController codeController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Verificar Correo'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Se ha enviado un código de 6 dígitos a tu correo electrónico. Ingresa el código a continuación:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(hintText: 'Código'),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isVerifying ? null : () async {
                    setStateDialog(() => isVerifying = true);
                    final result = await AuthService().verifyEmail(email, codeController.text);
                    setStateDialog(() => isVerifying = false);

                    if (result['success']) {
                      if (context.mounted) {
                        Navigator.pop(context); // close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cuenta verificada exitosamente. Ahora puedes iniciar sesión.')),
                        );
                        context.go('/login');
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Error al verificar')),
                        );
                      }
                    }
                  },
                  child: isVerifying 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Text('Verificar'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Crear Cuenta', style: theme.textTheme.headlineLarge),
        const SizedBox(height: 8),
        Text('Completa tus datos para registrarte', style: theme.textTheme.bodyMedium),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Nombres', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      hintText: 'Tus nombres',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apellidos', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      hintText: 'Tus apellidos',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '******',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleRegister,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Registrarse'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('¿Ya tienes cuenta?'),
            TextButton(
              onPressed: () => context.go('/login'),
              child: const Text('Inicia sesión aquí'),
            ),
          ],
        ),
      ],
    );
  }
}
