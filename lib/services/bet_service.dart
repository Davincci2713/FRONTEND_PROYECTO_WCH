import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

class BetService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        ...AuthService().getAuthHeaders(),
      };

  Future<Map<String, dynamic>> submitBet(int matchId, int userId, int homeGoals, int awayGoals) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bets'),
      headers: _h,
      body: jsonEncode({
        'matchId': matchId,
        'userId': userId,
        'homeGoals': homeGoals,
        'awayGoals': awayGoals,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al enviar pronóstico: ${response.body}');
    }
  }
}
