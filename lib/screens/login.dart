import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import '../services/auth/auth.dart';

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
      backgroundColor: theme.colorScheme.surface,
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    final result = await AuthService().login(_emailController.text, _passwordController.text);
    setState(() => _isLoading = false);

    if (!context.mounted) return;

    if (result['success'] == true) {
      context.go('/home');
    } else if (result['errorCode'] == 'ERR_UNVERIFIED') {
      _showVerificationDialog(result['email'] as String);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error desconocido')),
      );
    }
  }

  void _showVerificationDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _VerificationDialog(email: email),
    );
  }

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
          controller: _emailController,
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
          controller: _passwordController,
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
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.secondary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Iniciar Sesión'),
              if (!_isLoading) const SizedBox(width: 8),
              if (!_isLoading) const Icon(Icons.arrow_forward, size: 20),
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

// ---------------------------------------------------------------------------
// Diálogo de verificación de email (usado tanto desde registro como desde login)
// ---------------------------------------------------------------------------
class _VerificationDialog extends StatefulWidget {
  final String email;
  const _VerificationDialog({required this.email});

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  bool _isResending = false;
  String? _feedbackMessage;

  Future<void> _verify() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _feedbackMessage = 'El código debe tener 6 dígitos.');
      return;
    }
    setState(() { _isVerifying = true; _feedbackMessage = null; });
    final result = await AuthService().verifyEmail(widget.email, _codeController.text.trim());
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Cuenta verificada! Ahora puedes iniciar sesión.')),
      );
      context.go('/login');
    } else {
      setState(() => _feedbackMessage = result['message'] ?? 'Código incorrecto.');
    }
  }

  Future<void> _resend() async {
    setState(() { _isResending = true; _feedbackMessage = null; });
    final result = await AuthService().resendVerificationCode(widget.email);
    if (!mounted) return;
    setState(() {
      _isResending = false;
      _feedbackMessage = result['message'] ?? (result['success'] == true
          ? 'Código reenviado.'
          : 'No se pudo reenviar.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Verificar correo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa el código de 6 dígitos enviado a ${widget.email}.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'Código de verificación',
              counterText: '',
            ),
          ),
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 8),
            Text(_feedbackMessage!, style: TextStyle(
              color: _feedbackMessage!.contains('reenviado') || _feedbackMessage!.contains('verificad')
                  ? Colors.green
                  : Colors.red,
              fontSize: 13,
            )),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isResending ? null : _resend,
            child: _isResending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('¿No recibiste el código? Reenviar'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          child: _isVerifying
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verificar'),
        ),
      ],
    );
  }
}
