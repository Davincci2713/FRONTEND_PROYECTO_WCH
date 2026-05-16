import 'package:flutter/material.dart';
import '../services/news_service.dart' show NewsArticle, proxiedImageUrl;
import '../utils/url_opener.dart';

/// Muestra el detalle de una noticia como bottom sheet modal.
void showNewsDetail(BuildContext context, NewsArticle article) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _NewsDetailSheet(article: article),
  );
}

class _NewsDetailSheet extends StatelessWidget {
  final NewsArticle article;
  const _NewsDetailSheet({required this.article});

  Future<void> _openUrl(BuildContext context) async {
    if (article.url.isEmpty) return;
    final ok = await openExternalUrl(article.url);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.isNotEmpty;
    final hasUrl   = article.url.isNotEmpty;
    final screenH  = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.88),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Contenido scrollable ─────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen
                  if (hasImage)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          proxiedImageUrl(article.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(),
                        ),
                      ),
                    )
                  else
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _placeholder(),
                      ),
                    ),

                  const SizedBox(height: 20),

                  // Fuente + fecha
                  Row(
                    children: [
                      if (article.source.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00341C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            article.source,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00341C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      if (article.formattedDate.isNotEmpty)
                        Text(
                          article.formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Título
                  Text(
                    article.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200, height: 1),
                  const SizedBox(height: 16),

                  // Descripción
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        height: 1.65,
                      ),
                    )
                  else
                    Text(
                      'No hay más detalles disponibles para esta noticia.',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                  if (hasUrl) ...[
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(context),
                        icon: const Icon(Icons.open_in_new, size: 18),
                        label: const Text(
                          'Ver artículo completo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00341C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
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
    );
  }

  Widget _placeholder() => Container(
        color: const Color(0xFF00341C).withValues(alpha: 0.07),
        child: const Center(
          child: Icon(Icons.sports_soccer, color: Color(0xFF00341C), size: 48),
        ),
      );
}
