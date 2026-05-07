class AuthService {
  String? _accessToken;

  static const String _adminEmail = 'admin@mundial.com';
  static const String _adminPass = 'admin123';

  Future<Map<String, dynamic>> login(String email, String password) async {

    if (email == _adminEmail && password == _adminPass) {
      _accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...admin_token";
      return {
        'success': true,
        'token': _accessToken,
        'role': 'admin'
      };
    } else if (email.contains('@') && password.length >= 6) {
      _accessToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...user_token";
      return {
        'success': true,
        'token': _accessToken,
        'role': 'user'
      };
    }
    
    return {'success': false, 'message': 'Credenciales inválidas'};
  }


  Map<String, String> getAuthHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_accessToken',
    };
  }

  bool get isAuthenticated => _accessToken != null;

  void logout() {
    _accessToken = null;
  }
}