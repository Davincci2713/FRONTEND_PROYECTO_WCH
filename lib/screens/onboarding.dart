import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  // Step 1: Team Selection
  String? _selectedTeam;
  final List<String> _teams = [
    'Argentina', 'Brasil', 'Colombia', 'Uruguay', 'Ecuador',
    'Francia', 'España', 'Inglaterra', 'Alemania', 'Portugal'
  ];

  // Step 2: Notifications
  bool _prefPush = true;
  bool _prefTrades = true;
  bool _prefMatches = true;
  bool _prefBets = true;

  void _nextPage() {
    if (_currentPage < 1) {
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
    // Save team preference
    if (_selectedTeam != null) {
      await prefs.setString('favorite_team', _selectedTeam!);
    }
    
    // Save notification preferences
    await prefs.setBool('pref_push', _prefPush);
    await prefs.setBool('pref_trades', _prefTrades);
    await prefs.setBool('pref_matches', _prefMatches);
    await prefs.setBool('pref_bets', _prefBets);

    // Complete onboarding in Auth Service
    await AuthService().completeOnboarding();
    // The router will automatically redirect to /home because of the listener
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
            // Progress Indicator (Brutalist style)
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
                        widthFactor: (_currentPage + 1) / 2,
                        child: Container(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Pages
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildTeamSelectionPage(),
                  _buildNotificationPage(),
                ],
              ),
            ),

            // Bottom Buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 2)),
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    OutlinedButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.text,
                        side: BorderSide(color: AppColors.text, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                      child: Text('ATRÁS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_currentPage == 0 && _selectedTeam == null) ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.inverseSurface,
                      disabledBackgroundColor: Colors.grey.shade800,
                      disabledForegroundColor: Colors.grey.shade500,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                      side: BorderSide(color: (_currentPage == 0 && _selectedTeam == null) ? Colors.transparent : AppColors.primary, width: 2),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == 1 ? 'EMPEZAR' : 'SIGUIENTE',
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

  Widget _buildTeamSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BIENVENIDO AL\nHUB.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'PARA PERSONALIZAR TU EXPERIENCIA, ELIGE TU SELECCIÓN FAVORITA. RECIBIRÁS NOTICIAS Y ALERTAS DESTACADAS SOBRE ELLOS.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 48),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _teams.map((team) {
              final isSelected = _selectedTeam == team;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTeam = isSelected ? null : team;
                  });
                },
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
                  child: Text(
                    team.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      color: isSelected ? Colors.black : AppColors.text,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MANTENTE\nAL TANTO.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 48,
              height: 0.9,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'ELIGE QUÉ TIPO DE NOTIFICACIONES DESEAS RECIBIR. PODRÁS CAMBIAR ESTO MÁS TARDE EN TU PERFIL.',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: AppColors.textMuted,
              height: 1.5,
            ),
          ),
          SizedBox(height: 48),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('ACTIVAR NOTIFICACIONES PUSH', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text)),
                  subtitle: Text('Recomendado para no perderte nada', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                  value: _prefPush,
                  onChanged: (val) => setState(() => _prefPush = val),
                  activeColor: AppColors.inverseSurface,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.toggleInactiveTrack,
                  inactiveThumbColor: AppColors.toggleInactiveThumb,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          AnimatedOpacity(
            opacity: _prefPush ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_prefPush,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppColors.border, width: 2),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text('SOLICITUDES DE INTERCAMBIO', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Cuando alguien quiera cambiar una lámina', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefTrades,
                      onChanged: (val) => setState(() => _prefTrades = val),
                      activeColor: AppColors.inverseSurface,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      inactiveThumbColor: AppColors.textMuted,
                    ),
                    Divider(height: 2),
                    SwitchListTile(
                      title: Text('RECORDATORIOS DE PARTIDOS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Inicio y final de partidos de tu selección', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefMatches,
                      onChanged: (val) => setState(() => _prefMatches = val),
                      activeColor: AppColors.inverseSurface,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: AppColors.borderLight,
                      inactiveThumbColor: AppColors.textMuted,
                    ),
                    Divider(height: 2),
                    SwitchListTile(
                      title: Text('RESULTADOS DE POLLAS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w800, color: AppColors.text, fontSize: 14)),
                      subtitle: Text('Aciertos y subidas en el ranking', style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12)),
                      value: _prefBets,
                      onChanged: (val) => setState(() => _prefBets = val),
                      activeColor: AppColors.inverseSurface,
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
