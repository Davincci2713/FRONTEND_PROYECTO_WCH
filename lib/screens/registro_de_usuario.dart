import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import '../services/auth/auth.dart';

class RegistroDeUsuario extends StatelessWidget {
  const RegistroDeUsuario({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ResponsiveLayout(mobile: RegistroMobile(), web: RegistroWeb()),
    );
  }
}

class RegistroWeb extends StatelessWidget {
  const RegistroWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Branding / Marquee
        Expanded(
          flex: 5,
          child: Container(
            color: AppColors.primary,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: GridPaper(
                      color: AppColors.onPrimary,
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
                        Icon(Icons.sports_soccer, size: 80, color: AppColors.onPrimary),
                        SizedBox(height: 24),
                        Text(
                          'ÚNETE\nAL HUB.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 96,
                            height: 0.9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.onPrimary,
                            letterSpacing: -4,
                          ),
                        ),
                        SizedBox(height: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.onPrimary, width: 2),
                          ),
                          child: Text(
                            'EL COMPAÑERO DIGITAL OFICIAL ✦ 2026',
                            style: GoogleFonts.dmSans(
                              color: AppColors.onPrimary,
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
                constraints: const BoxConstraints(maxWidth: 450),
                child: const SingleChildScrollView(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: RegistroForm(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RegistroMobile extends StatelessWidget {
  const RegistroMobile({super.key});

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
            const RegistroForm(),
          ],
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
          SnackBar(
            content: Text(result['message'] ?? 'Error desconocido', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
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
                    'INGRESA EL CÓDIGO ENVIADO A:\n$email',
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5),
                  ),
                  SizedBox(height: 24),
                  _BrutalistInput(
                    label: 'CÓDIGO DE 6 DÍGITOS',
                    hint: '000000',
                    controller: codeController,
                    icon: Icons.numbers,
                  ),
                ],
              ),
              actionsPadding: const EdgeInsets.all(24),
              actions: [
                OutlinedButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          setStateDialog(() => isVerifying = true);
                          final result = await AuthService().verifyEmail(
                            email,
                            codeController.text,
                          );
                          setStateDialog(() => isVerifying = false);

                          if (result['success']) {
                            if (context.mounted) {
                              Navigator.pop(context); // close dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡CUENTA VERIFICADA! AHORA PUEDES INICIAR SESIÓN.', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                              );
                              context.go('/login');
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message']?.toString().toUpperCase() ?? 'ERROR AL VERIFICAR', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
                                  backgroundColor: AppColors.error,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                ),
                              );
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.inverseSurface,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: isVerifying
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.onPrimary))
                      : Text('VERIFICAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'CREAR\nCUENTA',
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
          'INGRESA TUS DATOS PARA COMENZAR.',
          style: GoogleFonts.dmSans(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: _BrutalistInput(
                label: 'NOMBRES',
                hint: 'JUAN',
                controller: _firstNameController,
                icon: Icons.person_outline,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _BrutalistInput(
                label: 'APELLIDOS',
                hint: 'PÉREZ',
                controller: _lastNameController,
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        SizedBox(height: 24),
        _BrutalistInput(
          label: 'CORREO ELECTRÓNICO',
          hint: 'USUARIO@EMAIL.COM',
          controller: _emailController,
          icon: Icons.email_outlined,
        ),
        SizedBox(height: 24),
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
        SizedBox(height: 48),
        SizedBox(
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleRegister,
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
                        'REGISTRARSE',
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
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Column(
            children: [
              Text(
                '¿YA TIENES CUENTA?',
                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => context.go('/login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.text, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                  child: Text(
                    'INICIAR SESIÓN',
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
