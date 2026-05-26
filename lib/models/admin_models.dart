
import 'dart:convert';
class AdminUserModel {
final int userId;
final String firstName;

final String lastName;
final String email;
final int roleId;
final bool verified;
final String accountStatus;
AdminUserModel({
required this.userId,
required this.firstName,
required this.lastName,
required this.email,
required this.roleId,
required this.verified,
required this.accountStatus,
});
String get fullName => '$firstName $lastName';
String get roleName => roleId == 1 ? 'ADMINISTRADOR NÚCLEO' : 'OPERADOR BACKOFFICE';
bool get isActive => accountStatus.toLowerCase() == 'activo';
factory AdminUserModel.fromJson(Map<String, dynamic> json) {
return AdminUserModel(
userId: json['userId'] ?? json['idUser'] ?? 0,
firstName: json['firstName'] ?? json['firstname'] ?? '',
lastName: json['lastName'] ?? json['lastname'] ?? '',
email: json['email'] ?? '',
roleId: json['roleId'] ?? json['idRole'] ?? 2,
verified: json['verified'] ?? false,
accountStatus: json['accountStatus'] ?? json['accountstatus'] ?? 'activo',
);
}
Map<String, dynamic> toJson() {
return {
'password': 'PasswordProvisional123*', // Requerido por UserCreateDTO
'firstName': firstName,
'lastName': lastName,
'email': email,
'roleId': roleId,
};
}
}
class ComplianceReportModel {
final int totalUsers;
final int activeUsers;
final int totalTickets;
final int paidTickets;
final int reservedTickets;
final double totalRevenue;
ComplianceReportModel({
required this.totalUsers,
required this.activeUsers,
required this.totalTickets,
required this.paidTickets,
required this.reservedTickets,
required this.totalRevenue,
});
factory ComplianceReportModel.fromJson(Map<String, dynamic> json) {
return ComplianceReportModel(
totalUsers: json['total_users'] ?? 0,
activeUsers: json['active_users'] ?? 0,
totalTickets: json['total_tickets'] ?? 0,
paidTickets: json['paid_tickets'] ?? 0,
reservedTickets: json['reserved_tickets'] ?? 0,
totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
);
}
}

class AuditEventModel {
  final int idAudit;
  final String correlationId;
  final DateTime createdAt;
  final String payload;
  final String affectedEntity;
  final String action;
  final String result;

  AuditEventModel({
    required this.idAudit,
    required this.correlationId,
    required this.createdAt,
    required this.payload,
    required this.affectedEntity,
    required this.action,
    required this.result,
  });

  Map<String, dynamic> get decodedPayload {
    try {
      if (payload.isEmpty) return {};
      return jsonDecode(payload);
    } catch (_) {
      return {};
    }
  }

  int? get embeddedUserId {
    final map = decodedPayload;
    return map['user_id'] ?? map['userId'];
  }

  String get eventName {
    final map = decodedPayload;
    return map['event'] ?? action;
  }

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      idAudit: json['idAudit'] ?? json['id_audit'] ?? 0,
      correlationId: json['correlationId'] ?? json['correlation_id'] ?? '',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : (json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now()),
      payload: json['payload'] ?? '',
      affectedEntity: json['affectedEntity'] ?? json['affected_entity'] ?? '',
      action: json['action'] ?? '',
      result: json['result'] ?? '',
    );
  }
}