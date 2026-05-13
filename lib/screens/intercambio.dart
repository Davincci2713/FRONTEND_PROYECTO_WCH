import 'package:flutter/material.dart';
import 'package:frontend_proyecto/utils/theme.dart';

enum TradeStatus { pending, accepted, rejected, completed }

class TradeOffer {
  final String id;
  final String fromUser;
  final String toUser;
  final String offeredSticker;
  final String wantedSticker;
  final TradeStatus status;
  final DateTime createdAt;

  const TradeOffer({
    required this.id,
    required this.fromUser,
    required this.toUser,
    required this.offeredSticker,
    required this.wantedSticker,
    required this.status,
    required this.createdAt,
  });
}

class RepeatedSticker {
  final String id;
  final String name;
  final String country;
  final String rarity;
  final int quantity;

  const RepeatedSticker({
    required this.id,
    required this.name,
    required this.country,
    required this.rarity,
    required this.quantity,
  });
}

final _myRepeated = [
  const RepeatedSticker(id: 'r1', name: 'H. Lozano', country: 'México', rarity: 'common', quantity: 3),
  const RepeatedSticker(id: 'r2', name: 'K. Mbappé', country: 'Francia', rarity: 'rare', quantity: 2),
  const RepeatedSticker(id: 'r3', name: 'T. Arnold', country: 'Inglaterra', rarity: 'common', quantity: 4),
  const RepeatedSticker(id: 'r4', name: 'P. Dybala', country: 'Argentina', rarity: 'rare', quantity: 1),
];

final _pendingOffers = [
  TradeOffer(
    id: 't1', fromUser: 'juanito_co', toUser: 'yo',
    offeredSticker: 'K. Mbappé', wantedSticker: 'L. Messi',
    status: TradeStatus.pending, createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  TradeOffer(
    id: 't2', fromUser: 'futbolero7', toUser: 'yo',
    offeredSticker: 'C. Ronaldo', wantedSticker: 'H. Lozano',
    status: TradeStatus.pending, createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];

final _historial = [
  TradeOffer(
    id: 'h1', fromUser: 'yo', toUser: 'mariafan26',
    offeredSticker: 'T. Arnold', wantedSticker: 'P. Dybala',
    status: TradeStatus.completed, createdAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  TradeOffer(
    id: 'h2', fromUser: 'copa2026', toUser: 'yo',
    offeredSticker: 'Neymar Jr', wantedSticker: 'K. Mbappé',
    status: TradeStatus.rejected, createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

class Intercambio extends StatefulWidget {
  const Intercambio({super.key});

  @override
  State<Intercambio> createState() => _IntercambioState();
}

class _IntercambioState extends State<Intercambio>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ÁLBUM DIGITAL',
                      style: TextStyle(
                          color: AppTheme.onSurfaceMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2)),
                  const SizedBox(height: 4),
                  const Text('Intercambios',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900)),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showNewTradeDialog,
                icon: const Icon(Icons.swap_horiz, size: 16),
                label: const Text('PROPONER',
                    style: TextStyle(
                        fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 11)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Tabs
        Container(
          color: AppTheme.surfaceCard,
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppTheme.accentGreen,
            indicatorWeight: 2,
            labelColor: Colors.white,
            unselectedLabelColor: AppTheme.onSurfaceMuted,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 1.5),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('OFERTAS'),
                    if (_pendingOffers.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: const BoxDecoration(
                            color: AppTheme.accentRed, shape: BoxShape.circle),
                        child: Text('${_pendingOffers.length}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'MIS REPETIDAS'),
              const Tab(text: 'HISTORIAL'),
            ],
          ),
        ),
        Container(height: 1, color: AppTheme.divider),

        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _OffersTab(offers: _pendingOffers, onAction: _handleOffer),
              _RepeatedTab(stickers: _myRepeated, onTrade: _showNewTradeDialog),
              _HistoryTab(history: _historial),
            ],
          ),
        ),
      ],
    );
  }

  void _handleOffer(TradeOffer offer, bool accepted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(accepted
            ? '✅ Intercambio aceptado con ${offer.fromUser}'
            : '❌ Intercambio rechazado'),
        backgroundColor: accepted ? AppTheme.accentGreen : AppTheme.accentRed,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showNewTradeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 4, height: 24, color: AppTheme.accentGreen),
                const SizedBox(width: 12),
                const Text('NUEVA PROPUESTA DE INTERCAMBIO',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 1)),
              ],
            ),
            const SizedBox(height: 20),
            _DropdownField(
              label: 'LÁMINA QUE OFRECES',
              hint: 'Selecciona una repetida',
              options: _myRepeated.map((s) => '${s.name} (${s.country}) ×${s.quantity}').toList(),
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: 'LÁMINA QUE QUIERES',
              hint: 'Ej: L. Messi (Argentina)',
              options: const [],
              isSearch: true,
            ),
            const SizedBox(height: 16),
            _DropdownField(
              label: 'USUARIO DESTINATARIO',
              hint: 'Nombre de usuario',
              options: const [],
              isSearch: true,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Propuesta enviada'),
                          backgroundColor: AppTheme.accentGreen,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                    child: const Text('ENVIAR PROPUESTA',
                        style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Text('CANCELAR',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab Ofertas pendientes ─────────────────────────────────────────────────────
class _OffersTab extends StatelessWidget {
  final List<TradeOffer> offers;
  final void Function(TradeOffer, bool) onAction;
  const _OffersTab({required this.offers, required this.onAction});

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) {
      return _EmptyState(icon: Icons.swap_horiz, msg: 'No tienes ofertas pendientes');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: offers.length,
      itemBuilder: (context, i) => _OfferCard(offer: offers[i], onAction: onAction),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final TradeOffer offer;
  final void Function(TradeOffer, bool) onAction;
  const _OfferCard({required this.offer, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.accentYellow.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.surfaceElevated,
                  child: Icon(Icons.person, color: AppTheme.onSurfaceMuted, size: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer.fromUser,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('quiere hacer un intercambio',
                        style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                color: AppTheme.accentYellow.withOpacity(0.15),
                child: const Text('PENDIENTE',
                    style: TextStyle(
                        color: AppTheme.accentYellow,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StickerChip(
                    label: 'TE OFRECE', sticker: offer.offeredSticker, color: AppTheme.accentGreen),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.swap_horiz, color: AppTheme.onSurfaceMuted, size: 20),
              ),
              Expanded(
                child: _StickerChip(
                    label: 'QUIERE', sticker: offer.wantedSticker, color: AppTheme.accentRed),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAction(offer, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                  ),
                  child: const Text('ACEPTAR'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onAction(offer, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentRed,
                    side: const BorderSide(color: AppTheme.accentRed),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 12),
                  ),
                  child: const Text('RECHAZAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Tab Repetidas ─────────────────────────────────────────────────────────────
class _RepeatedTab extends StatelessWidget {
  final List<RepeatedSticker> stickers;
  final VoidCallback onTrade;
  const _RepeatedTab({required this.stickers, required this.onTrade});

  @override
  Widget build(BuildContext context) {
    if (stickers.isEmpty) {
      return _EmptyState(icon: Icons.style, msg: 'No tienes láminas repetidas');
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.accentBlue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.accentBlue, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Tus láminas repetidas pueden intercambiarse. Límite: 5 intercambios/día.',
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: stickers.length,
            itemBuilder: (context, i) => _RepeatedCard(
                sticker: stickers[i], onTrade: onTrade),
          ),
        ),
      ],
    );
  }
}

class _RepeatedCard extends StatelessWidget {
  final RepeatedSticker sticker;
  final VoidCallback onTrade;
  const _RepeatedCard({required this.sticker, required this.onTrade});

  @override
  Widget build(BuildContext context) {
    final rc = sticker.rarity == 'legendary'
        ? AppTheme.accentYellow
        : sticker.rarity == 'rare'
            ? AppTheme.accentBlue
            : AppTheme.onSurfaceMuted;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Stack(
                children: [
                  Center(child: Icon(Icons.person, color: rc.withOpacity(0.3), size: 44)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      color: AppTheme.accentRed,
                      child: Text('×${sticker.quantity}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sticker.name,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                Text(sticker.country,
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 10)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTrade,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceElevated,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                    ),
                    child: const Text('INTERCAMBIAR'),
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

// ── Tab Historial ─────────────────────────────────────────────────────────────
class _HistoryTab extends StatelessWidget {
  final List<TradeOffer> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return _EmptyState(icon: Icons.history, msg: 'No hay intercambios previos');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, i) => _HistoryCard(offer: history[i]),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final TradeOffer offer;
  const _HistoryCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final isCompleted = offer.status == TradeStatus.completed;
    final sc = isCompleted ? AppTheme.accentGreen : AppTheme.accentRed;
    final sl = isCompleted ? 'COMPLETADO' : 'RECHAZADO';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: sc.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
                isCompleted ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: sc,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${offer.offeredSticker} ⇄ ${offer.wantedSticker}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text('con ${offer.fromUser == 'yo' ? offer.toUser : offer.fromUser}',
                    style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: sc.withOpacity(0.1),
            child: Text(sl,
                style: TextStyle(
                    color: sc, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _StickerChip extends StatelessWidget {
  final String label;
  final String sticker;
  final Color color;
  const _StickerChip({required this.label, required this.sticker, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(sticker,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  final String label;
  final String hint;
  final List<String> options;
  final bool isSearch;
  const _DropdownField(
      {required this.label,
      required this.hint,
      required this.options,
      this.isSearch = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.onSurfaceMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon:
                Icon(isSearch ? Icons.search : Icons.style, size: 18),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _EmptyState({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.onSurfaceMuted.withOpacity(0.3), size: 52),
          const SizedBox(height: 16),
          Text(msg, style: TextStyle(color: AppTheme.onSurfaceMuted, fontSize: 14)),
        ],
      ),
    );
  }
}