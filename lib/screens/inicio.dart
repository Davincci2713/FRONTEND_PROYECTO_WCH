import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/auth/auth.dart';
import '../services/album_service.dart';
import '../services/match_service.dart';
import '../services/news_service.dart' show NewsArticle, NewsService, proxiedImageUrl;
import 'news_detail.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
    _fetchNews();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final matches = await _matchService.getAllMatches();
      if (mounted) setState(() => _upcomingMatchesCount = matches.length);
    } catch (_) {}
  }

  Future<void> _fetchNews() async {
    try {
      final articles = await _newsService.getWC2026News();
      if (mounted) setState(() {
        _articles = articles;
        _newsLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _newsError = 'No se pudieron cargar las noticias';
        _newsLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = AuthService().currentUser ?? {};
    final firstName = user['firstName'] ?? 'Fanático';

    return RefreshIndicator(
      onRefresh: () async {
        setState(() { _newsLoading = true; _newsError = null; });
        await _fetchNews();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bienvenido de nuevo, $firstName',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // ── Dashboard cards ─────────────────────────────────────────
            LayoutBuilder(builder: (context, constraints) {
              final cardWidth = constraints.maxWidth < 300
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 32) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: DashboardCard(
                      title: 'Próximos partidos',
                      subtitle: '$_upcomingMatchesCount programados',
                      icon: Icons.calendar_month,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardCard(
                      title: 'Mi álbum',
                      subtitle: 'Ver colección',
                      icon: Icons.book,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardCard(
                      title: 'Mis comunidades',
                      subtitle: 'Ver ranking',
                      icon: Icons.group,
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 32),

            // ── Noticias ────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Noticias del Mundial 2026',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (!_newsLoading)
                  TextButton.icon(
                    onPressed: () {
                      setState(() { _newsLoading = true; _newsError = null; });
                      _fetchNews();
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Actualizar', style: TextStyle(fontSize: 13)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00341C),
                      padding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

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
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _NewsCard(article: _articles[i]),
              ),

            const SizedBox(height: 16),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          if (hasImage)
            SizedBox(
              width: 100,
              height: 100,
              child: Image.network(
                proxiedImageUrl(article.imageUrl),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _ImagePlaceholder(),
              ),
            )
          else
            SizedBox(width: 100, height: 100, child: _ImagePlaceholder()),

          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (article.source.isNotEmpty)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00341C).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.source,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF00341C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (article.formattedDate.isNotEmpty)
                          Text(
                            article.formattedDate,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  if (article.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      article.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF00341C).withValues(alpha: 0.06),
    child: const Center(
      child: Icon(Icons.sports_soccer, color: Color(0xFF00341C), size: 28),
    ),
  );
}

class _NewsShimmer extends StatelessWidget {
  const _NewsShimmer();
  @override
  Widget build(BuildContext context) => Column(
    children: List.generate(3, (_) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
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
  Widget build(BuildContext context) => Center(
    child: Column(
      children: [
        Icon(Icons.wifi_off, color: Colors.grey.shade400, size: 40),
        const SizedBox(height: 12),
        Text(message, style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: onRetry,
          child: const Text('Reintentar', style: TextStyle(color: Color(0xFF00341C))),
        ),
      ],
    ),
  );
}

class _NewsEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Text(
        'No hay noticias disponibles ahora mismo.',
        style: TextStyle(color: Colors.grey.shade500),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

// ── Dashboard card ────────────────────────────────────────────────────────────

class DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: const Color(0xFF00341C)),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── CoinsIndicator & AppTopBar (mantenidos para otros widgets que los importan) ─

class CoinsIndicator extends StatefulWidget {
  final Color textColor;
  const CoinsIndicator({super.key, this.textColor = Colors.black87});
  @override
  State<CoinsIndicator> createState() => _CoinsIndicatorState();
}

class _CoinsIndicatorState extends State<CoinsIndicator> {
  int? _coins;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final uid = AuthService().currentUserId;
    if (uid == null) return;
    try {
      final data = await AlbumService().getUserAlbum(uid);
      if (mounted) setState(() => _coins = (data['coins'] as num?)?.toInt());
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            _coins == null ? '—' : '$_coins',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthService(),
      builder: (context, child) {
        final user = AuthService().currentUser ?? {};
        final fullName =
            '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
        final displayName = fullName.isEmpty ? 'Usuario' : fullName;

        final profilePicture = user['profilePicture'] as String?;
        ImageProvider? imageProvider;
        if (profilePicture != null && profilePicture.isNotEmpty) {
          if (profilePicture.startsWith('data:image')) {
            final base64Str = profilePicture.split(',').last;
            imageProvider = MemoryImage(base64Decode(base64Str));
          } else if (profilePicture.startsWith('http')) {
            imageProvider = NetworkImage(profilePicture);
          }
        }

        return Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.notifications_outlined, size: 22),
                  color: Colors.grey.shade700,
                  onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF00341C),
                backgroundImage: imageProvider,
                child: imageProvider == null
                    ? const Icon(Icons.person, color: Colors.white, size: 18)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}
