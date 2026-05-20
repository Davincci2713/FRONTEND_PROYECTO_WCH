import 'package:frontend_proyecto/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_proyecto/services/news_service.dart' show NewsArticle, proxiedImageUrl;
import 'package:frontend_proyecto/utils/url_opener.dart';

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
        SnackBar(
          content: Text('NO SE PUDO ABRIR EL ENLACE', 
            style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = article.imageUrl.isNotEmpty;
    final hasUrl   = article.url.isNotEmpty;
    final screenH  = MediaQuery.of(context).size.height;

    return Container(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: screenH * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header Handle (Brutalist style) ──────────────────────────
          Container(
            height: 12,
            width: double.infinity,
            color: AppColors.primary,
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                color: AppColors.onPrimary,
              ),
            ),
          ),

          // ── Contenido scrollable ─────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: hasImage 
                        ? Image.network(
                            proxiedImageUrl(article.imageUrl),
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                    ),
                  ),

                  SizedBox(height: 32),

                  // Fuente + fecha
                  Row(
                    children: [
                      if (article.source.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                          ),
                          child: Text(
                            article.source.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: AppColors.onPrimary,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      if (article.formattedDate.isNotEmpty)
                        Text(
                          article.formattedDate.toUpperCase(),
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMuted,
                            letterSpacing: 1,
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Título
                  Text(
                    article.title.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),

                  SizedBox(height: 24),
                  Divider(color: AppColors.border, thickness: 2),
                  SizedBox(height: 24),

                  // Descripción
                  if (article.description.isNotEmpty)
                    Text(
                      article.description,
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: AppColors.text,
                        height: 1.6,
                      ),
                    )
                  else
                    Text(
                      'NO HAY MÁS DETALLES DISPONIBLES PARA ESTA NOTICIA.',
                      style: GoogleFonts.dmSans(
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),

                  if (hasUrl) ...[
                    SizedBox(height: 48),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton.icon(
                        onPressed: () => _openUrl(context),
                        icon: Icon(Icons.open_in_new_sharp, size: 20),
                        label: Text(
                          'VER ARTÍCULO COMPLETO',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          side: BorderSide(color: AppColors.onPrimary, width: 2),
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
        color: AppColors.primary,
        child: Center(
          child: Icon(Icons.sports_soccer_sharp, color: AppColors.onPrimary, size: 48),
        ),
      );
}
