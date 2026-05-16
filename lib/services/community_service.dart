import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;

class CommunityService {
  final String baseUrl = kBaseUrl;

  Future<Map<String, dynamic>> createCommunity(
    String name,
    int userId, {
    int? maxMembers,
    String? favoriteTeam,
    String? favoritePlayers,
    String? description,
    String? icon,
    String? banner,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/communities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'userId': userId,
        if (maxMembers != null)    'maxMembers': maxMembers,
        if (favoriteTeam != null)  'favoriteTeam': favoriteTeam,
        if (favoritePlayers != null) 'favoritePlayers': favoritePlayers,
        if (description != null)   'description': description,
        if (icon != null)          'icon': icon,
        if (banner != null)        'banner': banner,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al crear la comunidad: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> joinCommunity(int invitationCode, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/communities/join'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'invitationCode': invitationCode, 'userId': userId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al unirse a la comunidad: ${response.body}');
    }
  }

  Future<List<dynamic>> getRanking(int communityId) async {
    final response = await http.get(Uri.parse('$baseUrl/communities/$communityId/ranking'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Error al obtener el ranking');
  }

  Future<List<Map<String, dynamic>>> getMyCommunities(int userId) async {
    final r = await http.get(Uri.parse('$baseUrl/communities/mine?userId=$userId'));
    if (r.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    }
    throw Exception('Error al obtener tus grupos');
  }

  Future<List<Map<String, dynamic>>> getSuggestedCommunities(int userId) async {
    final r = await http.get(Uri.parse('$baseUrl/communities/suggested?userId=$userId'));
    if (r.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(r.body));
    }
    throw Exception('Error al obtener grupos sugeridos');
  }
}
