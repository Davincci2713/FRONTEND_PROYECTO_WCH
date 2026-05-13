import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

class DetallePollaScreen extends StatefulWidget {
  const DetallePollaScreen({super.key});

  @override
  State<DetallePollaScreen> createState() => _DetallePollaScreenState();
}

class _DetallePollaScreenState extends State<DetallePollaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceCard,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('POLLA: AMIGOS FC', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            Text('12 participantes', style: TextStyle(fontSize: 11, color: AppTheme.onSurfaceMuted)),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentYellow,
          labelColor: AppTheme.accentYellow,
          unselectedLabelColor: AppTheme.onSurfaceMuted,
          tabs: const [Tab(text: 'RANKING'), Tab(text: 'MIS PRONÓSTICOS')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRanking(),
          _buildMyPredictions(),
        ],
      ),
    );
  }

  Widget _buildRanking() {
    final ranking = [
      {'user': 'JuanK88', 'pts': '15', 'pos': '1'},
      {'user': 'Tu (Fanático)', 'pts': '12', 'pos': '2'},
      {'user': 'Maria_99', 'pts': '10', 'pos': '3'},
    ];
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ranking.length,
      itemBuilder: (context, i) {
        final r = ranking[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: r['pos'] == '1' ? AppTheme.accentYellow : AppTheme.surfaceElevated,
            child: Text(r['pos']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          title: Text(r['user']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          trailing: Text('${r['pts']} pts', style: const TextStyle(color: AppTheme.accentGreen, fontWeight: FontWeight.w900)),
        );
      },
    );
  }

  Widget _buildMyPredictions() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _predictionItem('COL', 'BRA', '2', '1'),
        _predictionItem('MEX', 'ARG', '0', '0'),
      ],
    );
  }

  Widget _predictionItem(String h, String a, String gh, String ga) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text(gh, style: const TextStyle(color: AppTheme.accentYellow, fontSize: 20, fontWeight: FontWeight.w900)),
          const Text('vs', style: TextStyle(color: AppTheme.onSurfaceMuted)),
          Text(ga, style: const TextStyle(color: AppTheme.accentYellow, fontSize: 20, fontWeight: FontWeight.w900)),
          Text(a, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}