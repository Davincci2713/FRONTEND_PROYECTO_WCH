import 'package:flutter/material.dart';
import '../services/betting_service.dart';
import '../services/auth/auth.dart';

// ── Modelo local ─────────────────────────────────────────────────────────────
class _BetSelection {
  final dynamic matchId;
  final String homeName, awayName, betType, betLabel;
  final double odds;
  _BetSelection({
    required this.matchId,
    required this.homeName,
    required this.awayName,
    required this.betType,
    required this.betLabel,
    required this.odds,
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
  List<dynamic> _myBets = [];
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
      if (mounted)
        setState(() {
          _matches = results[0];
          _myBets = results[1];
        });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleSelection(_BetSelection sel) {
    setState(() {
      final idx = _slip.indexWhere(
        (s) => s.matchId == sel.matchId && s.betType == sel.betType,
      );
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
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _BetSlip(
        selections: List.from(_slip),
        userId: _userId,
        service: _svc,
        onConfirm: (stake) async {
          for (final sel in _slip) {
            await _svc.placeBet(
              userId: _userId,
              matchId: sel.matchId,
              homeName: sel.homeName,
              awayName: sel.awayName,
              betType: sel.betType,
              betLabel: sel.betLabel,
              odds: sel.odds,
              stake: stake,
            );
          }
          if (mounted) {
            setState(() => _slip.clear());
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Apuesta registrada')));
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
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    _SectionHeader(
                      label: 'Próximos partidos',
                      icon: Icons.schedule,
                    ),
                    const SizedBox(height: 16),
                    ..._matches.map(
                      (m) => _MatchOddsCard(
                        match: m,
                        isSelected: _isSelected,
                        onSelect: _toggleSelection,
                      ),
                    ),
                    if (_matches.isEmpty)
                      const _EmptyState(
                        icon: Icons.sports_soccer,
                        text:
                            'No hay partidos disponibles ahora.\nTira hacia abajo para actualizar.',
                      ),
                    if (_myBets.isNotEmpty) ...[
                      const SizedBox(height: 48),
                      _SectionHeader(
                        label: 'Mis apuestas',
                        icon: Icons.receipt_long,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _myBets.length > 10 ? 10 : _myBets.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (_, i) =>
                              _BetHistoryRow(bet: _myBets[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

        if (_slip.isNotEmpty)
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: ElevatedButton.icon(
              onPressed: _openSlip,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${_slip.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              label: const Text(
                'Ver boleto',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00341C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MatchOddsCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final bool Function(dynamic matchId, String betType) isSelected;
  final void Function(_BetSelection) onSelect;

  const _MatchOddsCard({
    required this.match,
    required this.isSelected,
    required this.onSelect,
  });

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final odds = Map<String, dynamic>.from(match['odds'] ?? {});
    final mid = match['match_id'];
    final home = match['home_name'] as String? ?? 'Local';
    final away = match['away_name'] as String? ?? 'Visitante';
    final status = match['status'] as String? ?? '';
    final live = status == 'IN_PLAY' || status == 'LIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Column(
        children: [
          // Header partido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                if (live) ...[
                  const Icon(Icons.circle, color: Color(0xFFBB0014), size: 10),
                  const SizedBox(width: 6),
                  const Text(
                    'EN VIVO',
                    style: TextStyle(
                      color: Color(0xFFBB0014),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    _fmt(match['date']),
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const Spacer(),
                Icon(
                  Icons.sports_soccer,
                  color: Colors.grey.shade400,
                  size: 16,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    home,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'vs',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                  ),
                ),
                Expanded(
                  child: Text(
                    away,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                _OddsBtn(
                  label: '1 Local',
                  value: odds['home_win'],
                  selected: isSelected(mid, 'home_win'),
                  onTap: () => onSelect(
                    _BetSelection(
                      matchId: mid,
                      homeName: home,
                      awayName: away,
                      betType: 'home_win',
                      betLabel: '$home gana',
                      odds: (odds['home_win'] as num).toDouble(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _OddsBtn(
                  label: 'X Empate',
                  value: odds['draw'],
                  selected: isSelected(mid, 'draw'),
                  onTap: () => onSelect(
                    _BetSelection(
                      matchId: mid,
                      homeName: home,
                      awayName: away,
                      betType: 'draw',
                      betLabel: 'Empate',
                      odds: (odds['draw'] as num).toDouble(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _OddsBtn(
                  label: '2 Visita',
                  value: odds['away_win'],
                  selected: isSelected(mid, 'away_win'),
                  onTap: () => onSelect(
                    _BetSelection(
                      matchId: mid,
                      homeName: home,
                      awayName: away,
                      betType: 'away_win',
                      betLabel: '$away gana',
                      odds: (odds['away_win'] as num).toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if ((odds['top_scores'] as List?)?.isNotEmpty == true) ...[
            Divider(height: 1, color: Colors.grey.shade200),
            _ScoreOddsRow(
              matchId: mid,
              homeName: home,
              awayName: away,
              scores: List<Map<String, dynamic>>.from(odds['top_scores']),
              isSelected: isSelected,
              onSelect: onSelect,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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

class _OddsBtn extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool selected;
  final VoidCallback onTap;
  const _OddsBtn({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF00341C) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? const Color(0xFF00341C) : Colors.grey.shade300,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${value ?? '-'}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreOddsRow extends StatelessWidget {
  final dynamic matchId;
  final String homeName, awayName;
  final List<Map<String, dynamic>> scores;
  final bool Function(dynamic, String) isSelected;
  final void Function(_BetSelection) onSelect;
  const _ScoreOddsRow({
    required this.matchId,
    required this.homeName,
    required this.awayName,
    required this.scores,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marcador exacto',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: scores.take(6).map((s) {
              final score = s['score'] as String;
              final odds = (s['odds'] as num).toDouble();
              final bType = 'score_$score';
              final sel = isSelected(matchId, bType);
              return GestureDetector(
                onTap: () => onSelect(
                  _BetSelection(
                    matchId: matchId,
                    homeName: homeName,
                    awayName: awayName,
                    betType: bType,
                    betLabel: 'Marcador $score',
                    odds: odds,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFF00341C) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF00341C)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        score,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: sel ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'x${odds.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: sel ? Colors.white70 : Colors.grey.shade600,
                        ),
                      ),
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

class _ProbBar extends StatelessWidget {
  final double probHome, probDraw, probAway;
  const _ProbBar({
    required this.probHome,
    required this.probDraw,
    required this.probAway,
  });

  @override
  Widget build(BuildContext context) {
    final total = probHome + probDraw + probAway;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${probHome.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.green.shade700,
              ),
            ),
            Text(
              '${probDraw.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
            Text(
              '${probAway.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Flexible(
                flex: (probHome * 100 / total).round(),
                child: Container(height: 6, color: Colors.green.shade500),
              ),
              Flexible(
                flex: (probDraw * 100 / total).round(),
                child: Container(height: 6, color: Colors.grey.shade300),
              ),
              Flexible(
                flex: (probAway * 100 / total).round(),
                child: Container(height: 6, color: Colors.red.shade500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Local',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              'Empate',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
            Text(
              'Visitante',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }
}

class _BetSlip extends StatefulWidget {
  final List<_BetSelection> selections;
  final int userId;
  final BettingService service;
  final Future<void> Function(int stake) onConfirm;
  const _BetSlip({
    required this.selections,
    required this.userId,
    required this.service,
    required this.onConfirm,
  });
  @override
  State<_BetSlip> createState() => _BetSlipState();
}

class _BetSlipState extends State<_BetSlip> {
  int _stake = 10;
  bool _placing = false;

  double get _totalOdds =>
      widget.selections.fold(1.0, (acc, s) => acc * s.odds);
  int get _potentialWin => (_stake * _totalOdds).round();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Boleto de apuesta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 40),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: widget.selections
                    .map(
                      (s) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${s.homeName} vs ${s.awayName}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    s.betLabel,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'x${s.odds.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text(
                  'Monto (USD)',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                _StakeChip(
                  value: 5,
                  current: _stake,
                  onTap: () => setState(() => _stake = 5),
                ),
                _StakeChip(
                  value: 10,
                  current: _stake,
                  onTap: () => setState(() => _stake = 10),
                ),
                _StakeChip(
                  value: 25,
                  current: _stake,
                  onTap: () => setState(() => _stake = 25),
                ),
                _StakeChip(
                  value: 50,
                  current: _stake,
                  onTap: () => setState(() => _stake = 50),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cuota total',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'x${_totalOdds.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Ganancia potencial',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$$_potentialWin',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'Pago seguro • Modo de prueba',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _placing
                  ? null
                  : () async {
                      setState(() => _placing = true);
                      final messenger = ScaffoldMessenger.of(context);
                      try {
                        await widget.onConfirm(_stake);
                      } catch (e) {
                        if (mounted)
                          messenger.showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        if (mounted) setState(() => _placing = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00341C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              child: _placing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.credit_card, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Pagar \$$_stake',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
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
  const _StakeChip({
    required this.value,
    required this.current,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF00341C) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: sel ? const Color(0xFF00341C) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          '\$$value',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: sel ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}

class _BetHistoryRow extends StatelessWidget {
  final Map<String, dynamic> bet;
  const _BetHistoryRow({required this.bet});

  Color _statusColor(String s) => switch (s) {
    'won' => Colors.green.shade700,
    'lost' => const Color(0xFFBB0014),
    'cancelled' => Colors.grey.shade600,
    _ => Colors.orange.shade700,
  };

  String _statusLabel(String s) => switch (s) {
    'won' => 'Ganada',
    'lost' => 'Perdida',
    'cancelled' => 'Cancelada',
    _ => 'Pendiente',
  };

  @override
  Widget build(BuildContext context) {
    final status = bet['status'] as String? ?? 'pending';
    final color = _statusColor(status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bet['bet_label'] ?? '—',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${bet['home_name']} vs ${bet['away_name']} • x${(bet['odds'] as num).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _statusLabel(status),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${bet['stake']} → ${bet['potential_win']} USD',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 20, color: Colors.black87),
      const SizedBox(width: 8),
      Text(
        label,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    ],
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    ),
  );
}
