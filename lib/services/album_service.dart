import 'dart:convert';
import 'package:frontend_proyecto/config.dart';
import 'package:http/http.dart' as http;
import 'auth/auth.dart';

class AlbumService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        ...AuthService().getAuthHeaders(),
      };

  Future<Map<String, dynamic>> getUserAlbum(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/album'), headers: _h);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el álbum del usuario');
    }
  }

  Future<Map<String, dynamic>> openPack(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/packs/open'),
      headers: _h,
    );

    final data = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Error al abrir sobre');
    }
  }

  Future<Map<String, dynamic>> getAlbumProgress(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$userId/album/progress'), headers: _h);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Error al obtener el progreso del álbum: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> proposeTrade(
      int proposerId, String receiverEmail, List<int> offeredStickerIds, int requestedStickerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/album/exchange/propose'),
      headers: _h,
      body: jsonEncode({
        'proposer_id': proposerId,
        'receiver_email': receiverEmail,
        'offered_sticker_ids': offeredStickerIds,
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
