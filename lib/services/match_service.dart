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
    }
    throw Exception('Error al obtener los partidos');
  }

  Future<List<dynamic>> getLiveMatches() async {
    final response = await http.get(Uri.parse('$baseUrl/matches/live'), headers: _h);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener partidos en vivo');
  }

  /// Returns upcoming matches filtered by optional city, stadium, or phase.
  Future<List<dynamic>> getAgenda({String? city, String? stadium, String? phase}) async {
    final params = <String, String>{};
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (stadium != null && stadium.isNotEmpty) params['stadium'] = stadium;
    if (phase != null && phase.isNotEmpty) params['phase'] = phase;

    final uri = Uri.parse('$baseUrl/matches/agenda').replace(queryParameters: params);
    final response = await http.get(uri, headers: _h);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Error al obtener agenda de partidos');
  }

  Future<List<dynamic>> getPhases() async {
    final response = await http.get(Uri.parse('$baseUrl/matches/phases'), headers: _h);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return [];
  }
}
