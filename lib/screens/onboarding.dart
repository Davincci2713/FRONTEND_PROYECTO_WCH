import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (_currentPage + 1) / 2,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00341C)),
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
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                      ),
                      child: const Text('Atrás'),
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: (_currentPage == 0 && _selectedTeam == null) ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00341C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _currentPage == 1 ? 'Empezar' : 'Siguiente',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¡Bienvenido a World Cup Hub!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Para personalizar tu experiencia, elige tu selección favorita. Recibirás noticias y alertas destacadas sobre ellos.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _teams.map((team) {
              final isSelected = _selectedTeam == team;
              return ChoiceChip(
                label: Text(team),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedTeam = selected ? team : null;
                  });
                },
                selectedColor: const Color(0xFF00341C),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF00341C) : Colors.grey.shade300,
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mantente al tanto',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Elige qué tipo de notificaciones deseas recibir. Podrás cambiar esto más tarde en tu perfil.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Activar notificaciones push', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Recomendado para no perderte nada'),
                  value: _prefPush,
                  onChanged: (val) => setState(() => _prefPush = val),
                  activeColor: const Color(0xFF00341C),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          AnimatedOpacity(
            opacity: _prefPush ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_prefPush,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Solicitudes de intercambio'),
                      subtitle: const Text('Cuando alguien quiera cambiar una lámina'),
                      value: _prefTrades,
                      onChanged: (val) => setState(() => _prefTrades = val),
                      activeColor: const Color(0xFF00341C),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Recordatorios de partidos'),
                      subtitle: const Text('Inicio y final de partidos de tu selección'),
                      value: _prefMatches,
                      onChanged: (val) => setState(() => _prefMatches = val),
                      activeColor: const Color(0xFF00341C),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      title: const Text('Resultados de Pollas'),
                      subtitle: const Text('Aciertos y subidas en el ranking'),
                      value: _prefBets,
                      onChanged: (val) => setState(() => _prefBets = val),
                      activeColor: const Color(0xFF00341C),
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
