import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend_proyecto/utils/theme.dart';
import 'package:frontend_proyecto/models/admin_models.dart';
import 'package:frontend_proyecto/services/admin_service.dart';
import 'package:frontend_proyecto/services/auth/auth.dart';

class ExtendedColors {
  static const Color accentYellow = Color(0xFFFFDE4D);
  static const Color accentGreen = Color(0xFF4E9F3D);
  static const Color cardShadow = Color(0xFF000000);
}

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          toolbarHeight: 70,
          // 🚨 Esto bloquea la aparición de cualquier menú lateral o botón de retroceso
          automaticallyImplyLeading: false, 
          shape: Border(
            bottom: BorderSide(color: AppColors.border, width: 4),
          ),
          title: Text(
            'CENTRAL DE MANDO',
            style: GoogleFonts.spaceGrotesk(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 0.5,
            ),
          ),
          // 🚨 Botones exclusivos de Perfil y Cerrar Sesión
          actions: [
            TextButton.icon(
              onPressed: () => context.push('/profile'),
              icon: Icon(Icons.account_circle, color: AppColors.text),
              label: Text('PERFIL', style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.power_settings_new, color: AppColors.error),
              tooltip: 'Cerrar Sesión',
              onPressed: () async {
                await AuthService().logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 5,
            labelColor: AppColors.text,
            unselectedLabelColor: AppColors.textMuted,
            labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 13),
            tabs: const [
              Tab(text: 'MÉTRICAS'),
              Tab(text: 'USUARIOS'),
              Tab(text: 'AUDIT LOG'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DashboardTab(),
            _UserCrudTab(),
            _AuditLogTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PESTAÑA 1: DASHBOARD — Compliance Report
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardTab extends StatefulWidget {
  const _DashboardTab();

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  late Future<ComplianceReportModel> _future;

  @override
  void initState() {
    super.initState();
    _future = AdminService().getComplianceReport();
  }

  void _refresh() => setState(() {
        _future = AdminService().getComplianceReport();
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ComplianceReportModel>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final isMock = snapshot.hasError || !snapshot.hasData;
        final data = isMock
            ? ComplianceReportModel(
                totalUsers: 0,
                activeUsers: 0,
                totalTickets: 0,
                paidTickets: 0,
                reservedTickets: 0,
                totalRevenue: 0,
              )
            : snapshot.data!;

        return RefreshIndicator(
          color: AppColors.onPrimary,
          backgroundColor: AppColors.primary,
          onRefresh: () async => _refresh(),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (isMock) _buildNetworkAlert(errorMessage: snapshot.error?.toString()),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ESTADO GLOBAL DEL SISTEMA',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.text),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: AppColors.primary),
                    onPressed: _refresh,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: [
                  _buildMetricCard(
                    'USUARIOS TOTALES',
                    data.totalUsers.toString(),
                    'Registrados en la plataforma',
                    Colors.blueAccent,
                  ),
                  _buildMetricCard(
                    'INGRESOS TOTALES',
                    '\$${data.totalRevenue.toStringAsFixed(2)}',
                    'Ventas confirmadas',
                    ExtendedColors.accentGreen,
                  ),
                  _buildMetricCard(
                    'TIQUETES PAGADOS',
                    data.paidTickets.toString(),
                    'Asientos confirmados',
                    ExtendedColors.accentYellow,
                  ),
                  _buildMetricCard(
                    'RESERVAS ACTIVAS',
                    data.reservedTickets.toString(),
                    'Pendientes por pago',
                    AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Fila extra: usuarios activos vs totales
              _buildWideCard(
                'USUARIOS ACTIVOS',
                '${data.activeUsers} / ${data.totalUsers}',
                'Cuentas en estado activo',
                ExtendedColors.accentGreen,
              ),
              const SizedBox(height: 12),
              _buildWideCard(
                'TIQUETES EN SISTEMA',
                data.totalTickets.toString(),
                'Total emitidos (todos los estados)',
                Colors.blueAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [BoxShadow(color: ExtendedColors.cardShadow, offset: Offset(6, 6))],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: accent, border: Border.all(color: Colors.black, width: 1.5))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900, fontSize: 10, color: AppColors.textMuted)),
            ),
          ]),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.text)),
          Text(sub,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
        ],
      ),
    );
  }

  Widget _buildWideCard(String title, String value, String sub, Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 3),
        boxShadow: const [BoxShadow(color: ExtendedColors.cardShadow, offset: Offset(6, 6))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 4),
              Text(sub,
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 10, fontWeight: FontWeight.bold, color: accent)),
            ],
          ),
          Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900, fontSize: 26, color: AppColors.text)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PESTAÑA 2: CRUD USUARIOS
// ─────────────────────────────────────────────────────────────────────────────
class _UserCrudTab extends StatefulWidget {
  const _UserCrudTab();

  @override
  State<_UserCrudTab> createState() => _UserCrudTabState();
}

class _UserCrudTabState extends State<_UserCrudTab> {
  int _reloadKey = 0;

  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  int _selectedRoleId = 2;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _reload() => setState(() => _reloadKey++);

  void _openCreationDialog() {
    _firstNameController.clear();
    _lastNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _selectedRoleId = 2;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: AppColors.border, width: 4),
              ),
              titlePadding: EdgeInsets.zero,
              title: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: ExtendedColors.accentYellow,
                  border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
                ),
                child: Text(
                  'REGISTRAR NUEVO USUARIO',
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900, fontSize: 14, color: Colors.black),
                ),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputField(_firstNameController, 'Nombre(s)', Icons.person),
                      const SizedBox(height: 12),
                      _buildInputField(
                          _lastNameController, 'Apellido(s)', Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildInputField(_emailController, 'Correo Electrónico', Icons.email,
                          isEmail: true),
                      const SizedBox(height: 12),
                      _buildInputField(
                          _passwordController, 'Contraseña de Acceso', Icons.lock,
                          isPassword: true),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.border, width: 2.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: _selectedRoleId,
                            isExpanded: true,
                            dropdownColor: AppColors.surface,
                            style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.bold, color: AppColors.text),
                            items: const [
                              DropdownMenuItem(
                                  value: 2, child: Text('USUARIO REGULAR (Rol 2)')),
                              DropdownMenuItem(
                                  value: 1,
                                  child: Text('ADMINISTRADOR DEL SISTEMA (Rol 1)')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => _selectedRoleId = value);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('CANCELAR',
                      style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ExtendedColors.accentGreen,
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.black, width: 2),
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      await AdminService().createUser(
                        firstName: _firstNameController.text.trim(),
                        lastName: _lastNameController.text.trim(),
                        email: _emailController.text.trim(),
                        password: _passwordController.text,
                        roleId: _selectedRoleId,
                      );
                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Usuario creado exitosamente.')),
                      );
                      _reload(); 
                    } catch (e) {
                      if (!mounted) return;
                      Navigator.pop(dialogContext);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al crear usuario: $e')),
                      );
                    }
                  },
                  child: Text('CONSOLIDAR REGISTRO',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.spaceGrotesk(color: AppColors.textMuted, fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: AppColors.text),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.zero,
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 2),
          borderRadius: BorderRadius.zero,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 3),
          borderRadius: BorderRadius.zero,
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        if (isEmail && !value.contains('@')) return 'Escribe un correo válido';
        if (isPassword && value.length < 8) return 'Mínimo 8 caracteres';
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        label: Text('AÑADIR USUARIO',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
        icon: const Icon(Icons.person_add_alt_1),
        onPressed: _openCreationDialog,
      ),
      body: FutureBuilder<List<AdminUserModel>>(
        key: ValueKey(_reloadKey),
        future: AdminService().getAllUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final isMock = snapshot.hasError || !snapshot.hasData;
          final users = isMock ? <AdminUserModel>[] : snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: users.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return isMock ? _buildNetworkAlert(errorMessage: snapshot.error?.toString()) : const SizedBox.shrink();
              }
              final user = users[index - 1];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border, width: 3),
                  boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(5, 5))],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: _buildUserAvatar(user),
                  title: Text(
                    '${user.firstName.toUpperCase()} ${user.lastName.toUpperCase()}',
                    style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w900, color: AppColors.text),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(user.email,
                          style: GoogleFonts.spaceGrotesk(
                              color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        _buildBadge(
                          user.roleId == 1 ? 'ADMIN' : 'REGULAR',
                          user.roleId == 1 ? ExtendedColors.accentYellow : Colors.blueAccent,
                        ),
                        const SizedBox(width: 6),
                        _buildBadge(
                          user.accountStatus.toUpperCase(),
                          user.isActive ? ExtendedColors.accentGreen : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        if (user.verified)
                          _buildBadge('VERIFICADO', ExtendedColors.accentGreen)
                        else
                          _buildBadge('SIN VERIFICAR', AppColors.textMuted),
                      ]),
                    ],
                  ),
                  trailing: user.isActive
                      ? IconButton(
                          tooltip: 'Bloquear usuario',
                          icon: Icon(Icons.block, color: AppColors.error, size: 28),
                          onPressed: () async {
                            try {
                              await AdminService().blockUser(user.userId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${user.fullName} bloqueado correctamente.')),
                              );
                              _reload(); 
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al bloquear: $e')),
                              );
                            }
                          },
                        )
                      : Tooltip(
                          message: 'Cuenta bloqueada',
                          child: Icon(Icons.lock, color: AppColors.textMuted, size: 28),
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar(AdminUserModel user) {
    final pic = user.profilePicture;
    Widget imageChild;
    if (pic != null && pic.isNotEmpty) {
      if (pic.startsWith('data:image')) {
        try {
          final bytes = base64Decode(pic.split(',').last);
          imageChild = Image.memory(bytes, width: 48, height: 48, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _avatarFallback(user.roleId));
        } catch (_) {
          imageChild = _avatarFallback(user.roleId);
        }
      } else if (pic.startsWith('http')) {
        imageChild = Image.network(pic, width: 48, height: 48, fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _avatarFallback(user.roleId));
      } else {
        imageChild = _avatarFallback(user.roleId);
      }
    } else {
      imageChild = _avatarFallback(user.roleId);
    }
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: user.roleId == 1 ? ExtendedColors.accentYellow : AppColors.surfaceVariant,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: ClipRect(child: imageChild),
    );
  }

  Widget _avatarFallback(int roleId) => Center(
        child: Icon(roleId == 1 ? Icons.bolt : Icons.person,
            color: AppColors.text, size: 26),
      );

  Widget _buildBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: bg, border: Border.all(color: Colors.black, width: 1.5)),
      child: Text(text,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PESTAÑA 3: AUDIT LOG
// ─────────────────────────────────────────────────────────────────────────────
class _AuditLogTab extends StatefulWidget {
  const _AuditLogTab();

  @override
  State<_AuditLogTab> createState() => _AuditLogTabState();
}

class _AuditLogTabState extends State<_AuditLogTab> {
  final _userIdController = TextEditingController();
  late Future<List<AuditEventModel>> _future;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  void _fetch() {
    final id = int.tryParse(_userIdController.text.trim());
    setState(() {
      _future = AdminService().getAuditLog(userId: id);
    });
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _userIdController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold, color: AppColors.text),
                  decoration: InputDecoration(
                    labelText: 'USER ID (vacío = todos)',
                    labelStyle: GoogleFonts.spaceGrotesk(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.manage_search, color: AppColors.text),
                    filled: true,
                    fillColor: AppColors.background,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.border, width: 2),
                      borderRadius: BorderRadius.zero,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppColors.primary, width: 3),
                      borderRadius: BorderRadius.zero,
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  onFieldSubmitted: (_) => _fetch(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                onPressed: _fetch,
                icon: const Icon(Icons.search, size: 20),
                label: Text('BUSCAR',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<AuditEventModel>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final isMock = snapshot.hasError || !snapshot.hasData;
              final logs = isMock ? <AuditEventModel>[] : snapshot.data!;

              if (isMock) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [_buildNetworkAlert(errorMessage: snapshot.error?.toString())],
                );
              }

              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: Icon(Icons.search_off,
                            size: 32, color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 16),
                      Text('SIN EVENTOS REGISTRADOS',
                          style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w900,
                              color: AppColors.textMuted,
                              letterSpacing: 1)),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                color: AppColors.onPrimary,
                backgroundColor: AppColors.primary,
                onRefresh: () async => _fetch(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: logs.length,
                  itemBuilder: (context, idx) {
                    final log = logs[idx];
                    final isSuccess = log.result.toUpperCase() == 'SUCCESS';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border, width: 2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black, offset: Offset(4, 4))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  log.action.toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.primary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isSuccess
                                      ? ExtendedColors.accentGreen
                                      : AppColors.error,
                                  border:
                                      Border.all(color: Colors.black, width: 1.5),
                                ),
                                child: Text(
                                  log.result.toUpperCase(),
                                  style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: AppColors.border, thickness: 1.5, height: 15),
                          _logRow('ENTIDAD', log.affectedEntity),
                          const SizedBox(height: 4),
                          _logRow('CORRELACIÓN', log.correlationId),
                          const SizedBox(height: 4),
                          _logRow(
                            'FECHA',
                            '${log.createdAt.day.toString().padLeft(2, '0')}/'
                                '${log.createdAt.month.toString().padLeft(2, '0')}/'
                                '${log.createdAt.year}  '
                                '${log.createdAt.hour.toString().padLeft(2, '0')}:'
                                '${log.createdAt.minute.toString().padLeft(2, '0')}',
                          ),
                          const SizedBox(height: 8),

                          // 🚨 AQUÍ ESTÁ EL DECODIFICADOR DEL JSON QUE ME PEDISTE
                          Builder(builder: (context) {
                            Map<String, dynamic> payloadData = {};
                            try {
                              if (log.payload.isNotEmpty) {
                                payloadData = jsonDecode(log.payload);
                              }
                            } catch (_) {}

                            final eventType = payloadData['event'] ?? '';

                            if (eventType == 'sports_bet_placed') {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('DETALLES DE LA APUESTA:',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    color: const Color(0xFF1A1A1A),
                                    child: Text(
                                      '🎰 ID Apuesta: ${payloadData['bet_id']} | Stake: \$${payloadData['stake']} | Cuota: ${payloadData['odds']}\n👤 Target User ID: ${payloadData['user_id']}',
                                      style: GoogleFonts.sourceCodePro(
                                          color: Colors.greenAccent, fontSize: 11),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('PAYLOAD RAW:',
                                      style: GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          color: AppColors.textMuted,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    color: const Color(0xFF1A1A1A),
                                    child: Text(
                                      log.payload,
                                      style: GoogleFonts.sourceCodePro(
                                          color: Colors.greenAccent, fontSize: 11),
                                    ),
                                  ),
                                ],
                              );
                            }
                          }),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _logRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted)),
        Expanded(
          child: Text(value,
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.text)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Banner reutilizable de advertencia de red (Ahora imprime el error)
// ─────────────────────────────────────────────────────────────────────────────
Widget _buildNetworkAlert({String? errorMessage}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 15),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: ExtendedColors.accentYellow,
      border: Border.all(color: Colors.black, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(4, 4))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning_amber_rounded, size: 22, color: Colors.black),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'NO SE PUDO OBTENER DATOS DEL BACKEND.',
                style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900, fontSize: 11, color: Colors.black),
              ),
            ),
          ],
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            'Error: $errorMessage',
            style: GoogleFonts.sourceCodePro(
                fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
          ),
        ],
      ],
    ),
  );
}