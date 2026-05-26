import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import 'package:frontend_proyecto/utils/responsive.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/services/match_service.dart';
import 'package:frontend_proyecto/services/news_service.dart' show NewsArticle, NewsService, proxiedImageUrl;
import 'package:frontend_proyecto/screens/news_detail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Inicio extends StatefulWidget {
  const Inicio({super.key});

  @override
  State<Inicio> createState() => _InicioState();
}

class _InicioState extends State<Inicio> {
  final _matchService = MatchService();
  final _newsService  = NewsService();

  int _upcomingMatchesCount = 0;
  List<NewsArticle> _articles = [];
  bool _newsLoading = true;
  String? _newsError;
  bool _newsStale = false;

  // Agenda personal
  List<dynamic> _agendaMatches = [];
  bool _agendaLoading = true;
  String _agendaCityFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchNews();
    _loadAgenda();
  }

  Future<void> _loadAgenda({String city = ''}) async {
    setState(() => _agendaLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final favCities = prefs.getStringList('favorite_cities') ?? [];
      final effectiveCity = city.isNotEmpty ? city : (favCities.isNotEmpty ? favCities.first : '');
      final matches = await _matchService.getAgenda(city: effectiveCity.isNotEmpty ? effectiveCity : null);
      if (mounted) {
        setState(() {
          _agendaMatches = matches;
          _agendaCityFilter = effectiveCity;
          _agendaLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _agendaLoading = false);
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final matches = await _matchService.getAllMatches();
      if (mounted) setState(() => _upcomingMatchesCount = matches.length);
    } catch (_) {}
  }

  Future<void> _fetchNews() async {
    final result = await _newsService.getWC2026News();
    if (!mounted) return;
    setState(() {
      _articles   = result.articles;
      _newsStale  = result.isStale;
      _newsLoading = false;
      _newsError  = result.articles.isEmpty ? 'No se pudieron cargar las noticias' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final user = AuthService().currentUser ?? {};
    final firstName = user['firstName'] ?? 'FANÁTICO';
    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      onRefresh: () async {
        setState(() { _newsLoading = true; _newsError = null; });
        await _fetchNews();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(left: 24, right: 24, top: R.s(context, 32), bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BIENVENIDO,\n${firstName.toUpperCase()}.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: R.fs(context, 48),
                fontWeight: FontWeight.w900,
                color: AppColors.text,
                letterSpacing: -2,
                height: 0.9,
              ),
            ),
            SizedBox(height: 32),

            // ── Banner datos provisionales ───────────────────────────────
            if (_newsStale)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  border: Border.all(color: AppColors.onPrimary, width: 2),
                ),
                child: Row(children: [
                  Icon(Icons.wifi_off_rounded, size: 20, color: AppColors.onPrimary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'INFORMACIÓN SIN CONEXIÓN — ACTUALIZACIÓN PENDIENTE.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.onPrimary, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ]),
              ),

            // ── Agenda personal ──────────────────────────────────────────
            _AgendaSection(
              matches: _agendaMatches,
              loading: _agendaLoading,
              cityFilter: _agendaCityFilter,
              onCityChanged: (city) => _loadAgenda(city: city),
            ),
            const SizedBox(height: 48),

            // ── Dashboard cards ─────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 300
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24) / 2;
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: DashboardCard(
                      title: 'PARTIDOS',
                      subtitle: '$_upcomingMatchesCount PROGRAMADOS',
                      icon: Icons.calendar_month,
                      onTap: () => context.go('/tickets'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: DashboardCard(
                      title: 'MI ÁLBUM',
                      subtitle: 'VER COLECCIÓN',
                      icon: Icons.book,
                      onTap: () => context.go('/album'),
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: DashboardCard(
                      title: 'COMUNIDADES',
                      subtitle: 'VER RANKING',
                      icon: Icons.group,
                      onTap: () => context.go('/comunidades'),
                    ),
                  ),
                ],
              );
            }),

            SizedBox(height: 48),

            // ── Noticias ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'NOTICIAS DEL MUNDIAL',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: R.fs(context, 24),
                    fontWeight: FontWeight.w900,
                    color: AppColors.text,
                    letterSpacing: -1,
                  ),
                ),
                if (!_newsLoading)
                  TextButton.icon(
                    onPressed: () {
                      setState(() { _newsLoading = true; _newsError = null; });
                      _fetchNews();
                    },
                    icon: Icon(Icons.refresh, size: 16),
                    label: Text('ACTUALIZAR', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            SizedBox(height: 24),

            if (_newsLoading)
              const _NewsShimmer()
            else if (_newsError != null)
              _NewsError(message: _newsError!, onRetry: () {
                setState(() { _newsLoading = true; _newsError = null; });
                _fetchNews();
              })
            else if (_articles.isEmpty)
              _NewsEmpty()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _articles.length,
                separatorBuilder: (_, __) => SizedBox(height: 24),
                itemBuilder: (_, i) => _NewsCard(article: _articles[i]),
              ),

            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── News widgets ─────────────────────────────────────────────────────────────

class _NewsCard extends StatelessWidget {
  final NewsArticle article;
  const _NewsCard({required this.article});

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => showNewsDetail(context, article),
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen
            Container(
              width: 120,
              decoration: BoxDecoration(
                color: AppColors.background,
                border: Border(right: BorderSide(color: AppColors.border, width: 2)),
              ),
              child: hasImage
                  ? Image.network(
                      proxiedImageUrl(article.imageUrl),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(),
                    )
                  : _ImagePlaceholder(),
            ),

            // Contenido
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (article.source.isNotEmpty)
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                            ),
                            child: Text(
                              article.source.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                color: AppColors.onPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (article.formattedDate.isNotEmpty)
                            Text(
                              article.formattedDate.toUpperCase(),
                              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    SizedBox(height: 8),
                    Text(
                      article.title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppColors.text,
                        height: 1.1,
                      ),
                    ),
                    if (article.description.isNotEmpty) ...[
                      SizedBox(height: 6),
                      Flexible(
                        child: Text(
                          article.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.primary,
    child: Center(
      child: Icon(Icons.sports_soccer, color: AppColors.onPrimary, size: 32),
    ),
  );
}

class _NewsShimmer extends StatelessWidget {
  const _NewsShimmer();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(3, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.borderLight, width: 2),
        ),
      ),
    )),
  );
}

class _NewsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _NewsError({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.error, width: 2),
    ),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 40),
          SizedBox(height: 16),
          Text(message.toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.text, fontWeight: FontWeight.bold, letterSpacing: 1)),
          SizedBox(height: 16),
          OutlinedButton(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(color: AppColors.error, width: 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            child: Text('REINTENTAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

class _NewsEmpty extends StatelessWidget {
  const _NewsEmpty();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(48),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.border, width: 2),
    ),
    child: Center(
      child: Text(
        'NO HAY NOTICIAS DISPONIBLES',
        style: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 18),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ── Agenda section ─────────────────────────────────────────────────────────────

class _AgendaSection extends StatelessWidget {
  final List<dynamic> matches;
  final bool loading;
  final String cityFilter;
  final ValueChanged<String> onCityChanged;

  const _AgendaSection({
    required this.matches,
    required this.loading,
    required this.cityFilter,
    required this.onCityChanged,
  });

  static const _cities = [
    '', 'Nueva York', 'Los Angeles', 'Dallas', 'Miami', 'Seattle',
    'Boston', 'Houston', 'Ciudad de Mexico', 'Guadalajara', 'Vancouver',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'AGENDA POR CIUDAD',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24, fontWeight: FontWeight.w900,
                  color: AppColors.text, letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _cities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final city = _cities[i];
              final label = city.isEmpty ? 'TODAS' : city.toUpperCase();
              final selected = cityFilter == city;
              return GestureDetector(
                onTap: () => onCityChanged(city),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Text(label,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, fontWeight: FontWeight.w800,
                        color: selected ? Colors.black : AppColors.text,
                        letterSpacing: 0.5,
                      )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (loading)
          Container(
            height: 80,
            decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight, width: 2)),
          )
        else if (matches.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2)),
            child: Text(
              cityFilter.isEmpty ? 'NO HAY PARTIDOS PROGRAMADOS' : 'NO HAY PARTIDOS EN $cityFilter',
              style: GoogleFonts.spaceGrotesk(
                color: AppColors.textMuted, fontWeight: FontWeight.w900, fontSize: 14),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matches.length > 5 ? 5 : matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AgendaMatchTile(match: matches[i]),
          ),
      ],
    );
  }
}

class _AgendaMatchTile extends StatelessWidget {
  final Map<String, dynamic> match;
  const _AgendaMatchTile({required this.match});

  @override
  Widget build(BuildContext context) {
    final home  = match['homeTeamName'] ?? '?';
    final away  = match['awayTeamName'] ?? '?';
    final city  = match['city'] ?? match['stadiumName'] ?? '';
    final phase = (match['phases'] as List?)?.firstOrNull ?? '';
    final dateStr = match['scheduledAt'] ?? '';
    String dateLabel = '';
    if (dateStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateStr).toLocal();
        dateLabel = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${home.toUpperCase()} vs ${away.toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.text)),
                if (city.isNotEmpty || phase.isNotEmpty)
                  Text(
                    [if (city.isNotEmpty) city, if (phase.isNotEmpty) phase].join(' — ').toUpperCase(),
                    style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted, letterSpacing: 1),
                  ),
              ],
            ),
          ),
          if (dateLabel.isNotEmpty)
            Text(dateLabel,
                style: GoogleFonts.spaceGrotesk(
                    fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentText)),
        ],
      ),
    );
  }
}

// ── Dashboard card ────────────────────────────────────────────────────────────

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
              ),
              child: Icon(icon, size: 24, color: AppColors.onPrimary),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: AppColors.text,
                letterSpacing: -1,
              ),
            ),
            SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                color: AppColors.accentText,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

