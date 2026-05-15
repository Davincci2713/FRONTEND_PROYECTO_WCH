import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const _kToken    = 'auth_token';
const _kUser     = 'auth_user';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final String baseUrl = "http://localhost:5001/api/v1";

  String? _accessToken;
  Map<String, dynamic>? _currentUser;

  bool get isAuthenticated => _accessToken != null;
  int?  get currentUserId  => _currentUser?['userId'];
  Map<String, dynamic>? get currentUser => _currentUser;

  // ------------------------------------------------------------------
  // Persistence
  // ------------------------------------------------------------------

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kToken);
    final userJson = prefs.getString(_kUser);
    if (token != null && userJson != null) {
      _accessToken  = token;
      _currentUser  = jsonDecode(userJson) as Map<String, dynamic>;
      notifyListeners();
    }
  }

  Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    _accessToken = token;
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUser, jsonEncode(user));
    notifyListeners();
  }

  Future<void> _clearSession() async {
    _accessToken = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUser);
    notifyListeners();
  }

  // ------------------------------------------------------------------
  // Auth
  // ------------------------------------------------------------------

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveSession(data['token'] as String, data['user'] as Map<String, dynamic>);
        return {'success': true, 'token': _accessToken, 'user': _currentUser};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'errorCode': error['error'],
          'message': error['message'] ?? 'Credenciales inválidas',
          'email': error['email'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<Map<String, dynamic>> register(
      String firstName, String lastName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
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
        body: jsonEncode({'email': email, 'code': code}),
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

  Future<Map<String, dynamic>> resendVerificationCode(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Error al reenviar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  Future<void> logout() async {
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('$baseUrl/auth/logout'),
          headers: getAuthHeaders(),
        );
      } catch (_) {}
    }
    await _clearSession();
  }

  // ------------------------------------------------------------------
  // FCM token registration
  // ------------------------------------------------------------------

  Future<void> registerFcmToken(String fcmToken) async {
    final uid = currentUserId;
    if (uid == null) return;
    try {
      await http.post(
        Uri.parse('$baseUrl/users/$uid/fcm-token'),
        headers: getAuthHeaders(),
        body: jsonEncode({'token': fcmToken}),
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------------
  // Profile Picture
  // ------------------------------------------------------------------

  Future<Map<String, dynamic>> updateProfilePicture(String base64Image) async {
    final uid = currentUserId;
    if (uid == null) return {'success': false, 'message': 'No autorizado'};
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$uid/profile-picture'),
        headers: getAuthHeaders(),
        body: jsonEncode({'profilePicture': base64Image}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (_currentUser != null) {
          _currentUser!['profilePicture'] = data['profilePicture'];
          await _saveSession(_accessToken!, _currentUser!);
        }
        return {'success': true, 'message': 'Foto actualizada'};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Error al actualizar'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión'};
    }
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Map<String, String> getAuthHeaders() => {
    'Content-Type': 'application/json',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };
}
