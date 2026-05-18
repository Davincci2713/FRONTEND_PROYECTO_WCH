import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/auth/auth.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const SingleChildScrollView(
        child: ProfileForm(),
      ),
    );
  }
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  bool _prefPush = true;
  bool _prefEmail = false;
  bool _prefTrades = true;
  bool _prefMatches = true;
  bool _prefBets = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    // Primero cargar caché local para respuesta inmediata
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _prefPush    = prefs.getBool('pref_push')    ?? true;
        _prefEmail   = prefs.getBool('pref_email')   ?? false;
        _prefTrades  = prefs.getBool('pref_trades')  ?? true;
        _prefMatches = prefs.getBool('pref_matches') ?? true;
        _prefBets    = prefs.getBool('pref_bets')    ?? true;
      });
    }
    // Luego sincronizar con el servidor (fuente de verdad)
    try {
      final serverPrefs = await AuthService().getUserPreferences();
      if (serverPrefs.isNotEmpty && mounted) {
        final push    = serverPrefs['notif_push']    as bool? ?? _prefPush;
        final email   = serverPrefs['notif_email']   as bool? ?? _prefEmail;
        final trades  = serverPrefs['notif_trades']  as bool? ?? _prefTrades;
        final matches = serverPrefs['notif_matches'] as bool? ?? _prefMatches;
        final bets    = serverPrefs['notif_bets']    as bool? ?? _prefBets;
        // Actualizar caché local
        await prefs.setBool('pref_push',    push);
        await prefs.setBool('pref_email',   email);
        await prefs.setBool('pref_trades',  trades);
        await prefs.setBool('pref_matches', matches);
        await prefs.setBool('pref_bets',    bets);
        if (mounted) {
          setState(() {
            _prefPush    = push;
            _prefEmail   = email;
            _prefTrades  = trades;
            _prefMatches = matches;
            _prefBets    = bets;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _savePreference(String key, bool value) async {
    // Guardar localmente
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    // Sincronizar con servidor (mapa de keys locales → server)
    const keyMap = {
      'pref_push':    'notif_push',
      'pref_email':   'notif_email',
      'pref_trades':  'notif_trades',
      'pref_matches': 'notif_matches',
      'pref_bets':    'notif_bets',
    };
    final serverKey = keyMap[key];
    if (serverKey != null) {
      await AuthService().updateUserPreferences({serverKey: value});
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PREFERENCIA ACTUALIZADA', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  Future<void> _changeProfilePicture() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final base64Image = 'data:${image.mimeType ?? 'image/jpeg'};base64,${base64Encode(bytes)}';
        final result = await AuthService().updateProfilePicture(base64Image);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString().toUpperCase() ?? (result['success'] ? 'FOTO ACTUALIZADA' : 'ERROR'),
                style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)
              ),
              backgroundColor: result['success'] ? AppColors.primary : AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ERROR AL PROCESAR LA IMAGEN', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final user = AuthService().currentUser ?? {};
    final fullName = '${user['firstName'] ?? 'Usuario'} ${user['lastName'] ?? ''}'.trim();
    final email = user['email'] ?? 'No disponible';
    final profilePicture = user['profilePicture'] as String?;
    final themeProvider = context.watch<ThemeProvider>();

    ImageProvider? imageProvider;
    if (profilePicture != null && profilePicture.isNotEmpty) {
      if (profilePicture.startsWith('data:image')) {
        imageProvider = MemoryImage(base64Decode(profilePicture.split(',').last));
      } else if (profilePicture.startsWith('http')) {
        imageProvider = NetworkImage(profilePicture);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Hero header ────────────────────────────────────────────────
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border(bottom: BorderSide(color: AppColors.onPrimary, width: 2)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _isUploading ? null : _changeProfilePicture,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(color: AppColors.onPrimary, width: 2),
                      ),
                      child: imageProvider != null
                        ? Image(image: imageProvider, fit: BoxFit.cover)
                        : Container(
                            color: AppColors.onPrimary,
                            child: Icon(Icons.person_rounded, size: 42, color: AppColors.background),
                          ),
                    ),
                    if (_isUploading)
                      const Positioned.fill(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black), strokeWidth: 2),
                      ),
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Icon(Icons.camera_alt_rounded, size: 15, color: Colors.black),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                fullName.toUpperCase(),
                style: GoogleFonts.spaceGrotesk(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.onPrimary, letterSpacing: -1),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 4),
              Text(
                email.toUpperCase(),
                style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.onPrimary.withOpacity(0.87), fontWeight: FontWeight.bold, letterSpacing: 1),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  AuthService().logout();
                  context.go('/login');
                },
                icon: Icon(Icons.logout_rounded, size: 15),
                label: Text('CERRAR SESIÓN'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.onPrimary,
                  side: BorderSide(color: AppColors.onPrimary, width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  textStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Personal info ────────────────────────────────────────
              const _SectionLabel(label: 'INFORMACIÓN PERSONAL', icon: Icons.person_rounded),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    _ProfileField(label: 'NOMBRE COMPLETO', value: fullName),
                    Divider(),
                    _ProfileField(label: 'CORREO ELECTRÓNICO', value: email),
                  ],
                ),
              ),
              SizedBox(height: 48),
              
              // ── Apariencia ──────────────────────────────────────────
              const _SectionLabel(label: 'APARIENCIA', icon: Icons.palette_rounded),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    _PrefTile(
                      label: 'MODO CLARO',
                      subtitle: 'Diseño brutalista en alto contraste blanco',
                      value: themeProvider.isLightMode,
                      onChanged: (val) {
                        themeProvider.toggleTheme();
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 48),

              // ── General notifications ─────────────────────────────────
              const _SectionLabel(label: 'NOTIFICACIONES GENERALES', icon: Icons.notifications_rounded),
              SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    _PrefTile(
                      label: 'NOTIFICACIONES PUSH',
                      value: _prefPush,
                      onChanged: (val) { setState(() => _prefPush = val); _savePreference('pref_push', val); },
                    ),
                    Divider(),
                    _PrefTile(
                      label: 'NOTIFICACIONES POR CORREO',
                      value: _prefEmail,
                      onChanged: (val) { setState(() => _prefEmail = val); _savePreference('pref_email', val); },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // ── Event notifications ───────────────────────────────────
              AnimatedOpacity(
                opacity: _prefPush ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: IgnorePointer(
                  ignoring: !_prefPush,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel(label: 'EVENTOS A NOTIFICAR', icon: Icons.tune_rounded),
                      SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Column(
                          children: [
                            _PrefTile(
                              label: 'SOLICITUDES DE INTERCAMBIO',
                              subtitle: 'Álbum digital',
                              value: _prefTrades,
                              onChanged: (val) { setState(() => _prefTrades = val); _savePreference('pref_trades', val); },
                            ),
                            Divider(),
                            _PrefTile(
                              label: 'RECORDATORIOS DE PARTIDOS',
                              value: _prefMatches,
                              onChanged: (val) { setState(() => _prefMatches = val); _savePreference('pref_matches', val); },
                            ),
                            Divider(),
                            _PrefTile(
                              label: 'RESULTADOS DE APUESTAS',
                              value: _prefBets,
                              onChanged: (val) { setState(() => _prefBets = val); _savePreference('pref_bets', val); },
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 32, height: 32,
      decoration: BoxDecoration(color: AppColors.primary),
      child: Icon(icon, size: 16, color: AppColors.onPrimary),
    ),
    SizedBox(width: 12),
    Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        color: AppColors.text,
        fontSize: 16,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    ),
  ]);
}

class _ProfileField extends StatelessWidget {
  final String label, value;
  const _ProfileField({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppColors.accentText,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value.toUpperCase(),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PrefTile extends StatelessWidget {
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _PrefTile({required this.label, this.subtitle, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => SwitchListTile(
    title: Text(
      label,
      style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 1),
    ),
    subtitle: subtitle != null ? Text(subtitle!.toUpperCase(), style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, letterSpacing: 1)) : null,
    value: value,
    onChanged: onChanged,
    activeColor: AppColors.inverseSurface,
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.toggleInactiveTrack,
    inactiveThumbColor: AppColors.toggleInactiveThumb,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
  );
}
