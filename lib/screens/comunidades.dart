import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/auth/auth.dart';

// Pantalla independiente (usada en la navegación principal)
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Crear Comunidad'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Nombre')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final r = await _svc.createCommunity(ctrl.text, _userId);
                if (!mounted) return;
                Navigator.pop(context);
                _showCode(r['invitation_code'].toString());
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Crear'),
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
        title: const Text('Unirse con Código'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Código'), keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _svc.joinCommunity(int.parse(ctrl.text), _userId);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Te uniste!')));
                _fetchRanking();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  void _showCode(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¡Comunidad creada!'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Código de invitación:'),
          const SizedBox(height: 12),
          Text(code, style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 4)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mis Comunidades', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 16),
          Wrap(spacing: 12, runSpacing: 12, children: [
            ElevatedButton.icon(
              onPressed: _showCreate,
              icon: const Icon(Icons.add),
              label: const Text('Crear'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
            OutlinedButton.icon(
              onPressed: _showJoin,
              icon: const Icon(Icons.group_add),
              label: const Text('Unirme'),
            ),
          ]),
          const SizedBox(height: 28),
          Text('Ranking', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_ranking.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  const Text('Aún no hay participantes. ¡Sé el primero!',
                      textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ]),
              ),
            )
          else
            Card(
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(theme.colorScheme.primary.withOpacity(0.08)),
                columns: const [
                  DataColumn(label: Text('#')),
                  DataColumn(label: Text('Usuario')),
                  DataColumn(label: Text('Pts')),
                ],
                rows: _ranking.asMap().entries.map((e) {
                  final pos = e.key + 1;
                  final item = e.value;
                  final medal = pos == 1 ? '🥇' : pos == 2 ? '🥈' : pos == 3 ? '🥉' : '$pos';
                  return DataRow(cells: [
                    DataCell(Text(medal)),
                    DataCell(Text(item['name'] ?? '-')),
                    DataCell(Text('${item['points'] ?? 0}')),
                  ]);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
