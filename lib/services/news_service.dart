import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

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

/// Devuelve la URL de imagen pasada por el proxy del backend para evitar CORS.
String proxiedImageUrl(String imageUrl) {
  if (imageUrl.isEmpty) return '';
  final base = AuthService().baseUrl;
  return '$base/proxy/image?url=${Uri.encodeComponent(imageUrl)}';
}

class NewsService {
  final String _base = AuthService().baseUrl;

  Future<List<NewsArticle>> getWC2026News() async {
    final resp = await http.get(
      Uri.parse('$_base/news'),
      headers: AuthService().getAuthHeaders(),
    );
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      final list = data['articles'] as List<dynamic>? ?? [];
      return list.map((e) => NewsArticle.fromJson(e as Map<String, dynamic>)).toList();
    }
    throw Exception('Error cargando noticias (${resp.statusCode})');
  }
}
