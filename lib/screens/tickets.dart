import 'dart:async';
import 'package:flutter/material.dart';
import '../services/ticket_service.dart';
import '../services/auth/auth.dart';

// ── Colores de estado ─────────────────────────────────────────────────────────
Color _statusColor(String s) => switch (s.toLowerCase()) {
  'pagada'      => const Color(0xFF2E7D32),
  'reservada'   => const Color(0xFFF57C00),
  'transferida' => const Color(0xFF1565C0),
  'reembolsada' => const Color(0xFF6A1B9A),
  'expirada'    => const Color(0xFFB71C1C),
  _             => const Color(0xFF455A64),
};

String _statusLabel(String s) => switch (s.toLowerCase()) {
  'disponible'  => 'Disponible',  'reservada'   => 'Reservada',
  'pagada'      => 'Pagada',      'transferida' => 'Transferida',
  'reembolsada' => 'Reembolsada', 'expirada'    => 'Expirada',
  _             => s,
};

// ── Pantalla principal ────────────────────────────────────────────────────────
class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Material(
          color: Theme.of(context).colorScheme.primary,
          child: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Color(0xFFBB0014),
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'COMPRAR', icon: Icon(Icons.confirmation_number, size: 18)),
              Tab(text: 'MIS ENTRADAS', icon: Icon(Icons.receipt_long, size: 18)),
            ],
          ),
        ),
      ),
      body: const TabBarView(
        children: [_BuyTab(), _MyTicketsTab()],
      ),
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getAvailableMatches();
      if (mounted) setState(() { _matches = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_matches.isEmpty) return const _Empty(icon: Icons.event_busy, text: 'No hay partidos disponibles.');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _matches.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
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
        title: 'Reservar Entrada',
        content: 'Reservar entrada para\n${match['home_name']} vs ${match['away_name']}\n\n'
            'Precio: \$${match['price']}\n\n'
            '⏱ Tienes 10 minutos para completar el pago.',
        confirmLabel: 'Reservar',
        confirmColor: Theme.of(context).colorScheme.primary,
      ),
    );
    if (confirmed != true) return;

    try {
      await _svc.reserveTicket(_uid, match['match_id']);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Entrada reservada. Ve a "Mis Entradas" para pagar.')));
      DefaultTabController.of(context).animateTo(1);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
      return '${_mes(dt.month)} ${dt.day}, ${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }

  String _mes(int m) => ['', 'Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic'][m];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avail = match['available'] as int? ?? 0;
    final sold  = avail == 0;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: sold ? Colors.grey.shade400 : theme.colorScheme.primary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(children: [
              const Icon(Icons.sports_soccer, color: Colors.white60, size: 16),
              const SizedBox(width: 8),
              Text(_fmt(match['date'] as String?),
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const Spacer(),
              if (avail > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                  child: Text('$avail disponibles',
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                )
              else
                const Text('AGOTADO', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ),
          // Equipos + precio
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(match['home_name'] as String? ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('vs', style: TextStyle(color: Colors.grey.shade500)),
                ),
                Expanded(
                  child: Text(match['away_name'] as String? ?? '—',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('\$${match['price']}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary)),
                ElevatedButton(
                  onPressed: sold ? null : onReserve,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: sold ? Colors.grey : theme.colorScheme.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(sold ? 'Agotado' : 'Reservar →'),
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
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _svc.getUserTickets(_uid);
      if (mounted) setState(() { _tickets = data; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_tickets.isEmpty) return const _Empty(
        icon: Icons.confirmation_number_outlined,
        text: 'No tienes entradas aún.\nVe a "Comprar" para reservar la tuya.');

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
  const _TicketCard({required this.ticket, required this.userId,
      required this.service, required this.onRefresh});
  @override
  State<_TicketCard> createState() => _TicketCardState();
}

class _TicketCardState extends State<_TicketCard> {
  bool _acting = false;

  Map<String, dynamic> get t => widget.ticket;
  String get status => (t['status'] as String? ?? '').toLowerCase();
  Color get color  => _statusColor(status);

  Duration? _ttl() {
    if (status != 'reservada') return null;
    final expStr = t['expirationDate'] as String?;
    if (expStr == null) return null;
    try {
      final exp = DateTime.parse(expStr).toLocal();
      final diff = exp.difference(DateTime.now());
      return diff.isNegative ? Duration.zero : diff;
    } catch (_) { return null; }
  }

  Future<void> _pay() async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => _StripeModal(price: t['price'] ?? 0));
    if (ok != true) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.payTicket(t['ticketId'], widget.userId);
      widget.onRefresh();
      messenger.showSnackBar(const SnackBar(content: Text('✅ Pago confirmado por Stripe')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _transfer() async {
    final toId = await showDialog<int>(context: context,
        builder: (_) => const _TransferDialog());
    if (toId == null) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await widget.service.transferTicket(t['ticketId'], widget.userId, toId);
      widget.onRefresh();
      messenger.showSnackBar(SnackBar(
          content: Text('🔄 Transferido — correlación: ${res['correlationId']}')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _refund() async {
    final ok = await showDialog<bool>(context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Solicitar Reembolso',
        content: 'Esta acción es irreversible.\n¿Confirmar reembolso de la entrada?',
        confirmLabel: 'Reembolsar',
        confirmColor: Colors.red,
      ));
    if (ok != true) return;
    setState(() => _acting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.service.refundTicket(t['ticketId'], widget.userId, 'Solicitud del usuario');
      widget.onRefresh();
      messenger.showSnackBar(const SnackBar(content: Text('💰 Reembolso procesado')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _history() async {
    final items = await widget.service.getTicketHistory(t['ticketId']);
    if (!mounted) return;
    showDialog(context: context,
        builder: (_) => _HistoryDialog(history: items,
            ticketId: t['ticketId']));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ttl = _ttl();
    final matchDetail = t['match_details'] as String? ?? 'Partido #${t['matchId']}';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Barra de estado lateral
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado + badge
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(_statusLabel(status),
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Text('\$${t['price'] ?? '—'}',
                          style: TextStyle(fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary, fontSize: 15)),
                    ]),
                    const SizedBox(height: 8),
                    Text(matchDetail,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (t['stadium'] != null) ...[
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.location_on, size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(t['stadium'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ]),
                    ],
                    // Countdown para reservadas
                    if (ttl != null) ...[
                      const SizedBox(height: 8),
                      _TTLWidget(ttl: ttl),
                    ],
                    // Botones de acción
                    const SizedBox(height: 12),
                    _ActionsRow(
                      status: status,
                      acting: _acting,
                      onPay: status == 'reservada' ? _pay : null,
                      onTransfer: status == 'pagada' ? _transfer : null,
                      onRefund: status == 'pagada' ? _refund : null,
                      onHistory: _history,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final min = _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final urgent = _remaining.inMinutes < 3;
    return Row(children: [
      Icon(Icons.timer_outlined, size: 14, color: urgent ? Colors.red : Colors.orange),
      const SizedBox(width: 4),
      Text('Paga antes de que expire: $min:$sec',
          style: TextStyle(fontSize: 12,
              color: urgent ? Colors.red : Colors.orange.shade800,
              fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Fila de acciones ──────────────────────────────────────────────────────────
class _ActionsRow extends StatelessWidget {
  final String status;
  final bool acting;
  final VoidCallback? onPay, onTransfer, onRefund, onHistory;
  const _ActionsRow({required this.status, required this.acting,
      this.onPay, this.onTransfer, this.onRefund, this.onHistory});

  @override
  Widget build(BuildContext context) {
    if (acting) return const Center(child: SizedBox(height: 28, width: 28,
        child: CircularProgressIndicator(strokeWidth: 2)));

    return Wrap(spacing: 8, runSpacing: 6, children: [
      if (onPay != null)
        _Btn(label: '💳 Pagar', color: Colors.green.shade700, onTap: onPay!),
      if (onTransfer != null)
        _Btn(label: '🔄 Transferir', color: Colors.blue.shade700, onTap: onTransfer!),
      if (onRefund != null)
        _Btn(label: '↩ Reembolsar', color: Colors.red.shade700, onTap: onRefund!),
      _Btn(label: '📋 Historial', color: Colors.grey.shade600, onTap: onHistory ?? () {}),
    ]);
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) => OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: Text(label, style: const TextStyle(fontSize: 12)),
  );
}

// ── Modal pago Stripe (simulado) ──────────────────────────────────────────────
class _StripeModal extends StatelessWidget {
  final dynamic price;
  const _StripeModal({required this.price});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        Image.network('https://cdn.jsdelivr.net/npm/@stripe-elements/stripe-elements@latest/favicon.png',
            width: 20, height: 20, errorBuilder: (_, __, ___) =>
                const Icon(Icons.credit_card, size: 20)),
        const SizedBox(width: 8),
        const Text('Pago con Stripe'),
      ]),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Total: \$$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 16),
        _MockField(label: 'Número de tarjeta', hint: '4242 4242 4242 4242'),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MockField(label: 'Vencimiento', hint: '12 / 28')),
          const SizedBox(width: 10),
          Expanded(child: _MockField(label: 'CVV', hint: '424')),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: const Row(children: [
            Icon(Icons.info_outline, size: 14, color: Colors.blue),
            SizedBox(width: 6),
            Expanded(child: Text(
              'Modo de prueba Stripe. Los datos no se envían a ningún servidor externo.',
              style: TextStyle(fontSize: 11, color: Colors.blue),
            )),
          ]),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
        ElevatedButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.lock_outline, size: 16),
          label: Text('Pagar \$$price'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6259F5),
              foregroundColor: Colors.white),
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
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(hint, style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
      ),
    ],
  );
}

// ── Modal transferencia ───────────────────────────────────────────────────────
class _TransferDialog extends StatefulWidget {
  const _TransferDialog();
  @override
  State<_TransferDialog> createState() => _TransferDialogState();
}

class _TransferDialogState extends State<_TransferDialog> {
  final _ctrl = TextEditingController();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Transferir Entrada'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Ingresa el ID del usuario destinatario:',
          style: TextStyle(fontSize: 13)),
      const SizedBox(height: 12),
      TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'ID de usuario', prefixIcon: Icon(Icons.person_search),
          border: OutlineInputBorder(),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.orange.shade200)),
        child: const Text(
          '⚠️ Esta acción es irreversible. Se registrará quién transfiere, a quién y cuándo (trazabilidad completa).',
          style: TextStyle(fontSize: 11, color: Colors.deepOrange),
        ),
      ),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: () {
          final id = int.tryParse(_ctrl.text.trim());
          if (id != null) Navigator.pop(context, id);
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white),
        child: const Text('Confirmar Transferencia'),
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
    title: Text('Historial — Entrada #$ticketId'),
    content: SizedBox(
      width: 340,
      child: history.isEmpty
          ? const Text('Sin eventos registrados aún.')
          : ListView.separated(
              shrinkWrap: true,
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = history[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: _statusColor(e['status'] ?? '').withOpacity(0.15),
                    child: Icon(Icons.circle, size: 8,
                        color: _statusColor(e['status'] ?? '')),
                  ),
                  title: Text(_statusLabel(e['status'] ?? ''),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text(e['reason'] ?? '—',
                      style: const TextStyle(fontSize: 11)),
                  trailing: Text(
                    (e['changedAt'] as String? ?? '').substring(0, 10),
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                );
              },
            ),
    ),
    actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
  );
}

// ── Confirm dialog reutilizable ───────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title, content, confirmLabel;
  final Color confirmColor;
  const _ConfirmDialog({required this.title, required this.content,
      required this.confirmLabel, required this.confirmColor});
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(content),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        style: ElevatedButton.styleFrom(backgroundColor: confirmColor, foregroundColor: Colors.white),
        child: Text(confirmLabel),
      ),
    ],
  );
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _Empty extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Empty({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(40),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 56, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, height: 1.6)),
      ]),
    ),
  );
}
