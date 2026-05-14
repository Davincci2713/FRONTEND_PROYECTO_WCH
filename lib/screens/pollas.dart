import 'package:flutter/material.dart';
import '../services/betting_service.dart';
import '../services/auth/auth.dart';

// ── Modelo local ─────────────────────────────────────────────────────────────
class _BetSelection {
  final dynamic matchId;
  final String homeName, awayName, betType, betLabel;
  final double odds;
  _BetSelection({
    required this.matchId, required this.homeName, required this.awayName,
    required this.betType, required this.betLabel, required this.odds,
  });
}

// ── Pantalla de apuestas ──────────────────────────────────────────────────────
class PollasScreen extends StatelessWidget {
  const PollasScreen({super.key});

  @override
  Widget build(BuildContext context) => const _BettingTab();
}

// ── Tab de apuestas ───────────────────────────────────────────────────────────
class _BettingTab extends StatefulWidget {
  const _BettingTab();
  @override
  State<_BettingTab> createState() => _BettingTabState();
}

class _BettingTabState extends State<_BettingTab> {
  final _svc = BettingService();
  List<dynamic> _matches = [];
  List<dynamic> _myBets  = [];
  bool _loading = true;
  final List<_BetSelection> _slip = [];
  int get _userId => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _svc.getBettingMatches(),
        _svc.getUserBets(_userId),
      ]);
      if (mounted) setState(() { _matches = results[0]; _myBets = results[1]; });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelection(_BetSelection sel) {
    setState(() {
      final idx = _slip.indexWhere((s) => s.matchId == sel.matchId && s.betType == sel.betType);
      if (idx >= 0) {
        _slip.removeAt(idx);
      } else {
        _slip.removeWhere((s) => s.matchId == sel.matchId);
        _slip.add(sel);
      }
    });
  }

  bool _isSelected(dynamic matchId, String betType) =>
      _slip.any((s) => s.matchId == matchId && s.betType == betType);

  void _openSlip() {
    if (_slip.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _BetSlip(
        selections: List.from(_slip),
        userId: _userId,
        service: _svc,
        onConfirm: (stake) async {
          for (final sel in _slip) {
            await _svc.placeBet(
              userId: _userId, matchId: sel.matchId,
              homeName: sel.homeName, awayName: sel.awayName,
              betType: sel.betType, betLabel: sel.betLabel,
              odds: sel.odds, stake: stake,
            );
          }
          if (mounted) {
            setState(() => _slip.clear());
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('¡Apuesta registrada!')),
            );
            _load();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      children: [
        _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                  children: [
                    _SectionHeader(label: 'Próximos Partidos', icon: Icons.schedule),
                    ..._matches.map((m) => _MatchOddsCard(
                          match: m,
                          isSelected: _isSelected,
                          onSelect: _toggleSelection,
                        )),
                    if (_matches.isEmpty)
                      const _EmptyState(
                          icon: Icons.sports_soccer,
                          text: 'No hay partidos disponibles ahora.\nTira hacia abajo para actualizar.'),
                    if (_myBets.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(label: 'Mis Apuestas', icon: Icons.receipt_long),
                      ..._myBets.take(10).map((b) => _BetHistoryCard(bet: b)),
                    ],
                  ],
                ),
              ),

        // Botón flotante del boleto
        if (_slip.isNotEmpty)
          Positioned(
            bottom: 16, left: 16, right: 16,
            child: ElevatedButton.icon(
              onPressed: _openSlip,
              icon: CircleAvatar(
                radius: 10,
                backgroundColor: theme.colorScheme.secondary,
                child: Text('${_slip.length}',
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              ),
              label: const Text('Ver Boleto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 6,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Tarjeta de partido con cuotas ─────────────────────────────────────────────
class _MatchOddsCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final bool Function(dynamic matchId, String betType) isSelected;
  final void Function(_BetSelection) onSelect;

  const _MatchOddsCard({required this.match, required this.isSelected, required this.onSelect});

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final odds   = Map<String, dynamic>.from(match['odds'] ?? {});
    final mid    = match['match_id'];
    final home   = match['home_name'] as String? ?? 'Local';
    final away   = match['away_name'] as String? ?? 'Visitante';
    final status = match['status'] as String? ?? '';
    final live   = status == 'IN_PLAY' || status == 'LIVE';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Header partido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: live ? Colors.red.shade700 : theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                if (live) ...[
                  const Icon(Icons.circle, color: Colors.white, size: 8),
                  const SizedBox(width: 4),
                  const Text('EN VIVO', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ] else
                  Text(_fmt(match['date']),
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.sports_soccer, color: Colors.white60, size: 14),
              ],
            ),
          ),
          // Equipos
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(child: Text(home, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('vs', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                ),
                Expanded(child: Text(away, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center)),
              ],
            ),
          ),
          // Cuotas 1X2
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
            child: Row(
              children: [
                _OddsBtn(label: '1 Local', value: odds['home_win'], selected: isSelected(mid, 'home_win'),
                    onTap: () => onSelect(_BetSelection(matchId: mid, homeName: home, awayName: away, betType: 'home_win', betLabel: '$home gana', odds: (odds['home_win'] as num).toDouble()))),
                const SizedBox(width: 6),
                _OddsBtn(label: 'X Empate', value: odds['draw'], selected: isSelected(mid, 'draw'),
                    onTap: () => onSelect(_BetSelection(matchId: mid, homeName: home, awayName: away, betType: 'draw', betLabel: 'Empate', odds: (odds['draw'] as num).toDouble()))),
                const SizedBox(width: 6),
                _OddsBtn(label: '2 Visita', value: odds['away_win'], selected: isSelected(mid, 'away_win'),
                    onTap: () => onSelect(_BetSelection(matchId: mid, homeName: home, awayName: away, betType: 'away_win', betLabel: '$away gana', odds: (odds['away_win'] as num).toDouble()))),
              ],
            ),
          ),
          // Marcadores exactos
          if ((odds['top_scores'] as List?)?.isNotEmpty == true) ...[
            const Divider(height: 1),
            _ScoreOddsRow(
              matchId: mid, homeName: home, awayName: away,
              scores: List<Map<String, dynamic>>.from(odds['top_scores']),
              isSelected: isSelected, onSelect: onSelect,
            ),
          ],
          // Probabilidades (modelo)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            child: _ProbBar(
              probHome: (odds['prob_home'] as num?)?.toDouble() ?? 33,
              probDraw: (odds['prob_draw'] as num?)?.toDouble() ?? 34,
              probAway: (odds['prob_away'] as num?)?.toDouble() ?? 33,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón de cuota ────────────────────────────────────────────────────────────
class _OddsBtn extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool selected;
  final VoidCallback onTap;
  const _OddsBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.secondary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? theme.colorScheme.secondary : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: selected ? Colors.white70 : Colors.grey.shade600)),
              const SizedBox(height: 3),
              Text(
                '${value ?? '-'}',
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold,
                  color: selected ? Colors.white : theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Fila de marcadores exactos ────────────────────────────────────────────────
class _ScoreOddsRow extends StatelessWidget {
  final dynamic matchId;
  final String homeName, awayName;
  final List<Map<String, dynamic>> scores;
  final bool Function(dynamic, String) isSelected;
  final void Function(_BetSelection) onSelect;
  const _ScoreOddsRow({required this.matchId, required this.homeName, required this.awayName,
      required this.scores, required this.isSelected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Marcador exacto', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6, runSpacing: 6,
            children: scores.take(6).map((s) {
              final score   = s['score'] as String;
              final odds    = (s['odds'] as num).toDouble();
              final bType   = 'score_$score';
              final sel     = isSelected(matchId, bType);
              return GestureDetector(
                onTap: () => onSelect(_BetSelection(
                    matchId: matchId, homeName: homeName, awayName: awayName,
                    betType: bType, betLabel: 'Marcador $score', odds: odds)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? theme.colorScheme.secondary : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: sel ? theme.colorScheme.secondary : Colors.grey.shade300),
                  ),
                  child: Column(
                    children: [
                      Text(score, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
                          color: sel ? Colors.white : Colors.black87)),
                      Text('x${odds.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 10, color: sel ? Colors.white70 : Colors.grey.shade600)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Barra de probabilidades ───────────────────────────────────────────────────
class _ProbBar extends StatelessWidget {
  final double probHome, probDraw, probAway;
  const _ProbBar({required this.probHome, required this.probDraw, required this.probAway});

  @override
  Widget build(BuildContext context) {
    final total = probHome + probDraw + probAway;
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${probHome.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.green)),
          Text('${probDraw.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.grey)),
          Text('${probAway.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: Colors.red)),
        ]),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Flexible(flex: (probHome * 100 / total).round(), child: Container(height: 5, color: Colors.green.shade400)),
              Flexible(flex: (probDraw * 100 / total).round(),  child: Container(height: 5, color: Colors.grey.shade300)),
              Flexible(flex: (probAway * 100 / total).round(),  child: Container(height: 5, color: Colors.red.shade400)),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Local', style: TextStyle(fontSize: 9, color: Colors.grey)),
          const Text('Empate', style: TextStyle(fontSize: 9, color: Colors.grey)),
          const Text('Visitante', style: TextStyle(fontSize: 9, color: Colors.grey)),
        ]),
      ],
    );
  }
}

// ── Boleto de apuesta (bottom sheet) ─────────────────────────────────────────
class _BetSlip extends StatefulWidget {
  final List<_BetSelection> selections;
  final int userId;
  final BettingService service;
  final Future<void> Function(int stake) onConfirm;
  const _BetSlip({required this.selections, required this.userId,
      required this.service, required this.onConfirm});
  @override
  State<_BetSlip> createState() => _BetSlipState();
}

class _BetSlipState extends State<_BetSlip> {
  int _stake = 100;
  bool _placing = false;

  double get _totalOdds => widget.selections.fold(1.0, (acc, s) => acc * s.odds);
  int get _potentialWin => (_stake * _totalOdds).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const Spacer(),
              Text('Boleto de Apuesta', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              const SizedBox(width: 40),
            ]),
            const SizedBox(height: 16),

            // Selecciones
            ...widget.selections.map((s) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${s.homeName} vs ${s.awayName}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(s.betLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('x${s.odds.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ]),
            )),

            const Divider(height: 20),

            // Monto
            Row(children: [
              const Text('Monto (monedas):', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              _StakeChip(value: 50,  current: _stake, onTap: () => setState(() => _stake = 50)),
              _StakeChip(value: 100, current: _stake, onTap: () => setState(() => _stake = 100)),
              _StakeChip(value: 250, current: _stake, onTap: () => setState(() => _stake = 250)),
              _StakeChip(value: 500, current: _stake, onTap: () => setState(() => _stake = 500)),
            ]),
            const SizedBox(height: 12),

            // Resumen
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Cuota total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('x${_totalOdds.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Ganancia potencial', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  Text('$_potentialWin 🪙',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _placing ? null : () async {
                setState(() => _placing = true);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  await widget.onConfirm(_stake);
                } catch (e) {
                  if (mounted) messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                  if (mounted) setState(() => _placing = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _placing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('APOSTAR · $_stake monedas', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}

class _StakeChip extends StatelessWidget {
  final int value, current;
  final VoidCallback onTap;
  const _StakeChip({required this.value, required this.current, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: sel ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
        ),
        child: Text('$value', style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold,
            color: sel ? Colors.white : Colors.grey.shade700)),
      ),
    );
  }
}

// ── Historial de apuesta ──────────────────────────────────────────────────────
class _BetHistoryCard extends StatelessWidget {
  final Map<String, dynamic> bet;
  const _BetHistoryCard({required this.bet});

  Color _statusColor(String s) => switch (s) {
    'won'  => Colors.green, 'lost' => Colors.red,
    'cancelled' => Colors.grey, _ => Colors.orange,
  };

  String _statusLabel(String s) => switch (s) {
    'won'  => 'Ganada', 'lost' => 'Perdida',
    'cancelled' => 'Cancelada', _ => 'Pendiente',
  };

  @override
  Widget build(BuildContext context) {
    final status = bet['status'] as String? ?? 'pending';
    final color  = _statusColor(status);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        title: Text(bet['bet_label'] ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${bet['home_name']} vs ${bet['away_name']}  •  x${(bet['odds'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12)),
        trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4)),
            child: Text(_statusLabel(status),
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 2),
          Text('${bet['stake']} → ${bet['potential_win']} 🪙',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
        ]),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 4),
    child: Row(children: [
      Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
      const SizedBox(width: 8),
      Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
    ]),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(children: [
        Icon(icon, size: 52, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(text, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.5)),
      ]),
    ),
  );
}
