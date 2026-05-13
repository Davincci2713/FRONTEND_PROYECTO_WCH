import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveLayout(
      mobile: _LoginMobile(),
      web: _LoginWeb(),
    );
  }
}

// ── WEB ─────────────────────────────────────────────────────────────────────
class _LoginWeb extends StatelessWidget {
  const _LoginWeb();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Row(
        children: [
          Expanded(child: const _HeroPanel()),
          Container(
            width: 480,
            color: AppTheme.surfaceCard,
            child: const SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 56, vertical: 64),
              child: _LoginForm(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── MÓVIL ─────────────────────────────────────────────────────────────────
class _LoginMobile extends StatelessWidget {
  const _LoginMobile();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Stack(
        children: [
          const Positioned.fill(child: _StadiumBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const Icon(Icons.sports_soccer, color: AppTheme.accentRed, size: 40),
                  ),
                  const SizedBox(height: 40),
                  const SizedBox(
                    height: 200,
                    child: _InfiniteCarousel(),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceCard.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: const _LoginForm(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── CARRUSEL INFINITO QUE SE MUEVE CONSTANTEMENTE A LA DERECHA ────────────────
class _InfiniteCarousel extends StatefulWidget {
  const _InfiniteCarousel();

  @override
  State<_InfiniteCarousel> createState() => _InfiniteCarouselState();
}

class _InfiniteCarouselState extends State<_InfiniteCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  
  // Duplicamos los items para crear el efecto infinito
  late final List<FeatureItem> _infiniteFeatures;
  
  final List<FeatureItem> _originalFeatures = const [
    FeatureItem(
      icon: Icons.confirmation_number,
      title: 'COMPRAR BOLETAS',
      description: 'Adquiere tus entradas para los partidos del Mundial 2026',
      color: AppTheme.accentRed,
    ),
    FeatureItem(
      icon: Icons.calendar_today,
      title: 'AGENDA',
      description: 'Organiza tu calendario de partidos y eventos',
      color: AppTheme.accentBlue,
    ),
    FeatureItem(
      icon: Icons.workspace_premium,
      title: 'POLLAS',
      description: 'Crea y participa en quinielas con amigos',
      color: AppTheme.accentGreen,
    ),
    FeatureItem(
      icon: Icons.photo_album,
      title: 'ÁLBUM',
      description: 'Colecciona figuritas digitales del mundial',
      color: AppTheme.accentYellow,
    ),
    FeatureItem(
      icon: Icons.account_balance_wallet,
      title: 'BILLETERA',
      description: 'Gestiona tus pagos y recompensas',
      color: AppTheme.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Duplicamos los items 3 veces para que el bucle sea infinito
    _infiniteFeatures = [..._originalFeatures, ..._originalFeatures, ..._originalFeatures];
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: _originalFeatures.length, // Comenzamos en la copia del medio
    );
    _startInfiniteScroll();
  }

  void _startInfiniteScroll() {
    // Mover constantemente a la derecha cada 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), _moveToNext);
  }

  void _moveToNext() {
    if (!mounted) return;
    
    final nextPage = _currentPage + 1;
    
    _pageController.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 800),
      curve: Curves.linear, // Movimiento lineal y constante
    );
    
    _startInfiniteScroll();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
        });
        
        // Efecto infinito: cuando llegamos al final, volvemos al inicio sin que se note
        if (index == _infiniteFeatures.length - 1) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _pageController.jumpToPage(_originalFeatures.length);
            setState(() {
              _currentPage = _originalFeatures.length;
            });
          });
        }
        // Cuando llegamos muy al principio (por si alguien scrollea hacia atrás)
        else if (index == 0) {
          Future.delayed(const Duration(milliseconds: 100), () {
            _pageController.jumpToPage(_infiniteFeatures.length - _originalFeatures.length - 1);
            setState(() {
              _currentPage = _infiniteFeatures.length - _originalFeatures.length - 1;
            });
          });
        }
      },
      itemCount: _infiniteFeatures.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: _FeatureCard(feature: _infiniteFeatures[index % _originalFeatures.length]),
        );
      },
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final FeatureItem feature;
  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            feature.color.withOpacity(0.2),
            feature.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: feature.color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, size: 48, color: feature.color),
          ),
          const SizedBox(height: 24),
          Text(
            feature.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              feature.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureItem {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  
  const FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

// ── COMPONENTES ──────────────────────────────────────────────────────────────

class _StadiumBackground extends StatelessWidget {
  const _StadiumBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF001a0e), Color(0xFF0a0a1a), Color(0xFF1a000a)],
            ),
          ),
          child: const Center(
            child: Icon(Icons.stadium, size: 200, color: Color(0x15FFFFFF)),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Panel hero para web con carrusel infinito
class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const _StadiumBackground(),
        Padding(
          padding: const EdgeInsets.all(56),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Icon(Icons.sports_soccer, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text('WCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 3)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'WORLD CUP HUB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tu experiencia definitiva del Mundial 2026',
                style: TextStyle(
                  color: AppTheme.onSurfaceMuted,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: _WebInfiniteCarousel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Carrusel infinito para web (scroll automático constante a la derecha)
class _WebInfiniteCarousel extends StatefulWidget {
  @override
  State<_WebInfiniteCarousel> createState() => _WebInfiniteCarouselState();
}

class _WebInfiniteCarouselState extends State<_WebInfiniteCarousel> {
  late final ScrollController _scrollController;
  int _currentIndex = 0;
  
  late final List<FeatureItem> _infiniteFeatures;
  
  final List<FeatureItem> _originalFeatures = const [
    FeatureItem(
      icon: Icons.confirmation_number,
      title: 'COMPRAR BOLETAS',
      description: 'Adquiere tus entradas oficiales',
      color: AppTheme.accentRed,
    ),
    FeatureItem(
      icon: Icons.calendar_today,
      title: 'AGENDA',
      description: 'Organiza tu itinerario',
      color: AppTheme.accentBlue,
    ),
    FeatureItem(
      icon: Icons.workspace_premium,
      title: 'POLLAS',
      description: 'Crea quinielas',
      color: AppTheme.accentGreen,
    ),
    FeatureItem(
      icon: Icons.photo_album,
      title: 'ÁLBUM',
      description: 'Colecciona figuritas',
      color: AppTheme.accentYellow,
    ),
    FeatureItem(
      icon: Icons.account_balance_wallet,
      title: 'BILLETERA',
      description: 'Gestiona tus pagos',
      color: AppTheme.primary,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Duplicamos items para efecto infinito
    _infiniteFeatures = [..._originalFeatures, ..._originalFeatures, ..._originalFeatures];
    _scrollController = ScrollController(initialScrollOffset: 300);
    _startInfiniteScroll();
  }

  void _startInfiniteScroll() {
    Future.delayed(const Duration(milliseconds: 2500), _scrollToNext);
  }

  void _scrollToNext() {
    if (!mounted) return;
    
    _currentIndex++;
    final cardWidth = 280.0;
    const spacing = 20.0;
    final scrollPosition = _currentIndex * (cardWidth + spacing);
    
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 800),
      curve: Curves.linear,
    );
    
    // Efecto infinito
    if (_currentIndex >= _infiniteFeatures.length - 3) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.jumpTo(300);
        _currentIndex = 0;
      });
    }
    
    _startInfiniteScroll();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: _infiniteFeatures.length,
      itemBuilder: (context, index) {
        return Container(
          width: 280,
          margin: const EdgeInsets.only(right: 20),
          child: _WebFeatureCard(feature: _infiniteFeatures[index % _originalFeatures.length]),
        );
      },
    );
  }
}

class _WebFeatureCard extends StatelessWidget {
  final FeatureItem feature;
  const _WebFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            feature.color.withOpacity(0.15),
            feature.color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: feature.color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: feature.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(feature.icon, size: 40, color: feature.color),
          ),
          const SizedBox(height: 20),
          Text(
            feature.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              feature.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── FORMULARIO ────────────────────────────────────────────────────────────────
class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 4, height: 32, color: AppTheme.accentRed),
            const SizedBox(width: 12),
            const Text(
              'INICIAR SESIÓN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Ingresa a tu cuenta de World Cup Hub',
            style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 13)),
        const SizedBox(height: 32),

        const _FieldLabel('CORREO ELECTRÓNICO'),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'tu@correo.com',
            prefixIcon: const Icon(Icons.email_outlined),
          ),
        ),
        const SizedBox(height: 20),

        const _FieldLabel('CONTRASEÑA'),
        const SizedBox(height: 8),
        TextField(
          obscureText: _obscurePassword,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: '••••••••',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.go('/recover'),
            child: const Text('¿Olvidaste tu contraseña?',
                style: TextStyle(color: AppTheme.accentRed, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 24),

        ElevatedButton(
          onPressed: () => context.go('/home'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentRed,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('INICIAR SESIÓN', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            const Expanded(child: Divider(color: Color(0xFF333333))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('O', style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: Color(0xFF333333))),
          ],
        ),
        const SizedBox(height: 20),

        OutlinedButton(
          onPressed: () => context.go('/register'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFF444444)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          child: const Text('CREAR CUENTA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, letterSpacing: 1.5, fontSize: 12)),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5));
  }
}