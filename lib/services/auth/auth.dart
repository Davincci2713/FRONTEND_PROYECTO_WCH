import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl = "http://localhost:5001/api/v1";

  String? _accessToken;
  Map<String, dynamic>? _currentUser;

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['token'];
        _currentUser = data['user'];
        return {
          'success': true,
          'token': _accessToken,
          'user': _currentUser,
        };
      } else {
        final error = jsonDecode(response.body);
        return {'success': false, 'message': error['message'] ?? 'Credenciales inválidas'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> register(String firstName, String lastName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al registrar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al verificar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
  }

  bool get isAuthenticated => _accessToken != null;
  int? get currentUserId => _currentUser?['userId'];
  Map<String, dynamic>? get currentUser => _currentUser;

  void logout() {
    _accessToken = null;
    _currentUser = null;
  }
}