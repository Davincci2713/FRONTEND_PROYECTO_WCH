import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;

class AlbumService {
  final String baseUrl = kBaseUrl;

  Future<Map<String, dynamic>> getUserAlbum(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/album'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el álbum del usuario');
    }
  }

  Future<Map<String, dynamic>> openPack(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/packs/open'),
      headers: {'Content-Type': 'application/json'},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error al abrir sobre');
    }
  }

  Future<Map<String, dynamic>> getAlbumProgress(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/album/progress'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el progreso del álbum: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> proposeTrade(int proposerId, String receiverEmail, int offeredStickerId, int requestedStickerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/album/exchange/propose'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'proposer_id': proposerId,
        'receiver_email': receiverEmail,
        'offered_sticker_id': offeredStickerId,
        'requested_sticker_id': requestedStickerId,
      }),
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Error al proponer intercambio'};
    }
  }
}
