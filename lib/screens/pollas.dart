import 'package:flutter/material.dart';
import '../services/community_service.dart';
import '../services/auth/auth.dart';

class PollasScreen extends StatefulWidget {
  const PollasScreen({super.key});

  @override
  State<PollasScreen> createState() => _PollasScreenState();
}

class _PollasScreenState extends State<PollasScreen> {
  final CommunityService _communityService = CommunityService();
  List<dynamic> _ranking = [];
  bool _isLoading = false;
  
  int get _currentUserId => AuthService().currentUserId ?? 1; // Fallback solo de seguridad
  final int _activeCommunityId = 100; // Esto luego puede venir de un listado

  @override
  void initState() {
    super.initState();
    _fetchRanking();
  }

  Future<void> _fetchRanking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _communityService.getRanking(_activeCommunityId);
      setState(() => _ranking = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar ranking: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateCommunityDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Nueva Comunidad'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'Nombre de la comunidad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                final result = await _communityService.createCommunity(nameController.text, _currentUserId);
                Navigator.pop(context);
                _showCommunityCreatedDialog(result['invitation_code'].toString());
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showJoinCommunityDialog() {
    final TextEditingController codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a Comunidad'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(hintText: 'Código de invitación'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _communityService.joinCommunity(int.parse(codeController.text), _currentUserId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Te has unido con éxito!')));
                _fetchRanking();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  void _showCommunityCreatedDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comunidad Creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comparte este código con tus amigos:'),
            const SizedBox(height: 16),
            Text(code, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 48, bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mis Comunidades', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 32),
            Text('Ranking de la Comunidad', style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _buildRankingTable(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchRanking,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        ElevatedButton.icon(
          onPressed: _showCreateCommunityDialog,
          icon: const Icon(Icons.add),
          label: const Text('Crear Comunidad'),
        ),
        ElevatedButton.icon(
          onPressed: _showJoinCommunityDialog,
          icon: const Icon(Icons.group_add),
          label: const Text('Unirse con Código'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.white),
        ),
      ],
    );
  }

  Widget _buildRankingTable(BuildContext context) {
    if (_ranking.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No hay datos de ranking disponibles aún. Comienza a realizar pronósticos.'),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Pos')),
          DataColumn(label: Text('Usuario')),
          DataColumn(label: Text('Puntos')),
        ],
        rows: _ranking.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          return DataRow(
            cells: [
              DataCell(Text('${idx + 1}')),
              DataCell(Text(item['name'])),
              DataCell(Text('${item['points']}')),
            ],
          );
        }).toList(),
      ),
    );
  }
}
