import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

class TicketService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _h => {
    'Content-Type': 'application/json',
    ...AuthService().getAuthHeaders(),
  };

  Future<List<dynamic>> getAvailableMatches() async {
    final r = await http.get(Uri.parse('$baseUrl/matches/ticketing'), headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body)['matches'] ?? [];
    throw Exception('Error cargando partidos');
  }

  Future<List<dynamic>> getUserTickets(int userId) async {
    final r = await http.get(Uri.parse('$baseUrl/users/$userId/tickets'), headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Error cargando entradas');
  }

  Future<Map<String, dynamic>> reserveTicket(int userId, int matchId) async {
    final r = await http.post(Uri.parse('$baseUrl/tickets/reserve'),
        headers: _h, body: jsonEncode({'userId': userId, 'matchId': matchId}));
    final d = jsonDecode(r.body);
    if (r.statusCode == 200) return d;
    throw Exception(d['message'] ?? 'Error al reservar');
  }

  Future<Map<String, dynamic>> payTicket(int ticketId, int userId) async {
    final r = await http.post(Uri.parse('$baseUrl/tickets/$ticketId/pay'),
        headers: _h,
        body: jsonEncode({'userId': userId, 'paymentToken': 'pm_card_visa'}));
    final d = jsonDecode(r.body);
    if (r.statusCode == 200) return d;
    throw Exception(d['message'] ?? 'Error al pagar');
  }

  Future<Map<String, dynamic>> transferTicketByEmail(
      int ticketId, int fromUserId, String toEmail) async {
    final r = await http.post(Uri.parse('$baseUrl/tickets/$ticketId/transfer-by-email'),
        headers: _h,
        body: jsonEncode({'fromUserId': fromUserId, 'toEmail': toEmail}));
    final d = jsonDecode(r.body);
    if (r.statusCode == 200) return d;
    throw Exception(d['message'] ?? 'Error al transferir');
  }

  Future<Map<String, dynamic>> refundTicket(int ticketId, int userId, String reason) async {
    final r = await http.post(Uri.parse('$baseUrl/tickets/$ticketId/refund'),
        headers: _h,
        body: jsonEncode({'userId': userId, 'reason': reason}));
    final d = jsonDecode(r.body);
    if (r.statusCode == 200) return d;
    throw Exception(d['message'] ?? 'Error al reembolsar');
  }

  Future<List<dynamic>> getTicketHistory(int ticketId) async {
    final r = await http.get(
        Uri.parse('$baseUrl/tickets/$ticketId/history'), headers: _h);
    if (r.statusCode == 200) return jsonDecode(r.body);
    throw Exception('Error cargando historial');
  }
}
