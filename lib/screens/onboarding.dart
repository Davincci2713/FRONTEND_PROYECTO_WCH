import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import '../services/auth/auth.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;

  // Step 1: Team Selection
  String? _selectedTeam;
  final List<String> _teams = [
    'Argentina', 'Brasil', 'Colombia', 'Uruguay', 'Ecuador',
    'Francia', 'España', 'Inglaterra', 'Alemania', 'Portugal',
    'Estados Unidos', 'México', 'Canadá', 'Marruecos', 'Japón',
  ];

  // Step 2: City / Stadium preferences
  final List<String> _selectedCities = [];
  final List<String> _hostCities = [
    'Nueva York', 'Los Angeles', 'Dallas', 'San Francisco', 'Seattle',
    'Miami', 'Boston', 'Atlanta', 'Kansas City', 'Philadelphia',
    'Houston', 'Vancouver', 'Toronto', 'Guadalajara', 'Monterrey',
    'Ciudad de México',
  ];

  // Step 3: Notifications
  bool _prefPush    = true;
  bool _prefTrades  = true;
  bool _prefMatches = true;
  bool _prefBets    = true;

  bool get _canAdvance {
    if (_currentPage == 0) return _selectedTeam != null;
    return true;
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selectedTeam != null) {
      await prefs.setString('favorite_team', _selectedTeam!);
    }
    if (_selectedCities.isNotEmpty) {
      await prefs.setStringList('favorite_cities', _selectedCities);
    }
    await prefs.setBool('pref_push', _prefPush);
    await prefs.setBool('pref_trades', _prefTrades);
    await prefs.setBool('pref_matches', _prefMatches);
    await prefs.setBool('pref_bets', _prefBets);

    // Persist preferences to backend
    try {
      await AuthService().updatePreferences({
        'notif_push':        _prefPush,
        'notif_email':       _prefPush,
        'notif_trades':      _prefTrades,
        'notif_matches':     _prefMatches,
        'notif_bets':        _prefBets,
        'favorite_teams':    _selectedTeam != null ? [_selectedTeam!] : [],
        'favorite_cities':   _selectedCities,
        'favorite_stadiums': [],
      });
    } catch (_) {}

    await AuthService().completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (_currentPage + 1) / _totalPages,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildTeamSelectionPage(),
                  _buildCitySelectionPage(),
                  _buildNotificationPage(),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 2)),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.text, width: 2),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      child: Text('ATRAS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _canAdvance ? _nextPage : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.inverseSurface,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == _totalPages - 1 ? 'EMPEZAR' : 'SIGUIENTE',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Page 1: Team selection
  // -------------------------------------------------------------------------
  Widget _buildTeamSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BIENVENIDO AL\nHUB.',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 48, height: 0.9, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -2)),
          const SizedBox(height: 16),
          Text('ELIGE TU SELECCION FAVORITA. RECIBIRAS NOTICIAS Y ALERTAS DESTACADAS SOBRE ELLOS.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _teams.map((team) {
              final isSelected = _selectedTeam == team;
              return GestureDetector(
                onTap: () => setState(() => _selectedTeam = isSelected ? null : team),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(team.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                          color: isSelected ? Colors.black : AppColors.text,
                          fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Page 2: City / venue preferences
  // -------------------------------------------------------------------------
  Widget _buildCitySelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TU AGENDA\nPOR CIUDAD.',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 48, height: 0.9, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -2)),
          const SizedBox(height: 16),
          Text('SELECCIONA LAS CIUDADES SEDE QUE TE INTERESAN. VERÁS PRIMERO LOS PARTIDOS EN ESAS SEDES Y RECIBIRAS ALERTAS RELEVANTES.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 8),
          Text('(OPCIONAL — PUEDES SALTARTE ESTE PASO)',
              style: GoogleFonts.dmSans(
                  fontSize: 11, letterSpacing: 1.2, color: AppColors.textMuted)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _hostCities.map((city) {
              final isSelected = _selectedCities.contains(city);
              return GestureDetector(
                onTap: () => setState(() {
                  isSelected ? _selectedCities.remove(city) : _selectedCities.add(city);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(city.toUpperCase(),
                      style: GoogleFonts.spaceGrotesk(
                          color: isSelected ? Colors.black : AppColors.text,
                          fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Page 3: Notification preferences
  // -------------------------------------------------------------------------
  Widget _buildNotificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANTENTE\NAL TANTO.',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 48, height: 0.9, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -2)),
          const SizedBox(height: 16),
          Text('ELIGE QUE TIPO DE NOTIFICACIONES DESEAS RECIBIR. PODRAS CAMBIAR ESTO MAS TARDE EN TU PERFIL.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5,
                  color: AppColors.textMuted, height: 1.5)),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: SwitchListTile(
              title: Text('ACTIVAR NOTIFICACIONES PUSH',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text)),
              subtitle: Text('Recomendado para no perderte nada',
                  style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
              value: _prefPush,
              onChanged: (val) => setState(() => _prefPush = val),
              activeThumbColor: AppColors.inverseSurface,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.toggleInactiveTrack,
              inactiveThumbColor: AppColors.toggleInactiveThumb,
            ),
          ),
          const SizedBox(height: 24),
          AnimatedOpacity(
            opacity: _prefPush ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_prefPush,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('SOLICITUDES DE INTERCAMBIO',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Cuando alguien quiera cambiar una lamina',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefTrades,
                      onChanged: (val) => setState(() => _prefTrades = val),
                      activeThumbColor: AppColors.inverseSurface,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      inactiveThumbColor: AppColors.textMuted,
                    ),
                    const Divider(height: 2),
                    SwitchListTile(
                      title: Text('RECORDATORIOS DE PARTIDOS',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Inicio y final de partidos de tu seleccion',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefMatches,
                      onChanged: (val) => setState(() => _prefMatches = val),
                      activeThumbColor: AppColors.inverseSurface,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      inactiveThumbColor: AppColors.textMuted,
                    ),
                    const Divider(height: 2),
                    SwitchListTile(
                      title: Text('RESULTADOS DE POLLAS',
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Aciertos y subidas en el ranking',
                          style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefBets,
                      onChanged: (val) => setState(() => _prefBets = val),
                      activeThumbColor: AppColors.inverseSurface,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      inactiveThumbColor: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
