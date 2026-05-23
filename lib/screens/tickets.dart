import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:frontend_proyecto/providers/theme_provider.dart';
import '../services/ticket_service.dart';
import '../services/auth/auth.dart';
import '../utils/theme.dart';

// ── Colores de estado ─────────────────────────────────────────────────────────
Color _statusColor(String s) => switch (s.toLowerCase()) {
  'pagada'      => AppColors.primary,
  'reservada'   => const Color(0xFF00FFFF), // Cyan
  'transferida' => const Color(0xFFFF00FF), // Magenta
  'reembolsada' => AppColors.error,
  'expirada'    => AppColors.textMuted,
  _             => AppColors.border,
};

String _statusLabel(String s) => switch (s.toLowerCase()) {
  'disponible' => 'DISPONIBLE',
  'reservada' => 'RESERVADA',
  'pagada' => 'PAGADA',
  'transferida' => 'TRANSFERIDA',
  'reembolsada' => 'REEMBOLSADA',
  'expirada' => 'EXPIRADA',
  _ => s.toUpperCase(),
};

String _statusIcon(String s) => switch (s.toLowerCase()) {
  'pagada'      => '',
  'reservada'   => '',
  'transferida' => '',
  'reembolsada' => '',
  'expirada'    => '',
  _             => '',
};

// ── Pantalla principal ────────────────────────────────────────────────────────
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});
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
              Tab(icon: Icon(Icons.confirmation_number_rounded, size: 20), text: 'COMPRAR'),
              Tab(icon: Icon(Icons.receipt_long_rounded, size: 20), text: 'MIS ENTRADAS'),
            ],
          ),
        ),
      ),
      body: const TabBarView(children: [_BuyTab(), _MyTicketsTab()]),
    ),
  );
  }
}

class _BuyTab extends StatefulWidget {
  const _BuyTab();
  @override
  State<_BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends State<_BuyTab> {
  final _svc = TicketService();
  List<dynamic> _matches = [];
  Map<String, dynamic> _dailyStats = {};
  bool _loading = true;
  int get _uid => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final matchesData = await _svc.getAvailableMatches();
      final statsData = await _svc.getUserDailyStats(_uid);
      if (mounted) {
        setState(() {
          _matches = matchesData;
          _dailyStats = statsData;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.primary));

    final purchasesToday = _dailyStats['purchasesToday'] ?? 0;
    final maxPurchases = _dailyStats['maxPurchasesPerDay'] ?? 4;
    final limitReached = purchasesToday >= maxPurchases;

    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: limitReached ? AppColors.error.withValues(alpha: 0.1) : AppColors.surface,
              border: Border.all(
                color: limitReached ? AppColors.error : AppColors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  limitReached ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  color: limitReached ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    limitReached
                        ? 'LÍMITE DIARIO DE COMPRAS ALCANZADO ($purchasesToday/$maxPurchases)'
                        : 'COMPRAS REALIZADAS HOY: $purchasesToday DE $maxPurchases TICKETS MÁXIMO.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: limitReached ? AppColors.error : AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: _Empty(icon: Icons.event_busy_rounded, text: 'NO HAY PARTIDOS DISPONIBLES.'),
              ),
            )
          else
            ..._matches.map((match) {
              final avail = match['available'] as int? ?? 0;
              final sold = avail == 0;
              final disabled = sold || limitReached;
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: _MatchCard(
                  match: match,
                  limitReached: limitReached,
                  onReserve: disabled ? null : () => _reserve(match),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _reserve(Map<String, dynamic> match) async {
    if (match['available'] == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'RESERVAR ENTRADA',
        content: 'RESERVAR ENTRADA PARA\n${match['home_name']} VS ${match['away_name']}\n\nPRECIO: \$${match['price']}\n\n⏱ TIENES 10 MINUTOS PARA COMPLETAR EL PAGO.',
        confirmLabel: 'RESERVAR',
        confirmColor: AppColors.primary,
      ),
    );
    if (confirmed != true) return;

    try {
      await _svc.reserveTicket(_uid, match['match_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ENTRADA RESERVADA. VE A "MIS ENTRADAS" PARA PAGAR.', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
        ),
      );
      DefaultTabController.of(context).animateTo(1);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${e.toString().toUpperCase()}', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final bool limitReached;
  final VoidCallback? onReserve;
  const _MatchCard({required this.match, required this.limitReached, required this.onReserve});

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${_mes(dt.month)} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _mes(int m) => ['', 'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN', 'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'][m];

  @override
  Widget build(BuildContext context) {
    final avail = match['available'] as int? ?? 0;
    final sold = avail == 0;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: sold ? Colors.black : AppColors.primary.withValues(alpha: 0.1),
              border: Border(bottom: BorderSide(color: AppColors.border, width: 2)),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Text(_fmt(match['date'] as String?),
                  style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: avail > 0 ? AppColors.primary : AppColors.error,
                    border: Border.all(color: AppColors.onPrimary, width: 2),
                  ),
                  child: Text(
                    avail > 0 ? '$avail DISPONIBLES' : 'AGOTADO',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.onPrimary,
                      fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Teams ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text((match['home_name'] as String? ?? '—').toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
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
                  child: Text((match['away_name'] as String? ?? '—').toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1),
                    textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          // ── Price + action ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('PRECIO', style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  SizedBox(height: 4),
                  Text('\$${match['price']}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.text, letterSpacing: -2)),
                ]),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: onReserve,
                  icon: Icon(
                    sold
                        ? Icons.block_rounded
                        : (limitReached ? Icons.warning_amber_rounded : Icons.confirmation_number_rounded),
                    size: 20,
                  ),
                  label: Text(
                    sold
                        ? 'AGOTADO'
                        : (limitReached ? 'LÍMITE ALCANZADO' : 'RESERVAR'),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — MIS ENTRADAS
// ══════════════════════════════════════════════════════════════════════════════
class _MyTicketsTab extends StatefulWidget {
  const _MyTicketsTab();
  @override
  State<_MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<_MyTicketsTab> {
  final _svc = TicketService();
  List<dynamic> _tickets = [];
  Map<String, dynamic> _dailyStats = {};
  bool _loading = true;
  int get _uid => AuthService().currentUserId ?? 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final ticketsData = await _svc.getUserTickets(_uid);
      final statsData = await _svc.getUserDailyStats(_uid);
      if (mounted) {
        setState(() {
          _tickets = ticketsData;
          _dailyStats = statsData;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator(color: AppColors.primary));

    final transfersToday = _dailyStats['transfersToday'] ?? 0;
    final maxTransfers = _dailyStats['maxTransfersPerDay'] ?? 3;
    final limitReached = transfersToday >= maxTransfers;

    return RefreshIndicator(
      color: AppColors.onPrimary,
      backgroundColor: AppColors.primary,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: limitReached ? AppColors.error.withValues(alpha: 0.1) : AppColors.surface,
              border: Border.all(
                color: limitReached ? AppColors.error : AppColors.border,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  limitReached ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                  color: limitReached ? AppColors.error : AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    limitReached
                        ? 'LÍMITE DIARIO DE TRANSFERENCIAS ALCANZADO ($transfersToday/$maxTransfers)'
                        : 'TRANSFERENCIAS REALIZADAS HOY: $transfersToday DE $maxTransfers MÁXIMO.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: limitReached ? AppColors.error : AppColors.text,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_tickets.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: _Empty(
                  icon: Icons.confirmation_number_rounded,
                  text: 'NO TIENES ENTRADAS AÚN.\nVE A "COMPRAR" PARA RESERVAR LA TUYA.',
                ),
              ),
            )
          else
            ..._tickets.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _TicketCard(
                ticket: t,
                userId: _uid,
                service: _svc,
                dailyStats: _dailyStats,
                onRefresh: _load,
              ),
            )),
        ],
      ),
    );
  }
}

// ── Tarjeta de entrada con acciones ──────────────────────────────────────────
class _TicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final int userId;
  final TicketService service;
  final Map<String, dynamic> dailyStats;
  final VoidCallback onRefresh;
  const _TicketCard({
    required this.ticket,
    required this.userId,
    required this.service,
    required this.dailyStats,
    required this.onRefresh,
  });
  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _acting = false;
  bool _showQR = false;

  Map<String, dynamic> get t => widget.ticket;
  String get status => (t['status'] as String? ?? '').toLowerCase();
  Color get color => _statusColor(status);

  Duration? _ttl() {
    if (status != 'reservada') return null;
    final expStr = t['expirationDate'] as String?;
    if (expStr == null) return null;
    try {
      final exp = DateTime.parse(expStr).toLocal();
      final diff = exp.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) {
      return null;
    }
  }

  Future<void> _pay() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _StripeModal(price: t['price'] ?? 0),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.payTicket(t['ticketId'], widget.userId);
      widget.onRefresh();
      messenger.showSnackBar(SnackBar(content: Text('PAGO CONFIRMADO', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _transfer() async {
    final transfersToday = widget.dailyStats['transfersToday'] ?? 0;
    final maxTransfers = widget.dailyStats['maxTransfersPerDay'] ?? 3;
    if (transfersToday >= maxTransfers) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ LÍMITE DIARIO DE TRANSFERENCIAS ALCANZADO ($transfersToday/$maxTransfers)',
              style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _TransferDialog(),
    );
    if (email == null) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await widget.service.transferTicketByEmail(
        t['ticketId'],
        widget.userId,
        email,
      );
      widget.onRefresh();
      final toName = res['toName'] as String? ?? email;
      messenger.showSnackBar(
        SnackBar(
          content: Text('TRANSFERIDA A ${toName.toUpperCase()}', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _refund() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'SOLICITAR REEMBOLSO',
        content: 'ESTA ACCIÓN ES IRREVERSIBLE.\n¿CONFIRMAR REEMBOLSO DE LA ENTRADA?',
        confirmLabel: 'REEMBOLSAR',
        confirmColor: AppColors.error,
      ),
    );
    if (ok != true) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.refundTicket(
        t['ticketId'],
        widget.userId,
        'Solicitud del usuario',
      );
      widget.onRefresh();
      messenger.showSnackBar(
        SnackBar(content: Text('REEMBOLSO PROCESADO', style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.primary),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString().toUpperCase(), style: GoogleFonts.dmSans(color: AppColors.onPrimary, fontWeight: FontWeight.bold)), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _history() async {
    final items = await widget.service.getTicketHistory(t['ticketId']);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => _HistoryDialog(history: items, ticketId: t['ticketId']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ttl = _ttl();
    final matchDetail = t['match_details'] as String? ?? 'PARTIDO #${t['matchId']}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      child: Column(
        children: [
          // ── Información principal ─────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Barra de estado lateral
                Container(width: 8, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado + precio
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(color: color, width: 2),
                              ),
                              child: Text(_statusIcon(status) + _statusLabel(status),
                                style: GoogleFonts.spaceGrotesk(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                            const Spacer(),
                            Text('\$${t['price'] ?? '—'}',
                              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, color: AppColors.text, fontSize: 24, letterSpacing: -1)),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(matchDetail.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
                        if (t['stadium'] != null) ...[
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.stadium_rounded, size: 16, color: AppColors.textMuted),
                              SizedBox(width: 8),
                              Text((t['stadium'] as String).toUpperCase(),
                                style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            ],
                          ),
                        ],
                        if (ttl != null) ...[
                          SizedBox(height: 20),
                          _TTLWidget(ttl: ttl),
                        ],
                        SizedBox(height: 24),
                        _ActionsRow(
                          status: status,
                          acting: _acting,
                          onPay: status == 'reservada' ? _pay : null,
                          onTransfer: status == 'pagada' ? _transfer : null,
                          onRefund: status == 'pagada' ? _refund : null,
                          onHistory: _history,
                          onQr: status == 'pagada'
                              ? () => setState(() => _showQR = !_showQR)
                              : null,
                          qrActive: _showQR,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── QR de acceso (fuera de IntrinsicHeight) ────────────────────────
          if (status == 'pagada' && _showQR) ...[
            Row(
              children: [
                Container(width: 8, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(color: AppColors.border, thickness: 2),
                        SizedBox(height: 20),
                        Row(children: [
                          Icon(Icons.qr_code_rounded, size: 16, color: AppColors.textMuted),
                          SizedBox(width: 8),
                          Text('CÓDIGO QR DE ACCESO',
                            style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1)),
                        ]),
                        SizedBox(height: 20),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.text,
                              border: Border.all(color: AppColors.onPrimary, width: 4),
                            ),
                            child: QrImageView(
                              data: 'ticket_id:${t['ticketId'] ?? 0},match:${t['matchId'] ?? 0}',
                              version: QrVersions.auto,
                              size: 200,
                              backgroundColor: AppColors.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Countdown TTL ─────────────────────────────────────────────────────────────
class _TTLWidget extends StatefulWidget {
  final Duration ttl;
  const _TTLWidget({required this.ttl});
  @override
  State<_TTLWidget> createState() => _TTLWidgetState();
}

class _TTLWidgetState extends State<_TTLWidget> {
  late Duration _remaining;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.ttl;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _remaining = _remaining.inSeconds > 0
            ? _remaining - const Duration(seconds: 1)
            : Duration.zero;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final min = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final urgent = _remaining.inMinutes < 3;
    final color = urgent ? AppColors.error : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_rounded, size: 16, color: color),
          SizedBox(width: 8),
          Text('EXPIRA EN: $min:$sec',
            style: GoogleFonts.spaceGrotesk(fontSize: 14, color: color, fontWeight: FontWeight.w900, letterSpacing: 1)),
        ],
      ),
    );
  }
}

// ── Fila de acciones ──────────────────────────────────────────────────────────
class _ActionsRow extends StatelessWidget {
  final String status;
  final bool acting;
  final bool qrActive;
  final VoidCallback? onPay, onTransfer, onRefund, onHistory, onQr;
  const _ActionsRow({
    required this.status,
    required this.acting,
    this.qrActive = false,
    this.onPay,
    this.onTransfer,
    this.onRefund,
    this.onHistory,
    this.onQr,
  });

  @override
  Widget build(BuildContext context) {
    if (acting) {
      return Center(
        child: SizedBox(
          height: 28, width: 28,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (onPay != null)
          _Btn(label: 'PAGAR', icon: Icons.payment_rounded, color: AppColors.primary, onTap: onPay!),
        if (onTransfer != null)
          _Btn(label: 'TRANSFERIR', icon: Icons.swap_horiz_rounded, color: const Color(0xFFFF00FF), onTap: onTransfer!),
        if (onRefund != null)
          _Btn(label: 'REEMBOLSAR', icon: Icons.undo_rounded, color: AppColors.error, onTap: onRefund!),
        if (onQr != null)
          _Btn(label: qrActive ? 'OCULTAR QR' : 'VER QR',
            icon: qrActive ? Icons.qr_code_2_rounded : Icons.qr_code_rounded,
            color: const Color(0xFF00FFFF), onTap: onQr!),
        _Btn(label: 'HISTORIAL', icon: Icons.history_rounded, color: AppColors.textMuted, onTap: onHistory ?? () {}),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _Btn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 16),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color, width: 2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      textStyle: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
    ),
  );
}

// ── Modal pago Stripe (simulado) ──────────────────────────────────────────────
class _StripeModal extends StatefulWidget {
  final dynamic price;
  const _StripeModal({required this.price});
  @override
  State<_StripeModal> createState() => _StripeModalState();
}

class _StripeModalState extends State<_StripeModal> {
  bool _processing = false;

  Future<void> _startPayment() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_processing,
      child: AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
        title: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(color: const Color(0xFF6259F5), width: 2),
              ),
              child: Icon(Icons.credit_card_rounded, size: 20, color: Color(0xFF6259F5)),
            ),
            SizedBox(width: 16),
            Text('PAGO STRIPE', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
          ],
        ),
        content: _processing
            ? SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: const Color(0xFF6259F5)),
                      const SizedBox(height: 24),
                      Text(
                        'PROCESANDO PAGO...',
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('TOTAL: \$${widget.price}',
                    style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 32, color: AppColors.primary, letterSpacing: -2)),
                  SizedBox(height: 32),
                  const _MockField(label: 'NÚMERO DE TARJETA', hint: '4242 4242 4242 4242'),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _MockField(label: 'VENCIMIENTO', hint: '12 / 28')),
                      SizedBox(width: 16),
                      Expanded(child: _MockField(label: 'CVV', hint: '424')),
                    ],
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(color: const Color(0xFF6259F5), width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_rounded, size: 20, color: Color(0xFF6259F5)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('MODO DE PRUEBA STRIPE. LOS DATOS NO SE ENVÍAN A NINGÚN SERVIDOR EXTERNO.',
                            style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        actionsPadding: const EdgeInsets.all(24),
        actions: _processing
            ? []
            : [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.text,
                    side: BorderSide(color: AppColors.border, width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                  ),
                  child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
                ),
                ElevatedButton.icon(
                  onPressed: _startPayment,
                  icon: Icon(Icons.lock_rounded, size: 16),
                  label: Text('PAGAR \$${widget.price}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6259F5),
                    foregroundColor: AppColors.text,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    side: BorderSide(color: Color(0xFF6259F5), width: 2),
                  ),
                ),
              ],
      ),
    );
  }
}

class _MockField extends StatelessWidget {
  final String label, hint;
  const _MockField({required this.label, required this.hint});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1)),
      SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: AppColors.border, width: 2),
        ),
        child: Text(hint, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    ],
  );
}

// ── Modal transferencia por email ─────────────────────────────────────────────
class _TransferDialog extends StatefulWidget {
  const _TransferDialog();
  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _ctrl = TextEditingController();
  String? _error;

  bool _validEmail(String s) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-z]{2,}$', caseSensitive: false).hasMatch(s);

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
    title: Text('TRANSFERIR ENTRADA', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1)),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CORREO DEL DESTINATARIO (DEBE ESTAR REGISTRADO EN EL HUB):',
          style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1, height: 1.5)),
        SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
          style: GoogleFonts.dmSans(color: AppColors.text, fontSize: 16),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: 'USUARIO@CORREO.COM',
            hintStyle: GoogleFonts.dmSans(color: AppColors.border),
            prefixIcon: Icon(Icons.email_rounded, size: 20, color: AppColors.textMuted),
            errorText: _error,
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.border, width: 2)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: AppColors.error, width: 2)),
          ),
        ),
        SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: AppColors.error, width: 2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: AppColors.error),
              SizedBox(width: 12),
              Expanded(
                child: Text('LA TRANSFERENCIA DE ENTRADAS ES IRREVERSIBLE.',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.text, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            ],
          ),
        ),
      ],
    ),
    actionsPadding: const EdgeInsets.all(24),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
      ElevatedButton(
        onPressed: () {
          final email = _ctrl.text.trim();
          if (!_validEmail(email)) {
            setState(() => _error = 'INGRESA UN CORREO VÁLIDO');
            return;
          }
          Navigator.pop(context, email);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF00FF),
          foregroundColor: AppColors.inverseSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text('TRANSFERIR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
    ],
  );
}

// ── Modal historial ───────────────────────────────────────────────────────────
class _HistoryDialog extends StatelessWidget {
  final List<dynamic> history;
  final int ticketId;
  const _HistoryDialog({required this.history, required this.ticketId});

  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
    title: Text('HISTORIAL — ENTRADA #$ticketId',
      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 20, color: AppColors.text, letterSpacing: -1)),
    content: SizedBox(
      width: 400,
      child: history.isEmpty
          ? Text('SIN EVENTOS REGISTRADOS AÚN.',
              style: GoogleFonts.dmSans(color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1))
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 2),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: history.length,
                separatorBuilder: (_, __) => Divider(height: 2, color: AppColors.border),
                itemBuilder: (_, i) {
                  final e = history[i];
                  final sc = _statusColor(e['status'] ?? '');
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    dense: true,
                    leading: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: sc, width: 2)),
                      child: Icon(Icons.history_rounded, size: 20, color: sc),
                    ),
                    title: Text(_statusLabel(e['status'] ?? ''),
                      style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.text)),
                    subtitle: Text((e['reason'] ?? '—').toString().toUpperCase(),
                      style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    trailing: Text(
                      (e['changedAt'] as String? ?? '').substring(0, 10),
                      style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
    ),
    actionsPadding: const EdgeInsets.all(24),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(color: AppColors.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text('CERRAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
    ],
  );
}

class _ConfirmDialog extends StatelessWidget {
  final String title, content, confirmLabel;
  final Color confirmColor;
  const _ConfirmDialog({
    required this.title,
    required this.content,
    required this.confirmLabel,
    required this.confirmColor,
  });
  @override
  Widget build(BuildContext context) => AlertDialog(
    backgroundColor: AppColors.background,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero, side: BorderSide(color: AppColors.border, width: 2)),
    title: Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900, fontSize: 24, color: AppColors.text, letterSpacing: -1)),
    content: Text(content, style: GoogleFonts.dmSans(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, height: 1.5, letterSpacing: 1)),
    actionsPadding: const EdgeInsets.all(24),
    actions: [
      OutlinedButton(
        onPressed: () => Navigator.pop(context, false),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: BorderSide(color: AppColors.border, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: Text('CANCELAR', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: AppColors.inverseSurface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: confirmColor, width: 2),
        ),
        child: Text(confirmLabel, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w900)),
      ),
    ],
  );
}

class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(64),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.transparent, border: Border.all(color: AppColors.border, width: 2)),
            child: Icon(icon, size: 32, color: AppColors.textMuted),
          ),
          SizedBox(height: 24),
          Text(text,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: AppColors.textMuted, height: 1.6, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    ),
  );
}
