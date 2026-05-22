import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:frontend_proyecto/config.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';
import 'package:frontend_proyecto/models/admin_models.dart';

class AdminService {
  final String baseUrl = kBaseUrl;

  Map<String, String> get _h => {
        'Content-Type': 'application/json',
        ...AuthService().getAuthHeaders(),
      };

  // GET /admin/reports/compliance
  Future<ComplianceReportModel> getComplianceReport() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/reports/compliance'), headers: _h);
    if (response.statusCode == 200) {
      return ComplianceReportModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Error al conectar con reportes de compliance');
  }

  // GET /users (O la ruta que uses para listar usuarios en el back)
  Future<List<AdminUserModel>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/users'), headers: _h);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AdminUserModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener lista de usuarios');
  }

  // GET /admin/users/<id>/timeline
  Future<List<AuditEventModel>> getUserTimeline(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/admin/users/$userId/timeline'), headers: _h);
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AuditEventModel.fromJson(e)).toList();
    }
    throw Exception('Error al obtener trazabilidad');
  }

  // POST /admin/users/<id>/block
  Future<void> blockUser(int userId) async {
    final response = await http.post(Uri.parse('$baseUrl/admin/users/$userId/block'), headers: _h);
    if (response.statusCode != 200) {
      throw Exception('No se pudo ejecutar el bloqueo');
    }
  }

  // PUT /admin/settings/datasource
  Future<void> updateDataSource(String source, String endpoint) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/settings/datasource'),
      headers: _h,
      body: jsonEncode({'source': source, 'endpoint': endpoint}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al actualizar orígenes de datos');
    }
  }
}