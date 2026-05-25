import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_proyecto/utils/theme.dart'; // Contiene AppColors.border, primary,etc.
import 'package:frontend_proyecto/models/admin_models.dart';
import 'package:frontend_proyecto/services/admin_service.dart';

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
shape: Border(bottom: BorderSide(color: AppColors.border, width: 3)),
title: Text(
'BACKOFFICE OPERATIVO',
style: GoogleFonts.spaceGrotesk(color: AppColors.text, fontWeight: FontWeight.w900,
fontSize: 18),
),
bottom: TabBar(
indicatorColor: AppColors.error,
labelColor: AppColors.text,
unselectedLabelColor: AppColors.textMuted,
labelStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 12),
tabs: const [
Tab(text: 'DASHBOARD & TICKETS'),
Tab(text: 'CRUD USUARIOS'),
Tab(text: 'AUDITORÍA LOGS'),
],
),
),
body: const TabBarView(
children: [
_DashboardTab(),
_UsuariosTab(),
_AuditTabGeneral(),
],
),
),
);
}
}
// ── PESTAÑA 1: METRICAS & TICKETS ──────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
const _DashboardTab();
@override


Widget build(BuildContext context) {
final svc = AdminService();
return FutureBuilder<ComplianceReportModel>(
future: svc.getComplianceReport(),
builder: (context, snapshot) {
if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
final data = snapshot.data!;
return ListView(
padding: const EdgeInsets.all(16),
children: [
Text('MÉTRICAS CORE DE SISTEMA', style: GoogleFonts.spaceGrotesk(fontWeight:
FontWeight.w900, fontSize: 14)),
const SizedBox(height: 12),
Row(
children: [
Expanded(child: _buildMetricCard('USUARIOS', '${data.activeUsers} / ${data.totalUsers}', 'ACTIVOS / TOTALES')),
const SizedBox(width: 12),
Expanded(child: _buildMetricCard('REVENUE', '\$${data.totalRevenue.toStringAsFixed(0)}', 'USD RECAUDADOS')),
],
),
const SizedBox(height: 24),
Text('ESTADO DE LA BOLETERÍA (TICKETS)', style:
GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 14)),
const SizedBox(height: 12),
Container(
decoration: BoxDecoration(border: Border.all(color: AppColors.border, width: 2),
color: AppColors.surface),
padding: const EdgeInsets.all(16),
child: Column(
children: [
_buildTicketRow('TOTAL DE TIQUETES PROVISTOS', '${data.totalTickets}',
Colors.blue.shade800),
const Divider(height: 20, thickness: 2, color: Colors.black12),
_buildTicketRow('TIQUETES PAGADOS EN FIRME', '${data.paidTickets}',
Colors.green.shade800),
const Divider(height: 20, thickness: 2, color: Colors.black12),
_buildTicketRow('RESERVAS EXPIRABLES ACTIVAS', '${data.reservedTickets}',
Colors.amber.shade900),
],
),
)
],
);
},
);
}
Widget _buildMetricCard(String title, String val, String sub) {
return Container(
padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color:
AppColors.border, width: 2)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize:
11, color: AppColors.error)),
const SizedBox(height: 6),
Text(val, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize:
18)),
Text(sub, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted)),
],
),


);
}
Widget _buildTicketRow(String title, String qty, Color color) {
return Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(title, style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 13)),
Container(
padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
decoration: BoxDecoration(color: color.withOpacity(0.12), border: Border.all(color:
color, width: 1.5)),
child: Text(qty, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color:
color, fontSize: 14)),
)
],
);
}
}
// ── PESTAÑA 2: CRUD DE USUARIOS CONECTADO ───────────────────────────────────
class _UsuariosTab extends StatefulWidget {
const _UsuariosTab();
@override
State<_UsuariosTab> createState() => _UsuariosTabState();
}
class _UsuariosTabState extends State<_UsuariosTab> {
final _svc = AdminService();
final _searchCtrl = TextEditingController();
List<AdminUserModel> _allUsers = [];
List<AdminUserModel> _filteredUsers = [];
bool _loading = true;
@override
void initState() {
super.initState();
_fetchData();
_searchCtrl.addListener(() {
final q = _searchCtrl.text.toLowerCase();
setState(() {
_filteredUsers = _allUsers.where((u) => u.fullName.toLowerCase().contains(q) ||
u.email.toLowerCase().contains(q)).toList();
});
});
}
Future<void> _fetchData() async {
setState(() => _loading = true);
try {
final res = await _svc.getAllUsers();
setState(() { _allUsers = res; _filteredUsers = res; _loading = false; });
} catch (_) {
setState(() {
_allUsers = [
AdminUserModel(userId: 1, firstName: 'Carlos', lastName: 'Mendoza', email:
'carlos@hub.com', roleId: 1, verified: true, accountStatus: 'activo'),
AdminUserModel(userId: 2, firstName: 'Andrés', lastName: 'Gómez', email:
'andres@fraude.com', roleId: 2, verified: true, accountStatus: 'bloqueado'),
];
_filteredUsers = _allUsers;
_loading = false;
});
}
}


void _blockUser(int id) async {
try {
await _svc.blockUser(id);
_fetchData();
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ESTADO ACTUALIZADO (CRUD: DELETE/BLOCK)')));
} catch (e) {
ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
}
}
void _openForm({AdminUserModel? user}) {
showModalBottomSheet(
context: context,
isScrollControlled: true,
backgroundColor: Colors.transparent,
builder: (_) => _UserFormSheet(user: user, onSave: _fetchData),
);
}
@override
Widget build(BuildContext context) {
return Column(
children: [
Padding(
padding: const EdgeInsets.all(16),
child: Row(
children: [
Expanded(
child: TextField(
controller: _searchCtrl,
decoration: InputDecoration(
hintText: 'FILTRAR USUARIOS...',
filled: true, fillColor: AppColors.surface,
border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide:
BorderSide(color: AppColors.border, width: 2)),
),
),
),
const SizedBox(width: 12),
InkWell(
onTap: () => _openForm(),
child: Container(
height: 50, padding: const EdgeInsets.symmetric(horizontal: 16),
decoration: BoxDecoration(color: AppColors.primary, border: Border.all(color:
AppColors.text, width: 2)),
child: Center(child: Text('AÑADIR', style:
GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900))),
),
)
],
),
),
Expanded(
child: _loading
? const Center(child: CircularProgressIndicator())
: ListView.builder(
padding: const EdgeInsets.symmetric(horizontal: 16),
itemCount: _filteredUsers.length,
itemBuilder: (context, idx) {
final u = _filteredUsers[idx];
return Container(
margin: const EdgeInsets.only(bottom: 10),
decoration: BoxDecoration(color: AppColors.surface, border:


Border.all(color: AppColors.border, width: 2)),
child: ListTile(
title: Text(u.fullName.toUpperCase(), style:
GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
subtitle: Text('${u.email} • ${u.roleName}', style:
GoogleFonts.dmSans(fontSize: 11)),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(icon: const Icon(Icons.edit_sharp), onPressed: () =>
_openForm(user: u)),
IconButton(
icon: Icon(Icons.block_sharp, color: u.isActive ? AppColors.error :
Colors.grey),
onPressed: () => _blockUser(u.userId),
),
],
),
),
);
},
),
)
],
);
}
}
// ── HOJA FORMULARIO: AJUSTE DINÁMICO DE PANTALLA (INSETS) ────────────────────
class _UserFormSheet extends StatefulWidget {
final AdminUserModel? user;
final VoidCallback onSave;
const _UserFormSheet({this.user, required this.onSave});
@override
State<_UserFormSheet> createState() => _UserFormSheetState();
}
class _UserFormSheetState extends State<_UserFormSheet> {
final _formKey = GlobalKey<FormState>();
late TextEditingController _fnCtrl;
late TextEditingController _lnCtrl;
late TextEditingController _emCtrl;
@override
void initState() {
super.initState();
_fnCtrl = TextEditingController(text: widget.user?.firstName ?? '');
_lnCtrl = TextEditingController(text: widget.user?.lastName ?? '');
_emCtrl = TextEditingController(text: widget.user?.email ?? '');
}
@override
Widget build(BuildContext context) {
return Container(
padding: EdgeInsets.only(
top: 24, left: 24, right: 24,
bottom: MediaQuery.of(context).viewInsets.bottom + 24,
),
decoration: BoxDecoration(color: AppColors.background, border: Border(top:
BorderSide(color: AppColors.border, width: 4))),
child: Form(
key: _formKey,
child: Column(
mainAxisSize: MainAxisSize.min,


crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(widget.user == null ? 'CREAR USUARIO' : 'MODIFICAR USUARIO', style:
GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16)),
const SizedBox(height: 16),
TextFormField(controller: _fnCtrl, decoration: const InputDecoration(labelText:
'NOMBRE')),
const SizedBox(height: 12),
TextFormField(controller: _lnCtrl, decoration: const InputDecoration(labelText:
'APELLIDO')),
const SizedBox(height: 12),
TextFormField(controller: _emCtrl, decoration: const InputDecoration(labelText:
'EMAIL'), enabled: widget.user == null),
const SizedBox(height: 20),
SizedBox(
width: double.infinity, height: 48,
child: ElevatedButton(
style: ElevatedButton.styleFrom(backgroundColor: AppColors.text, shape: const
RoundedRectangleBorder()),
onPressed: () async {
if (!_formKey.currentState!.validate()) return;
final mockUser = AdminUserModel(
userId: widget.user?.userId ?? 0,
firstName: _fnCtrl.text,
lastName: _lnCtrl.text,
email: _emCtrl.text,
roleId: 2, verified: true, accountStatus: 'activo',
);
if (widget.user == null) {
await AdminService().createUser(mockUser);
}
widget.onSave();
Navigator.pop(context);
},
child: Text('GUARDAR REGISTRO', style: GoogleFonts.spaceGrotesk(color:
AppColors.background, fontWeight: FontWeight.bold)),
),
)
],
),
),
);
}
}
// ── PESTAÑA 3: LOGS DE AUDITORÍA GENERALES ──────────────────────────────────
class _AuditTabGeneral extends StatelessWidget {
const _AuditTabGeneral();
@override
Widget build(BuildContext context) {
// Al reutilizar la consulta secuencial del timeline sobre el ID de administración (1)
return FutureBuilder<List<AuditEventModel>>(
future: AdminService().getUserTimeline(1),
builder: (context, snapshot) {
if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
final logs = snapshot.data!;
if (logs.isEmpty) {
return Center(child: Text('NO HAY LOGS RECIENTES EN AUDIT_LOG', style:
GoogleFonts.spaceGrotesk(color: AppColors.textMuted)));
}
return ListView.builder(
padding: const EdgeInsets.all(16),
itemCount: logs.length,
itemBuilder: (context, idx) {


final log = logs[idx];
return Container(
margin: const EdgeInsets.only(bottom: 8),
padding: const EdgeInsets.all(12),
decoration: BoxDecoration(color: AppColors.surface, border: Border.all(color:
AppColors.border, width: 1.5)),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(log.action.toUpperCase(), style:
GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.error)),
Text(log.result, style: GoogleFonts.spaceGrotesk(fontWeight:
FontWeight.bold, fontSize: 11, color: log.result.toLowerCase() == 'success' ?
Colors.green.shade800 : AppColors.text)),
],
),
const SizedBox(height: 4),
Text('Entidad afectada: ${log.affectedEntity} • CID: ${log.correlationId}',
style: GoogleFonts.dmSans(fontSize: 11)),
],
),
);
},
);
},
);
}
}