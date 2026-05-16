import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/ticket_service.dart';
import '../services/auth/auth.dart';

// ── Colores de estado ─────────────────────────────────────────────────────────
Color _statusColor(String s) => switch (s.toLowerCase()) {
  'pagada' => Colors.green.shade700,
  'reservada' => Colors.orange.shade700,
  'transferida' => Colors.blue.shade700,
  'reembolsada' => Colors.purple.shade700,
  'expirada' => const Color(0xFFBB0014),
  _ => Colors.grey.shade700,
};

String _statusLabel(String s) => switch (s.toLowerCase()) {
  'disponible' => 'Disponible',
  'reservada' => 'Reservada',
  'pagada' => 'Pagada',
  'transferida' => 'Transferida',
  'reembolsada' => 'Reembolsada',
  'expirada' => 'Expirada',
  _ => s,
};

// ── Pantalla principal ────────────────────────────────────────────────────────
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Material(
          color: Colors.white,
          elevation: 0,
          child: Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const TabBar(
              labelColor: Color(0xFF00341C),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF00341C),
              indicatorWeight: 3,
              labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              unselectedLabelStyle: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              tabs: [
                Tab(
                  text: 'Comprar',
                  icon: Icon(Icons.confirmation_number_outlined, size: 18),
                ),
                Tab(
                  text: 'Mis entradas',
                  icon: Icon(Icons.receipt_long_outlined, size: 18),
                ),
              ],
            ),
          ),
        ),
      ),
      body: const TabBarView(children: [_BuyTab(), _MyTicketsTab()]),
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — COMPRAR
// ══════════════════════════════════════════════════════════════════════════════
class _BuyTab extends StatefulWidget {
  const _BuyTab();
  @override
  State<_BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends State<_BuyTab> {
  final _svc = TicketService();
  List<dynamic> _matches = [];
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
      final data = await _svc.getAvailableMatches();
      if (mounted)
        setState(() {
          _matches = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_matches.isEmpty)
      return const _Empty(
        icon: Icons.event_busy,
        text: 'No hay partidos disponibles.',
      );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (ctx, i) => _MatchCard(
          match: _matches[i],
          onReserve: () => _reserve(_matches[i]),
        ),
      ),
    );
  }

  Future<void> _reserve(Map<String, dynamic> match) async {
    if (match['available'] == 0) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Reservar entrada',
        content:
            'Reservar entrada para\n${match['home_name']} vs ${match['away_name']}\n\n'
            'Precio: \$${match['price']}\n\n'
            '⏱ Tienes 10 minutos para completar el pago.',
        confirmLabel: 'Reservar',
        confirmColor: const Color(0xFF00341C),
      ),
    );
    if (confirmed != true) return;

    try {
      await _svc.reserveTicket(_uid, match['match_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entrada reservada. Ve a "Mis entradas" para pagar.'),
        ),
      );
      DefaultTabController.of(context).animateTo(1);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _MatchCard extends StatelessWidget {
  final Map<String, dynamic> match;
  final VoidCallback onReserve;
  const _MatchCard({required this.match, required this.onReserve});

  String _fmt(String? iso) {
    if (iso == null) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${_mes(dt.month)} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  String _mes(int m) => [
    '',
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ][m];

  @override
  Widget build(BuildContext context) {
    final avail = match['available'] as int? ?? 0;
    final sold = avail == 0;

    return Container(
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
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sold ? Colors.grey.shade100 : Colors.grey.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  _fmt(match['date'] as String?),
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (avail > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Text(
                      '$avail disponibles',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      'Agotado',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Equipos + precio
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    match['home_name'] as String? ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
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
                    match['away_name'] as String? ?? '—',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${match['price']}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                ElevatedButton(
                  onPressed: sold ? null : onReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00341C),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  child: Text(sold ? 'Agotado' : 'Reservar'),
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
      final data = await _svc.getUserTickets(_uid);
      if (mounted)
        setState(() {
          _tickets = data;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_tickets.isEmpty)
      return const _Empty(
        icon: Icons.confirmation_number_outlined,
        text: 'No tienes entradas aún.\nVe a "Comprar" para reservar la tuya.',
      );

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(24),
        itemCount: _tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) => _TicketCard(
          ticket: _tickets[i],
          userId: _uid,
          service: _svc,
          onRefresh: _load,
        ),
      ),
    );
  }
}

// ── Tarjeta de entrada con acciones ──────────────────────────────────────────
class _TicketCard extends StatefulWidget {
  final Map<String, dynamic> ticket;
  final int userId;
  final TicketService service;
  final VoidCallback onRefresh;
  const _TicketCard({
    required this.ticket,
    required this.userId,
    required this.service,
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
      messenger.showSnackBar(const SnackBar(content: Text('Pago confirmado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _transfer() async {
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
          content: Text(
            'Transferida a $toName (${res['correlationId']?.toString().substring(0, 8) ?? '—'})...',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _refund() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Solicitar reembolso',
        content:
            'Esta acción es irreversible.\n¿Confirmar reembolso de la entrada?',
        confirmLabel: 'Reembolsar',
        confirmColor: const Color(0xFFBB0014),
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
        const SnackBar(content: Text('Reembolso procesado')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
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
    final matchDetail =
        t['match_details'] as String? ?? 'Partido #${t['matchId']}';

    return Container(
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
          // ── Información principal ──────────────────────────────────────────
          IntrinsicHeight(
            child: Row(
              children: [
                // Barra de estado lateral
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(6),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Estado + badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: color.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                _statusLabel(status),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${t['price'] ?? '—'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          matchDetail,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        if (t['stadium'] != null) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                t['stadium'],
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (ttl != null) ...[
                          const SizedBox(height: 12),
                          _TTLWidget(ttl: ttl),
                        ],
                        const SizedBox(height: 16),
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
                Container(width: 4, color: color),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(height: 1, color: Colors.grey.shade200),
                        const SizedBox(height: 14),
                        Text(
                          'Código QR de acceso',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: QrImageView(
                              data:
                                  'ticket_id:${t['ticketId'] ?? 0},match:${t['matchId'] ?? 0}',
                              version: QrVersions.auto,
                              size: 180,
                              backgroundColor: Colors.white,
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
    final color = urgent ? const Color(0xFFBB0014) : Colors.orange.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            'Paga antes de que expire: $min:$sec',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    if (acting)
      return const Center(
        child: SizedBox(
          height: 28,
          width: 28,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (onPay != null)
          _Btn(
            label: 'Pagar',
            icon: Icons.payment,
            color: Colors.green.shade700,
            onTap: onPay!,
          ),
        if (onTransfer != null)
          _Btn(
            label: 'Transferir',
            icon: Icons.swap_horiz,
            color: Colors.blue.shade700,
            onTap: onTransfer!,
          ),
        if (onRefund != null)
          _Btn(
            label: 'Reembolsar',
            icon: Icons.refresh,
            color: const Color(0xFFBB0014),
            onTap: onRefund!,
          ),
        if (onQr != null)
          _Btn(
            label: qrActive ? 'Ocultar QR' : 'Ver QR',
            icon: qrActive ? Icons.qr_code_2 : Icons.qr_code,
            color: const Color(0xFF00341C),
            onTap: onQr!,
          ),
        _Btn(
          label: 'Historial',
          icon: Icons.history,
          color: Colors.grey.shade700,
          onTap: onHistory ?? () {},
        ),
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
      side: BorderSide(color: color.withOpacity(0.5)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    ),
  );
}

// ── Modal pago Stripe (simulado) ──────────────────────────────────────────────
class _StripeModal extends StatelessWidget {
  final dynamic price;
  const _StripeModal({required this.price});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      title: Row(
        children: [
          Icon(Icons.credit_card, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          const Text(
            'Pago con Stripe',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: \$$price',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const _MockField(
            label: 'Número de tarjeta',
            hint: '4242 4242 4242 4242',
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _MockField(label: 'Vencimiento', hint: '12 / 28'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MockField(label: 'CVV', hint: '424'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Modo de prueba Stripe. Los datos no se envían a ningún servidor externo.',
                    style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.lock_outline, size: 16),
          label: Text('Pagar \$$price'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6259F5),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
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
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          hint,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        ),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    title: const Text(
      'Transferir entrada',
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correo del destinatario (debe estar registrado en la plataforma):',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => setState(() => _error = null),
          decoration: InputDecoration(
            hintText: 'usuario@correo.com',
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            isDense: true,
            errorText: _error,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.orange.shade800,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'La transferencia de entradas es irreversible',
                  style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () {
          final email = _ctrl.text.trim();
          if (!_validEmail(email)) {
            setState(() => _error = 'Ingresa un correo válido');
            return;
          }
          Navigator.pop(context, email);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: const Text(
          'Transferir',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    title: Text(
      'Historial — Entrada #$ticketId',
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    ),
    content: SizedBox(
      width: 400,
      child: history.isEmpty
          ? Text(
              'Sin eventos registrados aún.',
              style: TextStyle(color: Colors.grey.shade600),
            )
          : Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: history.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (_, i) {
                  final e = history[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: _statusColor(
                        e['status'] ?? '',
                      ).withOpacity(0.1),
                      child: Icon(
                        Icons.circle,
                        size: 10,
                        color: _statusColor(e['status'] ?? ''),
                      ),
                    ),
                    title: Text(
                      _statusLabel(e['status'] ?? ''),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      e['reason'] ?? '—',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    trailing: Text(
                      (e['changedAt'] as String? ?? '').substring(0, 10),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFF00341C)),
        child: const Text('Cerrar'),
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
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
    ),
    content: Text(
      content,
      style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
        child: const Text('Cancelar'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(
          backgroundColor: confirmColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(
          confirmLabel,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
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
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.5,
              fontSize: 14,
            ),
          ),
        ],
      ),
    ),
  );
}
