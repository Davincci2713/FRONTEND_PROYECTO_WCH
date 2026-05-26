import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_proyecto/config.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/models/admin_models.dart';

class AdminService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        ...AuthService().getAuthHeaders(),
      };

  // ── GET /users ─────────────────────────────────────────────────────────────
  // Retorna la lista completa de usuarios (solo admin, role 1).
  // El backend espera JWT con rol 1 en el header Authorization.
  Future<List<AdminUserModel>> getAllUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AdminUserModel.fromJson(e)).toList();
    }
    throw Exception(
        'Error al recuperar listado de usuarios [${response.statusCode}]: ${response.body}');
  }

  // ── POST /users ────────────────────────────────────────────────────────────
  // Crea un usuario nuevo. Recibe los campos explícitamente para no depender
  // de AdminUserModel.toJson() que no tiene acceso a la contraseña en texto plano.
  //
  // Body esperado por UserCreateDTO del backend:
  //   { firstName, lastName, email, password, roleId }
  Future<AdminUserModel> createUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required int roleId,
  }) async {
    final body = jsonEncode({
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,     // contraseña real capturada del formulario
      'roleId': roleId,
    });

    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: _headers,
      body: body,
    );

    if (response.statusCode == 201) {
      return AdminUserModel.fromJson(jsonDecode(response.body));
    }

    // El backend devuelve { error, details } en caso de ValidationError
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final message = decoded['message'] ?? decoded['error'] ?? 'Error desconocido';
    throw Exception('Fallo en la creación del usuario: $message [${response.statusCode}]');
  }

  // ── POST /admin/users/:id/block ────────────────────────────────────────────
  // Bloquea un usuario. El backend actualiza accountStatus → 'bloqueado'
  // y registra el evento en audit_log.
  Future<void> blockUser(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/users/$userId/block'),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final message = decoded['message'] ?? decoded['error'] ?? 'Error desconocido';
      throw Exception(
          'Error al bloquear usuario $userId: $message [${response.statusCode}]');
    }
  }

  // ── GET /admin/users/:id/timeline ─────────────────────────────────────────
  Future<List<AuditEventModel>> getUserTimeline(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId/timeline'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuditEventModel.fromJson(e)).toList();
    }
    if (response.statusCode == 404) return [];
    throw Exception(
        'Error al obtener timeline del usuario $userId [${response.statusCode}]');
  }

  // ── GET /admin/audit-log?user_id=&limit= ──────────────────────────────────
  // Devuelve eventos del audit log. user_id es opcional; sin él retorna los
  // últimos eventos globales.
  Future<List<AuditEventModel>> getAuditLog({int? userId, int limit = 100}) async {
    final queryParams = <String, String>{'limit': limit.toString()};
    if (userId != null) queryParams['user_id'] = userId.toString();
    final uri = Uri.parse('$baseUrl/admin/audit-log').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuditEventModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener audit log [${response.statusCode}]');
  }

  // ── GET /admin/reports/compliance ─────────────────────────────────────────
  // Reporte global: usuarios, tickets, ingresos.
  // No tiene fallback silencioso — la UI lo maneja con el banner de advertencia.
  Future<ComplianceReportModel> getComplianceReport() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/reports/compliance'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return ComplianceReportModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(
        'Error al obtener reporte de compliance [${response.statusCode}]');
  }
}