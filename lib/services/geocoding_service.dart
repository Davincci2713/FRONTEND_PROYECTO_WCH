import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_proyecto/config.dart';

class GeocodingService {
  static final GeocodingService _instance = GeocodingService._();
  factory GeocodingService() => _instance;
  GeocodingService._();

  Future<List<Map<String, dynamic>>> getStadiums() async {
    final resp = await http.get(
      Uri.parse('$kBaseUrl/stadiums'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> getCities() async {
    final resp = await http.get(
      Uri.parse('$kBaseUrl/cities'),
      headers: {'Content-Type': 'application/json'},
    );
    if (resp.statusCode == 200) {
      final List<dynamic> data = jsonDecode(resp.body);
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
