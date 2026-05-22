import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

class MatchService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        ...AuthService().getAuthHeaders(),
      };

  Future<List<dynamic>> getAllMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches'), headers: _h);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener los partidos');
    }
  }

  Future<List<dynamic>> getLiveMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches/live'), headers: _h);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener partidos en vivo');
    }
  }
}
