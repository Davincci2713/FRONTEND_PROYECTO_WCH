import 'package:flutter/material.dart';
import '../services/match_service.dart';
import '../services/bet_service.dart';
import '../services/auth/auth.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final MatchService _matchService = MatchService();
  final BetService _betService = BetService();
  List<dynamic> _matches = [];
  bool _isLoading = false;

  int get _currentUserId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _fetchMatches();
  }

  Future<void> _fetchMatches() async {
    setState(() => _isLoading = true);
    try {
      final data = await _matchService.getAllMatches();
      setState(() => _matches = data);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showPredictionDialog(dynamic match) {
    final TextEditingController homeController = TextEditingController();
    final TextEditingController awayController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pronóstico: ${match['homeTeamName'] ?? 'Equipo A'} vs ${match['awayTeamName'] ?? 'Equipo B'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: TextField(controller: homeController, decoration: const InputDecoration(labelText: 'Goles Local'), keyboardType: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: awayController, decoration: const InputDecoration(labelText: 'Goles Visitante'), keyboardType: TextInputType.number)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _betService.submitBet(
                  match['matchId'],
                  _currentUserId,
                  int.parse(homeController.text),
                  int.parse(awayController.text),
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pronóstico enviado con éxito')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendario de Partidos')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchMatches,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final m = _matches[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text('${m['homeTeamName'] ?? 'Local'} vs ${m['awayTeamName'] ?? 'Visitante'}'),
                      subtitle: Text('Fecha: ${m['scheduledAt']} - Fase: ${m['phase']}'),
                      trailing: ElevatedButton(
                        onPressed: () => _showPredictionDialog(m),
                        child: const Text('APOSTAR'),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
