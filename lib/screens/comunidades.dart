import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/auth/auth.dart';

class ComunidadesScreen extends StatelessWidget {
  const ComunidadesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ComunidadesTab();
}

class ComunidadesTab extends StatefulWidget {
  const ComunidadesTab({super.key});
  @override
  State<ComunidadesTab> createState() => _ComunidadesTabState();
}

class _ComunidadesTabState extends State<ComunidadesTab> {
  final _svc = CommunityService();
  List<dynamic> _ranking = [];
  bool _loading = false;
  int get _userId => AuthService().currentUserId ?? 1;
  final int _activeCommunityId = 100;

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getRanking(_activeCommunityId);
      if (mounted) setState(() => _ranking = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreate() {
    final ctrl = TextEditingController();
    final maxMembersCtrl = TextEditingController();
    final favTeamCtrl = TextEditingController();
    final favPlayersCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text(
          'Crear comunidad',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: 'Nombre de la comunidad',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxMembersCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Máximo de miembros (Opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: favTeamCtrl,
                decoration: InputDecoration(
                  hintText: 'Equipo favorito (Opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: favPlayersCtrl,
                decoration: InputDecoration(
                  hintText: 'Jugadores favoritos (Opcional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final r = await _svc.createCommunity(
                  ctrl.text,
                  _userId,
                  maxMembers: int.tryParse(maxMembersCtrl.text),
                  favoriteTeam: favTeamCtrl.text.isEmpty ? null : favTeamCtrl.text,
                  favoritePlayers: favPlayersCtrl.text.isEmpty ? null : favPlayersCtrl.text,
                );
                if (!mounted) return;
                Navigator.pop(context);
                _showCode(r['invitationCode'].toString());
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00341C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Crear',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showJoin() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text(
          'Unirse con código',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: TextField(
          controller: ctrl,
          decoration: InputDecoration(
            hintText: 'Código',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _svc.joinCommunity(int.parse(ctrl.text), _userId);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('¡Te uniste!')));
                _fetchRanking();
              } catch (e) {
                if (mounted)
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00341C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: const Text(
              'Unirse',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showCode(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        title: const Text(
          'Comunidad creada',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Código de invitación:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Text(
              code,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF00341C),
            ),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mis comunidades',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: _showCreate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Crear',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00341C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showJoin,
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text(
                    'Unirme',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Text(
              'Ranking',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_ranking.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aún no hay participantes. Sé el primero.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade50),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  dataTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                  columns: const [
                    DataColumn(label: Text('#')),
                    DataColumn(label: Text('Usuario')),
                    DataColumn(label: Text('Pts')),
                  ],
                  rows: _ranking.asMap().entries.map((e) {
                    final pos = e.key + 1;
                    final item = e.value;
                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            '$pos',
                            style: TextStyle(
                              fontWeight: pos <= 3
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        DataCell(Text(item['name'] ?? '-')),
                        DataCell(
                          Text(
                            '${item['points'] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
