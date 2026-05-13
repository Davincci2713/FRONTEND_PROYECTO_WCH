import 'dart:convert';
import 'package:http/http.dart' as http;

class MatchService {
  final String baseUrl = "http://localhost:5001/api/v1";

  Future<List<dynamic>> getAllMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener los partidos');
    }
  }

  Future<List<dynamic>> getLiveMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches/live'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener partidos en vivo');
    }
  }
}
