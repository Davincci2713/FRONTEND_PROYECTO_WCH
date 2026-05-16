import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;

class MatchService {
  final String baseUrl = kBaseUrl;

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
