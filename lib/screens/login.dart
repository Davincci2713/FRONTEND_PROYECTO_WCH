import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import '../services/auth/auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(mobile: LoginMobile(), web: LoginWeb());
  }
}

class LoginWeb extends StatelessWidget {
  const LoginWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          // Left side: Image or branding
          Expanded(
            child: Container(
              color: const Color(0xFF00341C),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'World Cup Hub',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu compañero digital para la Copa del Mundo',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side: Login form
          Container(
            width: 450,
            color: Colors.white,
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
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Center(
                child: Icon(
                  Icons.sports_soccer,
                  size: 64,
                  color: Color(0xFF00341C),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const LoginForm(),
              ),
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
    final result = await AuthService().login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (!context.mounted) return;

    if (result['success'] == true) {
      context.go('/home');
    } else if (result['requiresMfa'] == true) {
      _showMfaDialog(result['email'] as String);
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

  void _showMfaDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _MfaDialog(email: email),
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
          'Iniciar sesión',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa a tu cuenta de World Cup Hub',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Correo electrónico',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            hintText: '******',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00341C),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
            child: const Text('¿Olvidaste tu contraseña?'),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00341C),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Iniciar sesión',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
              if (!_isLoading) const SizedBox(width: 8),
              if (!_isLoading) const Icon(Icons.arrow_forward, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '¿No tienes cuenta?',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            TextButton(
              onPressed: () => context.go('/register'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF00341C),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
    setState(() {
      _isVerifying = true;
      _feedbackMessage = null;
    });
    final result = await AuthService().verifyEmail(
      widget.email,
      _codeController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Cuenta verificada! Ahora puedes iniciar sesión.'),
        ),
      );
      context.go('/login');
    } else {
      setState(
        () => _feedbackMessage = result['message'] ?? 'Código incorrecto.',
      );
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _feedbackMessage = null;
    });
    final result = await AuthService().resendVerificationCode(widget.email);
    if (!mounted) return;
    setState(() {
      _isResending = false;
      _feedbackMessage =
          result['message'] ??
          (result['success'] == true
              ? 'Código reenviado.'
              : 'No se pudo reenviar.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: const Text(
        'Verificar correo',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa el código de 6 dígitos enviado a ${widget.email}.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Código de verificación',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
            ),
          ),
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedbackMessage!,
              style: TextStyle(
                color:
                    _feedbackMessage!.contains('reenviado') ||
                        _feedbackMessage!.contains('verificad')
                    ? Colors.green.shade700
                    : const Color(0xFFBB0014),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: _isResending ? null : _resend,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00341C),
            ),
            child: _isResending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('¿No recibiste el código? Reenviar'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00341C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Verificar',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo de verificación de MFA (Multi-Factor Authentication) en Login
// ---------------------------------------------------------------------------
class _MfaDialog extends StatefulWidget {
  final String email;
  const _MfaDialog({required this.email});

  @override
  State<_MfaDialog> createState() => _MfaDialogState();
}

class _MfaDialogState extends State<_MfaDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _feedbackMessage;

  Future<void> _verifyMfa() async {
    if (_codeController.text.trim().length != 6) {
      setState(() => _feedbackMessage = 'El código debe tener 6 dígitos.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _feedbackMessage = null;
    });
    
    final result = await AuthService().verifyMfa(
      widget.email,
      _codeController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() => _isVerifying = false);

    if (result['success'] == true) {
      Navigator.pop(context); // Close dialog
      context.go('/home'); // Go to home on success
    } else {
      setState(() => _feedbackMessage = result['message'] ?? 'Código incorrecto o expirado.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: const Text(
        'Autenticación en dos pasos',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hemos enviado un código de seguridad a ${widget.email}.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'Código MFA',
              counterText: '',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              isDense: true,
            ),
          ),
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _feedbackMessage!,
              style: const TextStyle(
                color: Color(0xFFBB0014),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verifyMfa,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00341C),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Verificar',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
        ),
      ],
    );
  }
}

