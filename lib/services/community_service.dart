import 'dart:convert';
import 'package:http/http.dart' as http;

class CommunityService {
  final String baseUrl = "http://localhost:5001/api/v1";

  Future<Map<String, dynamic>> createCommunity(String name, int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/communities'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'userId': userId}),
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

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el ranking');
    }
  }
}
