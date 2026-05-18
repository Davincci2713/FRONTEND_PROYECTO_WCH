import '../utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import '../services/auth/auth.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(mobile: LoginMobile(), web: LoginWeb()),
    );
  }
}

// ---------------------------------------------------------------------------
// Layout Web (Split Screen Brutalista)
// ---------------------------------------------------------------------------
class LoginWeb extends StatelessWidget {
  const LoginWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Branding / Marquee
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primaryDark,
            child: Stack(
              children: [
                // Fondo de textura/patrón (simulado)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: GridPaper(
                      color: AppColors.primary,
                      interval: 40,
                      divisions: 1,
                      subdivisions: 1,
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(64.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sports_soccer, size: 80, color: AppColors.primary),
                        SizedBox(height: 24),
                        Text(
                          'WORLD\nCUP\nHUB.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 96,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                            letterSpacing: -4,
                          ),
                        ),
                        SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.primary, width: 2),
                          ),
                          child: Text(
                            'EL COMPAÑERO DIGITAL OFICIAL ✦ 2026',
                            style: GoogleFonts.dmSans(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Right Side: Form
        Expanded(
          flex: 4,
          child: Container(
            color: AppColors.background,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: const LoginForm(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Layout Móvil
// ---------------------------------------------------------------------------
class LoginMobile extends StatelessWidget {
  const LoginMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 24),
            // Header Brutalista
            Row(
              children: [
                Icon(Icons.sports_soccer, size: 40, color: AppColors.primary),
                SizedBox(width: 16),
                Text(
                  'WCH.26',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -2,
                  ),
                ),
              ],
            ),
            SizedBox(height: 48),
            const LoginForm(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formulario de Login (Estilo Brutalista)
// ---------------------------------------------------------------------------
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
    } else if (result['errorCode'] == 'ERR_UNVERIFIED') {
      _showVerificationDialog(result['email'] as String);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error desconocido', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'INICIAR\nSESIÓN',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 48,
            height: 1.0,
            fontWeight: FontWeight.w900,
            color: AppColors.text,
            letterSpacing: -2,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'ACCEDE AL ECOSISTEMA DIGITAL.',
          style: GoogleFonts.dmSans(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 48),
        
        // Input: Email
        _BrutalistInput(
          label: 'CORREO ELECTRÓNICO',
          hint: 'USUARIO@EMAIL.COM',
          controller: _emailController,
          icon: Icons.email_outlined,
        ),
        SizedBox(height: 24),
        
        // Input: Password
        _BrutalistInput(
          label: 'CONTRASEÑA',
          hint: '••••••••',
          controller: _passwordController,
          obscureText: _obscurePassword,
          icon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.text,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
        
        SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text(
              '¿OLVIDASTE TU CONTRASEÑA?',
              style: GoogleFonts.dmSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.primary,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 32),
        
        // Botón Submit Brutalista
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.inverseSurface,
              disabledBackgroundColor: Colors.grey.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              side: BorderSide(color: AppColors.primary, width: 2),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 3),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ENTRAR AL HUB',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(Icons.arrow_forward_sharp, size: 24),
                    ],
                  ),
          ),
        ),
        
        SizedBox(height: 32),
        
        // Registro
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              Text(
                '¿NUEVO EN EL HUB?',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/register'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.text, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text(
                    'CREAR UNA CUENTA',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget: Input Brutalista
// ---------------------------------------------------------------------------
class _BrutalistInput extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final IconData icon;
  final Widget? suffixIcon;

  const _BrutalistInput({
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.dmSans(color: AppColors.border),
            prefixIcon: Icon(icon, color: AppColors.textMuted),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Diálogo de verificación (Estilo Brutalista)
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
      setState(() => _feedbackMessage = 'EL CÓDIGO DEBE TENER 6 DÍGITOS.');
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
        SnackBar(
          content: Text('¡CUENTA VERIFICADA! AHORA PUEDES INICIAR SESIÓN.', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      context.go('/login');
    } else {
      setState(() => _feedbackMessage = result['message']?.toString().toUpperCase() ?? 'CÓDIGO INCORRECTO.');
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
      _feedbackMessage = result['message']?.toString().toUpperCase() ??
          (result['success'] == true ? 'CÓDIGO REENVIADO.' : 'ERROR AL REENVIAR.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.primary, width: 2),
      ),
      title: Text(
        'VERIFICAR CORREO',
        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INGRESA EL CÓDIGO ENVIADO A:\n${widget.email}',
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5),
          ),
          SizedBox(height: 24),
          _BrutalistInput(
            label: 'CÓDIGO DE 6 DÍGITOS',
            hint: '000000',
            controller: _codeController,
            icon: Icons.numbers,
          ),
          if (_feedbackMessage != null) ...[
            SizedBox(height: 12),
            Text(
              _feedbackMessage!,
              style: GoogleFonts.dmSans(
                color: _feedbackMessage!.contains('REENVIADO') || _feedbackMessage!.contains('VERIFICAD')
                    ? AppColors.primary
                    : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          SizedBox(height: 16),
          TextButton(
            onPressed: _isResending ? null : _resend,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.text,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: _isResending
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.text))
                : Text('¿NO LO RECIBISTE? REENVIAR', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.all(24),
      actions: [
        OutlinedButton(
          onPressed: _isVerifying ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text,
            side: BorderSide(color: AppColors.border, width: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.inverseSurface,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
          child: _isVerifying
              ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
              : Text('VERIFICAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
