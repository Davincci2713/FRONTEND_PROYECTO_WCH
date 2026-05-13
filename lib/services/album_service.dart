import 'dart:convert';
import 'package:http/http.dart' as http;

class AlbumService {
  final String baseUrl = "http://localhost:5001/api/v1";

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
}
