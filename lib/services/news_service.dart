import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String imageUrl;
  final String source;
  final String publishedAt;

  const NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    required this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  factory NewsArticle.fromJson(Map<String, dynamic> j) => NewsArticle(
        title:       j['title']       as String? ?? '',
        description: j['description'] as String? ?? '',
        url:         j['url']         as String? ?? '',
        imageUrl:    j['imageUrl']    as String? ?? '',
        source:      j['source']      as String? ?? '',
        publishedAt: j['publishedAt'] as String? ?? '',
      );

  String get formattedDate {
    try {
      final dt = DateTime.parse(publishedAt).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}

/// Resultado de getWC2026News: artículos + bandera de datos provisionales.
class NewsResult {
  final List<NewsArticle> articles;
  final bool isStale;
  const NewsResult(this.articles, {this.isStale = false});
}

/// Devuelve la URL de imagen pasada por el proxy del backend para evitar CORS.
String proxiedImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  final base = AuthService().baseUrl;
  return '$base/proxy/image?url=${Uri.encodeComponent(imageUrl)}';
}

class NewsService {
  final String _base = AuthService().baseUrl;
  static const _cacheKey = 'cache:news:wc2026';

  Future<NewsResult> getWC2026News() async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/news'),
        headers: AuthService().getAuthHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final list = (data['articles'] as List<dynamic>? ?? [])
            .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
            .toList();
        // Persist fresh data for future fallback
        _saveCache(resp.body);
        return NewsResult(list);
      }
    } catch (_) {}

    // Fallback: serve last known data from SharedPreferences
    final cached = await _loadCache();
    if (cached != null) {
      return NewsResult(cached, isStale: true);
    }
    return const NewsResult([], isStale: true);
  }

  Future<void> _saveCache(String raw) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, raw);
    } catch (_) {}
  }

  Future<List<NewsArticle>?> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final data = jsonDecode(raw);
      final list = (data['articles'] as List<dynamic>? ?? [])
          .map((e) => NewsArticle.fromJson(e as Map<String, dynamic>))
          .toList();
      return list;
    } catch (_) {
      return null;
    }
  }
}
