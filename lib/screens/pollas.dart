import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import '../services/betting_service.dart';
import '../services/auth/auth.dart';
import '../utils/theme.dart';

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

// ── Pantalla de apuestas con Tabs ─────────────────────────────────────────────
class PollasScreen extends StatelessWidget {
  const PollasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: TabBar(
              labelColor: AppColors.accentText,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accentText,
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
              tabs: const [
                Tab(icon: Icon(Icons.sports_soccer_rounded, size: 20), text: 'APUESTAS'),
                Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'HISTORIAL'),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _BettingTab(),
            _HistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ── Tab de Historial ──────────────────────────────────────────────────────────
class _HistoryTab extends StatefulWidget {
  const _HistoryTab();
  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  final _svc = BettingService();
  List<dynamic> _bets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid = AuthService().currentUserId ?? 1;
      final data = await _svc.getUserBets(uid);
      if (mounted) setState(() => _bets = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_bets.isEmpty) {
      return const _EmptyState(
        icon: Icons.receipt_long_rounded,
        text: 'AÚN NO HAS REALIZADO NINGUNA APUESTA.',
      );
    }

    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _bets.length,
        separatorBuilder: (_, _) => SizedBox(height: 16),
        itemBuilder: (_, i) => _BetHistoryRow(bet: _bets[i]),
      ),
    );
  }
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
      if (mounted) {
        setState(() {
          _matches = results[0];
          _myBets = results[1];
        });
      }
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
      backgroundColor: Colors.transparent,
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('APUESTA REGISTRADA EXITOSAMENTE', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold))),
            );
            _load();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _loading
            ? Center(child: CircularProgressIndicator(color: AppColors.primary))
            : RefreshIndicator(
                color: AppColors.onPrimary,
                backgroundColor: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                  children: [
                    const _SectionHeader(label: 'PRÓXIMOS PARTIDOS', icon: Icons.schedule_rounded),
                    SizedBox(height: 24),
                    ..._matches.map(
                      (m) => _MatchOddsCard(
                        match: m,
                        isSelected: _isSelected,
                        onSelect: _toggleSelection,
                      ),
                    ),
                    if (_matches.isEmpty)
                      const _EmptyState(
                        icon: Icons.sports_soccer_rounded,
                        text: 'NO HAY PARTIDOS DISPONIBLES AHORA.',
                      ),
                    if (_myBets.isNotEmpty) ...[
                      SizedBox(height: 48),
                      const _SectionHeader(label: 'APUESTAS RECIENTES', icon: Icons.receipt_long_rounded),
                      SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: AppColors.border, width: 2),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _myBets.length > 10 ? 10 : _myBets.length,
                          separatorBuilder: (_, _) => Divider(),
                          itemBuilder: (_, i) => _BetHistoryRow(bet: _myBets[i], compact: true),
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
            child: _SlipFab(count: _slip.length, onTap: _openSlip),
          ),
      ],
    );
  }
}

// ── Floating slip button ──────────────────────────────────────────────────────
class _SlipFab extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  const _SlipFab({required this.count, required this.onTap});
  @override
  State<_SlipFab> createState() => _SlipFabState();
}

class _SlipFabState extends State<_SlipFab> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: AppColors.onPrimary, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary,
                  border: Border.all(color: AppColors.onPrimary, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${widget.count}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w900),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  'VER BOLETO DE APUESTA',
                  style: GoogleFonts.spaceGrotesk(color: AppColors.onPrimary, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5),
                ),
              ),
              Icon(Icons.arrow_forward_sharp, color: AppColors.onPrimary, size: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────
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
    final home = match['home_name'] as String? ?? 'LOCAL';
    final away = match['away_name'] as String? ?? 'VISITANTE';
    final status = match['status'] as String? ?? '';
    final live = status == 'IN_PLAY' || status == 'LIVE';

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          // ── Card header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: live ? AppColors.primary.withValues(alpha: 0.1) : AppColors.inverseSurface,
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: Row(
              children: [
                if (live) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      border: Border.all(color: AppColors.onPrimary, width: 1),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.circle, color: AppColors.onPrimary, size: 8),
                      SizedBox(width: 6),
                      Text('EN VIVO', style: GoogleFonts.spaceGrotesk(color: AppColors.onPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ]),
                  ),
                ] else ...[
                  Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                  SizedBox(width: 8),
                  Text(
                    _fmt(match['date']),
                    style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                ],
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Text('FIFA WC 2026', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text, fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ),
          ),

          // ── Teams ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(home.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    border: Border.all(color: AppColors.onPrimary, width: 2),
                  ),
                  child: Text('VS', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.onPrimary, letterSpacing: -1)),
                ),
                Expanded(
                  child: Text(away.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // ── Odds buttons ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                _OddsBtn(
                  label: '1 LOCAL', value: odds['home_win'],
                  selected: isSelected(mid, 'home_win'),
                  onTap: () => onSelect(_BetSelection(
                    matchId: mid, homeName: home, awayName: away,
                    betType: 'home_win', betLabel: '$home gana',
                    odds: (odds['home_win'] as num).toDouble(),
                  )),
                ),
                SizedBox(width: 12),
                _OddsBtn(
                  label: 'X EMPATE', value: odds['draw'],
                  selected: isSelected(mid, 'draw'),
                  onTap: () => onSelect(_BetSelection(
                    matchId: mid, homeName: home, awayName: away,
                    betType: 'draw', betLabel: 'Empate',
                    odds: (odds['draw'] as num).toDouble(),
                  )),
                ),
                SizedBox(width: 12),
                _OddsBtn(
                  label: '2 VISITA', value: odds['away_win'],
                  selected: isSelected(mid, 'away_win'),
                  onTap: () => onSelect(_BetSelection(
                    matchId: mid, homeName: home, awayName: away,
                    betType: 'away_win', betLabel: '$away gana',
                    odds: (odds['away_win'] as num).toDouble(),
                  )),
                ),
              ],
            ),
          ),

          // ── Score odds ─────────────────────────────────────────────────
          if ((odds['top_scores'] as List?)?.isNotEmpty == true) ...[
            Divider(),
            _ScoreOddsRow(
              matchId: mid, homeName: home, awayName: away,
              scores: List<Map<String, dynamic>>.from(odds['top_scores']),
              isSelected: isSelected, onSelect: onSelect,
            ),
          ],

          // ── Probability bar ────────────────────────────────────────────
          Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
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

// ── Odds button ───────────────────────────────────────────────────────────────
class _OddsBtn extends StatelessWidget {
  final String label;
  final dynamic value;
  final bool selected;
  final VoidCallback onTap;
  const _OddsBtn({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: selected ? Colors.black54 : AppColors.textMuted,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '${value ?? '-'}',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.black : AppColors.text,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Score odds row ────────────────────────────────────────────────────────────
class _ScoreOddsRow extends StatelessWidget {
  final dynamic matchId;
  final String homeName, awayName;
  final List<Map<String, dynamic>> scores;
  final bool Function(dynamic, String) isSelected;
  final void Function(_BetSelection) onSelect;
  const _ScoreOddsRow({
    required this.matchId, required this.homeName, required this.awayName,
    required this.scores, required this.isSelected, required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.scoreboard_rounded, size: 16, color: AppColors.textMuted),
            SizedBox(width: 8),
            Text('MARCADOR EXACTO',
              style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
          ]),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: scores.take(6).map((s) {
              final score = s['score'] as String;
              final odds = (s['odds'] as num).toDouble();
              final bType = 'score_$score';
              final sel = isSelected(matchId, bType);
              return GestureDetector(
                onTap: () => onSelect(_BetSelection(
                  matchId: matchId, homeName: homeName, awayName: awayName,
                  betType: bType, betLabel: 'Marcador $score', odds: odds,
                )),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(score,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16,
                            color: sel ? Colors.black : AppColors.text)),
                      SizedBox(height: 4),
                      Text('x${odds.toStringAsFixed(2)}',
                        style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold,
                            color: sel ? Colors.black54 : AppColors.accentText)),
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

// ── Probability bar ───────────────────────────────────────────────────────────
class _ProbBar extends StatelessWidget {
  final double probHome, probDraw, probAway;
  const _ProbBar({required this.probHome, required this.probDraw, required this.probAway});

  @override
  Widget build(BuildContext context) {
    final total = probHome + probDraw + probAway;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ProbLabel('${probHome.toStringAsFixed(0)}%', 'LOCAL', AppColors.primary),
            _ProbLabel('${probDraw.toStringAsFixed(0)}%', 'EMPATE', AppColors.textMuted, center: true),
            _ProbLabel('${probAway.toStringAsFixed(0)}%', 'VISITANTE', AppColors.primaryDark, right: true),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 12,
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border, width: 2),
          ),
          child: Row(
            children: [
              Flexible(
                flex: (probHome * 100 / total).round(),
                child: Container(color: AppColors.primary),
              ),
              Flexible(
                flex: (probDraw * 100 / total).round(),
                child: Container(color: AppColors.surfaceVariant),
              ),
              Flexible(
                flex: (probAway * 100 / total).round(),
                child: Container(color: AppColors.primaryDark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProbLabel extends StatelessWidget {
  final String value, label;
  final Color color;
  final bool center, right;
  const _ProbLabel(this.value, this.label, this.color, {this.center = false, this.right = false});

  @override
  Widget build(BuildContext context) {
    final align = right ? CrossAxisAlignment.end : (center ? CrossAxisAlignment.center : CrossAxisAlignment.start);
    return Column(crossAxisAlignment: align, children: [
      Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
    ]);
  }
}

// ── Bet slip ──────────────────────────────────────────────────────────────────
class _BetSlip extends StatefulWidget {
  final List<_BetSelection> selections;
  final int userId;
  final BettingService service;
  final Future<void> Function(int stake) onConfirm;
  const _BetSlip({required this.selections, required this.userId, required this.service, required this.onConfirm});
  @override
  State<_BetSlip> createState() => _BetSlipState();
}

class _BetSlipState extends State<_BetSlip> {
  int _stake = 10;
  bool _placing = false;

  double get _totalOdds => widget.selections.fold(1.0, (acc, s) => acc * s.odds);
  int get _potentialWin => (_stake * _totalOdds).round();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.primary, width: 4)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Title ──────────────────────────────────────────────────
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(color: AppColors.onPrimary, width: 2),
                ),
                child: Icon(Icons.receipt_long_rounded, color: AppColors.onPrimary, size: 24),
              ),
              SizedBox(width: 16),
              Text('BOLETO',
                style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -2)),
              const Spacer(),
              Text('${widget.selections.length} SELECC.',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
            SizedBox(height: 32),

            // ── Selections ─────────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Column(
                children: widget.selections.map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(color: AppColors.primary, width: 4),
                      bottom: BorderSide(color: AppColors.borderLight, width: 2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${s.homeName} VS ${s.awayName}'.toUpperCase(),
                              style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            SizedBox(height: 4),
                            Text(s.betLabel.toUpperCase(),
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text, letterSpacing: -0.5)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          border: Border.all(color: AppColors.primary, width: 2),
                        ),
                        child: Text('x${s.odds.toStringAsFixed(2)}',
                          style: GoogleFonts.spaceGrotesk(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ],
                  ),
                )).toList(),
              ),
            ),
            SizedBox(height: 32),

            // ── Stake ──────────────────────────────────────────────────
            Row(children: [
              Text('MONTO (USD)', style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, color: AppColors.text, letterSpacing: 1, fontSize: 12)),
              const Spacer(),
              ...[5, 10, 25, 50].map((v) => _StakeChip(
                value: v, current: _stake,
                onTap: () => setState(() => _stake = v),
              )),
            ]),
            SizedBox(height: 32),

            // ── Summary ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('CUOTA TOTAL', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text('x${_totalOdds.toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -2)),
                    ]),
                  ),
                  Container(width: 2, height: 48, color: AppColors.border),
                  SizedBox(width: 24),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('GANANCIA', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      SizedBox(height: 8),
                      Text('\$$_potentialWin',
                        style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -2)),
                    ]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: AppColors.textMuted),
              SizedBox(width: 8),
              Text('PAGO SEGURO • MODO DE PRUEBA',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ]),
            SizedBox(height: 32),

            // ── Confirm button ─────────────────────────────────────────
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
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 24)),
              child: _placing
                ? SizedBox(width: 24, height: 24,
                    child: CircularProgressIndicator(color: AppColors.onPrimary, strokeWidth: 3))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.credit_card_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('CONFIRMAR • \$$_stake',
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)),
                  ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stake chip ────────────────────────────────────────────────────────────────
class _StakeChip extends StatelessWidget {
  final int value, current;
  final VoidCallback onTap;
  const _StakeChip({required this.value, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = value == current;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? AppColors.primary : Colors.transparent,
          border: Border.all(color: sel ? AppColors.primary : AppColors.border, width: 2),
        ),
        child: Text(
          '\$$value',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16, fontWeight: FontWeight.w900,
            color: sel ? Colors.black : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

// ── Bet history row ───────────────────────────────────────────────────────────
class _BetHistoryRow extends StatelessWidget {
  final Map<String, dynamic> bet;
  final bool compact;
  const _BetHistoryRow({required this.bet, this.compact = false});

  Color _statusColor(String s) => switch (s) {
    'won'       => AppColors.primary,
    'lost'      => AppColors.error,
    'cancelled' => AppColors.textMuted,
    _           => const Color(0xFF00FFFF), // Cyan pending
  };

  String _statusLabel(String s) => switch (s) {
    'won'       => 'GANADA',
    'lost'      => 'PERDIDA',
    'cancelled' => 'CANCELADA',
    _           => 'PENDIENTE',
  };

  @override
  Widget build(BuildContext context) {
    final status = bet['status'] as String? ?? 'pending';
    final color = _statusColor(status);

    final row = Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: compact ? 16 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (bet['bet_label'] ?? '—').toString().toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text, letterSpacing: -0.5),
                ),
                SizedBox(height: 6),
                Text(
                  '${bet['home_name']} VS ${bet['away_name']} • X${(bet['odds'] as num).toStringAsFixed(2)}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: Text(_statusLabel(status),
                  style: GoogleFonts.spaceGrotesk(fontSize: 10, color: color, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ),
              SizedBox(height: 8),
              Text(
                '${bet['stake']} → ${bet['potential_win']} USD',
                style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );

    if (compact) return row;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: row,
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionHeader({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: AppColors.onPrimary, width: 2),
        ),
        child: Icon(icon, size: 16, color: AppColors.onPrimary),
      ),
      SizedBox(width: 12),
      Text(label, style: GoogleFonts.spaceGrotesk(fontSize: 18, color: AppColors.text, fontWeight: FontWeight.w900, letterSpacing: -1)),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
          SizedBox(height: 24),
          Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, height: 1.6, letterSpacing: 1)),
        ],
      ),
    ),
  );
}
