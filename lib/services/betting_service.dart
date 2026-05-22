import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

class BettingService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    ...AuthService().getAuthHeaders(),
  };

  Future<List<dynamic>> getBettingMatches() async {
    final r = await http.get(Uri.parse('$baseUrl/matches/betting'), headers: _headers);
    if (r.statusCode == 200) return jsonDecode(r.body)['matches'] ?? [];
    throw Exception('Error al cargar partidos');
  }

  Future<List<dynamic>> getUserBets(int userId) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$userId/sports-bets'), headers: _headers);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Error al cargar apuestas');
  }

  Future<Map<String, dynamic>> placeBet({
    required int userId,
    required dynamic matchId,
    required String homeName,
    required String awayName,
    required String betType,
    required String betLabel,
    required double odds,
    required int stake,
  }) async {
    final r = await http.post(
      Uri.parse('$baseUrl/sports-bets'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId, 'matchId': matchId,
        'homeName': homeName, 'awayName': awayName,
        'betType': betType, 'betLabel': betLabel,
        'odds': odds, 'stake': stake,
      }),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode == 201) return data;
    throw Exception(data['message'] ?? 'Error al registrar apuesta');
  }
}
