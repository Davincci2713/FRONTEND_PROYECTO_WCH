import 'dart:convert';

/// Mapea los datos del reporte de compliance del back
class ComplianceReportModel {
  final int activeUsers;
  final int fraudAlerts;
  final int ticketsSold;
  final String systemStatus;
  final Map<String, double> transactionHistory;

  ComplianceReportModel({
    required this.activeUsers,
    required this.fraudAlerts,
    required this.ticketsSold,
    required this.systemStatus,
    required this.transactionHistory,
  });

  factory ComplianceReportModel.fromJson(Map<String, dynamic> json) {
    final historyData = json['transaction_history'] as Map<String, dynamic>? ?? {};
    final Map<String, double> history = {};
    historyData.forEach((key, value) {
      history[key] = (value as num).toDouble();
    });

    return ComplianceReportModel(
      activeUsers: json['active_users'] ?? 0,
      fraudAlerts: json['fraud_alerts'] ?? 0,
      ticketsSold: json['tickets_sold'] ?? 0,
      systemStatus: json['system_status'] ?? 'OPERATIVO',
      transactionHistory: history,
    );
  }
}

/// Mapea el UserResponseDTO de tu back para la auditoría y control de roles
class AdminUserModel {
  final int userId;
  final String firstName;
  final String lastName;
  final String email;
  final int? roleId;
  final bool verified;
  final String? profilePicture;

  AdminUserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.roleId,
    required this.verified,
    this.profilePicture,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      userId: json['userId'] ?? 0,
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      roleId: json['roleId'],
      verified: json['verified'] ?? false,
      profilePicture: json['profilePicture'],
    );
  }

  String get fullName => '$firstName $lastName'.trim();
  String get roleName => roleId == 1 ? 'ADMINISTRADOR' : 'USUARIO HUB';
}

/// Mapea la línea de tiempo o logs de auditoría
class AuditEventModel {
  final String timestamp;
  final String action;
  final String detail;
  final bool isAlert;

  AuditEventModel({
    required this.timestamp,
    required this.action,
    required this.detail,
    required this.isAlert,
  });

  factory AuditEventModel.fromJson(Map<String, dynamic> json) {
    return AuditEventModel(
      timestamp: json['timestamp']?.toString() ?? 'AHORA',
      action: json['action'] ?? 'OPERACIÓN',
      detail: json['detail'] ?? '',
      isAlert: json['is_alert'] ?? false,
    );
  }
}