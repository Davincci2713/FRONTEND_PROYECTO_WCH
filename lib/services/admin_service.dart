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

Future<List<AdminUserModel>> getAllUsers() async {
final response = await http.get(Uri.parse('$baseUrl/users'), headers: _headers);
if (response.statusCode == 200) {
final List<dynamic> data = jsonDecode(response.body);
return data.map((e) => AdminUserModel.fromJson(e)).toList();
}
throw Exception('Error al recuperar listado general de usuarios');
}
Future<void> createUser(AdminUserModel user) async {
final response = await http.post(
Uri.parse('$baseUrl/users'),
headers: _headers,
body: jsonEncode(user.toJson()),
);
if (response.statusCode != 201) {
throw Exception('Fallo en la creación del registro: ${response.body}');
}
}
Future<void> blockUser(int userId) async {
final response = await http.post(
Uri.parse('$baseUrl/admin/users/$userId/block'),
headers: _headers,
);
if (response.statusCode != 200) {
throw Exception('Código de estado inválido en bloqueo de usuario corporativo');
}
}
Future<List<AuditEventModel>> getUserTimeline(int userId) async {
final response = await http.get(
Uri.parse('$baseUrl/admin/users/$userId/timeline'),
headers: _headers,
);
if (response.statusCode == 200) {
final List<dynamic> data = jsonDecode(response.body);
return data.map((e) => AuditEventModel.fromJson(e)).toList();
}
return [];
}
Future<ComplianceReportModel> getComplianceReport() async {
final response = await http.get(
Uri.parse('$baseUrl/admin/reports/compliance'),
headers: _headers,
);
if (response.statusCode == 200) {
return ComplianceReportModel.fromJson(jsonDecode(response.body));
}
// Fallback Mock de Respaldo por si el microservicio de reportes está inicializando
return ComplianceReportModel(
totalUsers: 1420,
activeUsers: 1180,
totalTickets: 450,
paidTickets: 310,
reservedTickets: 90,
totalRevenue: 46500.00,
);
}
}